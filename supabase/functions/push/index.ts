// Delivers pending rows of public.notifications to FCM.
//
// Invoked only by the database (pg_net, see the push_delivery migration)
// with a shared secret. Which rows to send and how to record results is
// decided in SQL (private.claim_push_batch / private.complete_push); this
// function is only the transport.
import postgres from "npm:postgres@3.4.4";
import { parseServiceAccount, send, type FcmMessage } from "./fcm.ts";
import { render, type Params } from "./messages.ts";

const sql = postgres(Deno.env.get("SUPABASE_DB_URL")!, {
  prepare: false,
  max: 2,
  idle_timeout: 20,
});
const WEBHOOK_SECRET = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
const serviceAccount = parseServiceAccount(Deno.env.get("FCM_SERVICE_ACCOUNT"));
const WEB_APP_URL = (Deno.env.get("WEB_APP_URL") ?? "").replace(/\/$/, "");

type Token = { token: string; platform: "android" | "ios" | "web" };
type Claimed = {
  notification_id: string;
  team_id: string | null;
  category: string;
  params: Params;
  locale: string;
  tokens: Token[];
};

function safeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diff === 0;
}

function buildMessage(row: Claimed, token: Token): FcmMessage {
  const { title, body } = render(row.category, row.locale, row.params);
  // Collapse repeated notifications of one conversation into one entry.
  const tag = typeof row.params.channel_id === "number" || typeof row.params.channel_id === "string"
    ? `channel-${row.params.channel_id}`
    : `n-${row.notification_id}`;
  return {
    token: token.token,
    notification: { title, body },
    data: {
      notification_id: String(row.notification_id),
      category: row.category,
      team_id: row.team_id == null ? "" : String(row.team_id),
      params: JSON.stringify(row.params),
    },
    android: { priority: "high", notification: { tag } },
    apns: { headers: { "apns-collapse-id": tag }, payload: { aps: { sound: "default" } } },
    ...(WEB_APP_URL
      ? { webpush: { fcm_options: { link: `${WEB_APP_URL}/notifications` } } }
      : {}),
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });
  if (!WEBHOOK_SECRET || !safeEqual(req.headers.get("Authorization") ?? "", `Bearer ${WEBHOOK_SECRET}`)) {
    return new Response("Unauthorized", { status: 401 });
  }

  let ids: number[];
  try {
    const body = await req.json();
    ids = (Array.isArray(body?.ids) ? body.ids : []).map(Number).filter(Number.isSafeInteger);
  } catch {
    return new Response("Bad Request", { status: 400 });
  }
  if (ids.length === 0) return Response.json({ claimed: 0 });

  const rows = await sql<Claimed[]>`select * from private.claim_push_batch(${ids}::bigint[])`;
  const results: Array<{ id: number; status: "sent" | "failed" | "skipped" }> = [];
  const deadTokens: string[] = [];

  for (const row of rows) {
    const id = Number(row.notification_id);
    if (!serviceAccount || row.tokens.length === 0) {
      // Nothing to deliver to (push not configured here, or no devices).
      results.push({ id, status: "skipped" });
      continue;
    }
    const outcomes = await Promise.all(row.tokens.map((t) => send(serviceAccount, buildMessage(row, t))));
    row.tokens.forEach((t, i) => {
      if (outcomes[i] === "dead_token") deadTokens.push(t.token);
    });
    const status = outcomes.includes("sent") ? "sent" : outcomes.includes("error") ? "failed" : "skipped";
    results.push({ id, status });
  }

  await sql`select private.complete_push(${sql.json({ results, dead_tokens: deadTokens })})`;
  return Response.json({ claimed: rows.length });
});
