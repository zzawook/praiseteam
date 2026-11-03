import { sealToken, tokenContext, tokenHash } from "../_shared/apple.ts";
export type AppleActor = { id: string; sessionId: string; subjects: string[] };
export type AppleAuthDependencies = {
  clientId: string;
  encryptionKey: string;
  authenticate: (bearer: string) => Promise<AppleActor | null>;
  exchange: (code: string) => Promise<{ token: string; subject: string }>;
  save: (row: Record<string, unknown>) => Promise<void>;
  revoke: (token: string) => Promise<unknown>;
};
export async function handleAppleAuth(
  req: Request,
  deps: AppleAuthDependencies,
): Promise<Response> {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }
  const bearer = req.headers.get("Authorization") ?? "";
  if (!bearer.startsWith("Bearer ")) {
    return new Response("Unauthorized", { status: 401 });
  }
  const actor = await deps.authenticate(bearer);
  if (!actor || !actor.subjects.length) {
    return new Response("Apple sign-in required", { status: 401 });
  }
  const raw = await req.text();
  if (raw.length > 8192) {
    return new Response("Request too large", { status: 413 });
  }
  let code: unknown;
  try {
    code = JSON.parse(raw).authorization_code;
  } catch {
    return new Response("Invalid request", { status: 400 });
  }
  if (typeof code !== "string" || !code || code.length > 4096) {
    return new Response("Invalid authorization code", { status: 400 });
  }
  let credential: { token: string; subject: string };
  try {
    credential = await deps.exchange(code);
  } catch {
    return new Response("Apple authorization failed", { status: 400 });
  }
  if (!actor.subjects.includes(credential.subject)) {
    await deps.revoke(credential.token).catch(() => {});
    return new Response("Apple identity mismatch", { status: 403 });
  }
  try {
    await deps.save({
      p_user_id: actor.id,
      p_session_id: actor.sessionId,
      p_client_id: deps.clientId,
      p_token_hash: await tokenHash(credential.token),
      p_ciphertext: await sealToken(
        credential.token,
        deps.encryptionKey,
        tokenContext(actor.id, deps.clientId),
      ),
    });
  } catch {
    // Do not let an unsuccessful enrollment leave a newly exchanged token
    // unaccounted for. The mobile client also abandons its temporary session.
    await deps.revoke(credential.token).catch(() => {});
    return new Response("Apple sign-in could not be completed", {
      status: 503,
    });
  }
  return Response.json({ stored: true });
}
