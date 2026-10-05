import { get, list, put } from "@vercel/blob";

function dayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

async function writeJson(pathname, value) {
  return put(pathname, JSON.stringify(value), {
    access: "private",
    addRandomSuffix: false,
    contentType: "application/json; charset=utf-8",
  });
}

export async function writeEvent(kind, value) {
  const stamp = Date.now();
  const pathname = `events/${kind}/${dayKey()}/${stamp}-${crypto.randomUUID()}.json`;
  return writeJson(pathname, value);
}

export async function writeFeedback(value) {
  const stamp = Date.now();
  const pathname = `feedback/${dayKey()}/${stamp}-${crypto.randomUUID()}.json`;
  return writeJson(pathname, value);
}

export async function listAll(prefix, max = 20000) {
  const blobs = [];
  let cursor;
  do {
    const page = await list({ prefix, cursor, limit: 1000 });
    for (const blob of page.blobs) {
      blobs.push(blob);
      if (blobs.length >= max) return blobs;
    }
    cursor = page.cursor;
  } while (cursor);
  return blobs;
}

export async function countPrefix(prefix, max = 200000) {
  let count = 0;
  let cursor;
  do {
    const page = await list({ prefix, cursor, limit: 1000 });
    count += page.blobs.length;
    if (count >= max) return count;
    cursor = page.cursor;
  } while (cursor);
  return count;
}

export async function readJson(blob) {
  const result = await get(blob.pathname, { access: "private" });
  if (!result || result.statusCode !== 200) return null;
  try {
    return await new Response(result.stream).json();
  } catch {
    return null;
  }
}

export async function readMany(blobs, max = 5000) {
  const selected = blobs.slice(0, max);
  const output = [];
  for (let offset = 0; offset < selected.length; offset += 25) {
    const batch = selected.slice(offset, offset + 25);
    const values = await Promise.all(batch.map(readJson));
    for (const value of values) if (value) output.push(value);
  }
  return output;
}

export function isoDay(date = new Date()) {
  return dayKey(date);
}
