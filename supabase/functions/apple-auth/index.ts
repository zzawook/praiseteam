import { decodeJwt } from "npm:jose@5.9.6";
import {
  appleConfig,
  exchangeAppleCode,
  revokeAppleToken,
  serviceRpc,
} from "../_shared/apple.ts";
import { type AppleActor, handleAppleAuth } from "./handler.ts";
const config = appleConfig((key) => Deno.env.get(key));
const base = Deno.env.get("SUPABASE_URL")!,
  key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const rpc = serviceRpc(base, key);
async function authenticate(bearer: string): Promise<AppleActor | null> {
  const r = await fetch(`${base}/auth/v1/user`, {
    headers: { Authorization: bearer, apikey: key },
    signal: AbortSignal.timeout(8000),
  });
  if (!r.ok) {
    await r.body?.cancel();
    return null;
  }
  const user = await r.json();
  // decodeJwt is used only AFTER GoTrue has verified this exact bearer token.
  // The service-only RPC separately checks that this session is still live.
  const claims = decodeJwt(bearer.slice(7));
  if (claims.sub !== user.id || typeof claims.session_id !== "string") {
    return null;
  }
  const subjects = (user.identities ?? []).filter((i: { provider: string }) =>
    i.provider === "apple"
  )
    .map((i: { identity_data?: { sub?: string }; provider_id?: string }) =>
      i.identity_data?.sub ?? i.provider_id
    )
    .filter((s: unknown): s is string => typeof s === "string");
  return { id: user.id, sessionId: claims.session_id, subjects };
}
Deno.serve(async (req) => {
  if (!config) {
    return new Response("Apple sign-in is not configured", { status: 503 });
  }
  try {
    return await handleAppleAuth(req, {
      clientId: config.clientId,
      encryptionKey: config.encryptionKey,
      authenticate,
      exchange: (code) => exchangeAppleCode(config, code),
      save: async (row) => {
        await rpc("store_apple_token", row);
      },
      revoke: (token) => revokeAppleToken(config, token),
    });
  } catch {
    return new Response("Apple sign-in temporarily unavailable", {
      status: 503,
    });
  }
});
