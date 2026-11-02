export type QueuedFile = { bucket_id: string; storage_path: string };

/** Remove only paths the database queued after deleting their team. A failed
 * request keeps its batch in the queue so the next invocation can retry. */
export async function cleanFiles(
  files: QueuedFile[],
  remove: (bucket: string, paths: string[]) => Promise<boolean>,
  complete: (bucket: string, paths: string[]) => Promise<void>,
): Promise<number> {
  const buckets = new Map<string, string[]>();
  for (const file of files) {
    const paths = buckets.get(file.bucket_id) ?? [];
    paths.push(file.storage_path);
    buckets.set(file.bucket_id, paths);
  }
  let removed = 0;
  for (const [bucket, paths] of buckets) {
    if (!await remove(bucket, paths)) continue;
    await complete(bucket, paths);
    removed += paths.length;
  }
  return removed;
}
