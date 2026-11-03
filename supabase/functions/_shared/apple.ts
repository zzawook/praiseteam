import {
  createRemoteJWKSet,
  importPKCS8,
  jwtVerify,
  SignJWT,
} from "npm:jose@5.9.6";

export type AppleConfig = {
  clientId: string;
  teamId: string;
  keyId: string;
  privateKey: string;
  encryptionKey: string;
};
export function appleConfig(
  env: (key: string) => string | undefined,
): AppleConfig | null {
  const values = [
    "APPLE_CLIENT_ID",
    "APPLE_TEAM_ID",
    "APPLE_KEY_ID",
    "APPLE_PRIVATE_KEY",
    "APPLE_TOKEN_ENCRYPTION_KEY",
  ].map(env);
  if (values.some((v) => !v)) return null;
  return {
    clientId: values[0]!,
    teamId: values[1]!,
    keyId: values[2]!,
    privateKey: values[3]!.replaceAll("\\n", "\n"),
    encryptionKey: values[4]!,
  };
}
const bytes = new TextEncoder();
const encode = (value: Uint8Array) => btoa(String.fromCharCode(...value));
const decode = (value: string) =>
  Uint8Array.from(atob(value), (c) => c.charCodeAt(0));
async function encryptionKey(value: string) {
  const raw = decode(value);
  if (raw.length !== 32) {
    throw new Error("Apple token encryption key must contain 32 bytes");
  }
  return await crypto.subtle.importKey("raw", raw, "AES-GCM", false, [
    "encrypt",
    "decrypt",
  ]);
}
export const tokenContext = (userId: string, clientId: string) =>
  `apple:${userId}:${clientId}`;
export async function sealToken(
  token: string,
  key: string,
  context: string,
): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv, additionalData: bytes.encode(context) },
    await encryptionKey(key),
    bytes.encode(token),
  );
  return `v1.${encode(iv)}.${encode(new Uint8Array(encrypted))}`;
}
export async function openToken(
  ciphertext: string,
  key: string,
  context: string,
): Promise<string> {
  const [version, nonce, data, extra] = ciphertext.split(".");
  if (version !== "v1" || !nonce || !data || extra) {
    throw new Error("Invalid encrypted Apple token");
  }
  const plain = await crypto.subtle.decrypt(
    {
      name: "AES-GCM",
      iv: decode(nonce),
      additionalData: bytes.encode(context),
    },
    await encryptionKey(key),
    decode(data),
  );
  return new TextDecoder().decode(plain);
}
export async function tokenHash(token: string) {
  return [
    ...new Uint8Array(
      await crypto.subtle.digest("SHA-256", bytes.encode(token)),
    ),
  ].map((b) => b.toString(16).padStart(2, "0")).join("");
}
export async function appleClientSecret(
  config: AppleConfig,
  clientId = config.clientId,
) {
  if (clientId !== config.clientId) throw new Error("Unexpected Apple client");
  return await new SignJWT({}).setProtectedHeader({
    alg: "ES256",
    kid: config.keyId,
  }).setIssuer(config.teamId)
    .setAudience("https://appleid.apple.com").setSubject(clientId).setIssuedAt()
    .setExpirationTime("5m")
    .sign(await importPKCS8(config.privateKey, "ES256"));
}
const appleKeys = createRemoteJWKSet(
  new URL("https://appleid.apple.com/auth/keys"),
);
export async function exchangeAppleCode(config: AppleConfig, code: string) {
  const response = await fetch("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: config.clientId,
      client_secret: await appleClientSecret(config),
      code,
      grant_type: "authorization_code",
    }),
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new Error("Apple authorization exchange failed");
  }
  const data = await response.json();
  if (
    typeof data.refresh_token !== "string" || typeof data.id_token !== "string"
  ) throw new Error("Apple returned incomplete credentials");
  const { payload } = await jwtVerify(data.id_token, appleKeys, {
    issuer: "https://appleid.apple.com",
    audience: config.clientId,
  });
  if (!payload.sub) throw new Error("Apple identity is missing");
  return { token: data.refresh_token as string, subject: payload.sub };
}
export async function revokeAppleToken(
  config: AppleConfig,
  token: string,
  clientId = config.clientId,
): Promise<number> {
  const response = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: await appleClientSecret(config, clientId),
      token,
      token_type_hint: "refresh_token",
    }),
    signal: AbortSignal.timeout(8000),
  });
  await response.body?.cancel();
  return response.status;
}
export function safeEqual(a: string, b: string) {
  const x = bytes.encode(a), y = bytes.encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diff === 0;
}
export function serviceRpc(base: string, key: string) {
  return async (name: string, body: Record<string, unknown>) => {
    const r = await fetch(`${base}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(8000),
    });
    if (!r.ok) {
      await r.body?.cancel();
      throw new Error("Apple credential persistence failed");
    }
    const text = await r.text();
    return text ? JSON.parse(text) : null;
  };
}
