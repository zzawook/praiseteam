// Internal worker: called by pg_net with the same webhook credential as push.
// Account deletion commits first. This worker retries failed Storage API
// removals; deleting storage.objects with SQL would leave the actual files.
import postgres from "npm:postgres@3.4.4";
import { cleanFiles, type QueuedFile } from "./cleanup.ts";

const sql = postgres(Deno.env.get("SUPABASE_DB_URL")!, { prepare: false, max: 2, idle_timeout: 20 });
const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
const base = Deno.env.get("SUPABASE_URL")!;
const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function authorized(value: string): boolean {
  if (!secret) return false;
  const expected = new TextEncoder().encode(`Bearer ${secret}`);
  const actual = new TextEncoder().encode(value);
  let diff = expected.length ^ actual.length;
  for (let i = 0; i < Math.max(expected.length, actual.length); i++) {
    diff |= (expected[i] ?? 0) ^ (actual[i] ?? 0);
  }
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });
  if (!authorized(req.headers.get("Authorization") ?? "")) return new Response("Unauthorized", { status: 401 });
  // Request bodies never choose the files. Only committed database entries do.
  const files = await sql<QueuedFile[]>`
    select bucket_id, storage_path from private.storage_cleanup_queue
    order by created_at limit 100`;
  const removed = await cleanFiles(files, async (bucket, paths) => {
    try {
      const response = await fetch(`${base}/storage/v1/object/${encodeURIComponent(bucket)}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${key}`, apikey: key, "Content-Type": "application/json" },
        body: JSON.stringify({ prefixes: paths }),
        signal: AbortSignal.timeout(8000),
      });
      await response.body?.cancel();
      if (!response.ok) console.error("Storage cleanup failed", response.status);
      return response.ok;
    } catch {
      console.error("Storage cleanup could not reach storage");
      return false;
    }
  }, async (bucket, paths) => {
    await sql`delete from private.storage_cleanup_queue where bucket_id = ${bucket} and storage_path = any(${paths}::text[])`;
  });
  return Response.json({ removed });
});
