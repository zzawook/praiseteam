import { assertEquals, assertRejects } from "jsr:@std/assert@1.0.8";
import { cleanFiles } from "./cleanup.ts";

Deno.test("successful batches are acknowledged; failed storage batches stay queued", async () => {
  const completed: string[][] = [];
  const count = await cleanFiles([
    { bucket_id: "sheets", storage_path: "1/a.pdf" },
    { bucket_id: "sheets", storage_path: "1/b.pdf" },
    { bucket_id: "unavailable", storage_path: "2/c.pdf" },
  ], (bucket) => Promise.resolve(bucket === "sheets"), (bucket, paths) => {
    completed.push([bucket, ...paths]);
    return Promise.resolve();
  });
  assertEquals(count, 2);
  assertEquals(completed, [["sheets", "1/a.pdf", "1/b.pdf"]]);
});

Deno.test("an acknowledgement failure propagates so files can be retried", async () => {
  await assertRejects(() => cleanFiles([{ bucket_id: "sheets", storage_path: "1/a.pdf" }],
    () => Promise.resolve(true), () => Promise.reject(new Error("database unavailable"))), Error, "database unavailable");
});
