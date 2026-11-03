import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1.0.8";
import { exportPKCS8, generateKeyPair, jwtVerify } from "npm:jose@5.9.6";
import {
  appleClientSecret,
  openToken,
  sealToken,
  tokenContext,
} from "../_shared/apple.ts";
import { type AppleAuthDependencies, handleAppleAuth } from "./handler.ts";
const key = btoa(String.fromCharCode(...new Uint8Array(32).fill(7)));
function setup() {
  const saved: Record<string, unknown>[] = [], revoked: string[] = [];
  const deps: AppleAuthDependencies = {
    clientId: "com.example.native",
    encryptionKey: key,
    authenticate: () =>
      Promise.resolve({
        id: "user-a",
        sessionId: "session-a",
        subjects: ["apple-a"],
      }),
    exchange: () =>
      Promise.resolve({ token: "provider-refresh-secret", subject: "apple-a" }),
    save: (row) => {
      saved.push(row);
      return Promise.resolve();
    },
    revoke: (token) => {
      revoked.push(token);
      return Promise.resolve();
    },
  };
  const request = (
    body: unknown = { authorization_code: "one-use-code" },
    bearer = "Bearer verified-session",
  ) =>
    new Request("https://local.test/apple-auth", {
      method: "POST",
      headers: { Authorization: bearer },
      body: JSON.stringify(body),
    });
  return { deps, saved, revoked, request };
}
Deno.test("Apple enrollment requires an authenticated Apple identity", async () => {
  const f = setup();
  f.deps.authenticate = () => Promise.resolve(null);
  assertEquals((await handleAppleAuth(f.request(), f.deps)).status, 401);
  assertEquals(f.saved.length, 0);
  assertEquals((await handleAppleAuth(f.request({}, ""), f.deps)).status, 401);
});
Deno.test("Apple enrollment refuses missing and oversized authorization codes", async () => {
  const f = setup();
  assertEquals((await handleAppleAuth(f.request({}), f.deps)).status, 400);
  assertEquals(
    (await handleAppleAuth(
      f.request({ authorization_code: "x".repeat(9000) }),
      f.deps,
    )).status,
    413,
  );
  assertEquals(f.saved.length, 0);
});
Deno.test("Apple code from another identity is revoked and never attached", async () => {
  const f = setup();
  f.deps.exchange = () =>
    Promise.resolve({ token: "wrong-user-token", subject: "apple-b" });
  assertEquals((await handleAppleAuth(f.request(), f.deps)).status, 403);
  assertEquals(f.saved.length, 0);
  assertEquals(f.revoked, ["wrong-user-token"]);
});
Deno.test("Apple enrollment stores encrypted tokens for the verified session only", async () => {
  const f = setup();
  const result = await handleAppleAuth(
    f.request({ authorization_code: "code", user_id: "attacker-choice" }),
    f.deps,
  );
  assertEquals(result.status, 200);
  assertEquals(await result.json(), { stored: true });
  const row = f.saved[0];
  assertEquals(row.p_user_id, "user-a");
  assertEquals(row.p_session_id, "session-a");
  assert(!JSON.stringify(row).includes("provider-refresh-secret"));
  assertEquals(
    await openToken(
      row.p_ciphertext as string,
      key,
      tokenContext("user-a", f.deps.clientId),
    ),
    "provider-refresh-secret",
  );
  assertEquals((row.p_token_hash as string).length, 64);
  assertEquals(f.revoked, []);
});
Deno.test("Failed credential persistence revokes the just-exchanged token", async () => {
  const f = setup();
  f.deps.save = () => Promise.reject(new Error("database unavailable"));
  const result = await handleAppleAuth(f.request(), f.deps);
  assertEquals(result.status, 503);
  assertEquals(f.revoked, ["provider-refresh-secret"]);
  assert(!(await result.text()).includes("provider-refresh-secret"));
});
Deno.test("Apple token encryption binds each token to its user and client", async () => {
  const sealed = await sealToken(
    "secret",
    key,
    tokenContext("user-a", "app-a"),
  );
  assertEquals(
    await openToken(sealed, key, tokenContext("user-a", "app-a")),
    "secret",
  );
  await assertRejects(() =>
    openToken(sealed, key, tokenContext("user-b", "app-a"))
  );
  await assertRejects(() =>
    openToken(sealed, key, tokenContext("user-a", "app-b"))
  );
  const parts = sealed.split(".");
  const raw = atob(parts[2]);
  parts[2] = btoa(String.fromCharCode(raw.charCodeAt(0) ^ 1) + raw.slice(1));
  await assertRejects(() =>
    openToken(parts.join("."), key, tokenContext("user-a", "app-a"))
  );
  await assertRejects(() => sealToken("secret", "too-short", "context"));
});
Deno.test("Apple client secrets are scoped ES256 JWTs valid for five minutes", async () => {
  const { privateKey, publicKey } = await generateKeyPair("ES256", {
    extractable: true,
  });
  const config = {
    clientId: "com.example.native",
    teamId: "TEAM123456",
    keyId: "KEY1234567",
    privateKey: await exportPKCS8(privateKey),
    encryptionKey: key,
  };
  const token = await appleClientSecret(config);
  const verified = await jwtVerify(token, publicKey, {
    issuer: config.teamId,
    audience: "https://appleid.apple.com",
    subject: config.clientId,
  });
  assertEquals(verified.protectedHeader.kid, config.keyId);
  assertEquals(verified.payload.exp! - verified.payload.iat!, 300);
  await assertRejects(() => appleClientSecret(config, "other-client"));
});
