import {
  appleConfig,
  openToken,
  revokeAppleToken,
  safeEqual,
  serviceRpc,
  tokenContext,
} from "../_shared/apple.ts";
const config = appleConfig((key) => Deno.env.get(key));
const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
const rpc = serviceRpc(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
type Pending = {
  id: number;
  user_id: string;
  client_id: string;
  token_ciphertext: string;
};
Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }
  if (
    !secret ||
    !safeEqual(req.headers.get("Authorization") ?? "", `Bearer ${secret}`)
  ) return new Response("Unauthorized", { status: 401 });
  if (!config) {
    return new Response("Apple revocation is not configured", { status: 503 });
  }
  try {
    const rows = await rpc("claim_apple_revocations", {
      p_limit: 5,
    }) as Pending[];
    const results = await Promise.all(rows.map(async (row) => {
      let status = 0;
      try {
        const token = await openToken(
          row.token_ciphertext,
          config.encryptionKey,
          tokenContext(row.user_id, row.client_id),
        );
        status = await revokeAppleToken(config, token, row.client_id);
      } catch {
        /* Retry through the durable queue; never log provider tokens. */
      }
      await rpc("finish_apple_revocation", {
        p_id: row.id,
        p_success: status === 200,
        p_status: status,
      });
      return status === 200;
    }));
    return Response.json({
      revoked: results.filter(Boolean).length,
      retrying: results.filter((ok) => !ok).length,
    });
  } catch {
    return new Response("Apple revocation temporarily unavailable", {
      status: 503,
    });
  }
});
