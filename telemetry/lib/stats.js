import { countPrefix, isoDay, listAll, readMany } from "./blob";

function dayKeys(days) {
  const keys = [];
  const now = new Date();
  for (let index = days - 1; index >= 0; index -= 1) {
    const date = new Date(now);
    date.setUTCDate(now.getUTCDate() - index);
    keys.push(isoDay(date));
  }
  return keys;
}

function top(records, key, limit = 10) {
  const counts = new Map();
  for (const record of records) {
    const value = record?.[key];
    if (!value) continue;
    counts.set(value, (counts.get(value) || 0) + 1);
  }
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || String(a[0]).localeCompare(String(b[0])))
    .slice(0, limit)
    .map(([name, count]) => ({ name, count }));
}

async function blobsForDays(kind, keys) {
  const groups = await Promise.all(
    keys.map((key) => listAll(`events/${kind}/${key}/`, 10000)),
  );
  return groups.flat();
}

export async function buildStats(days = 7) {
  const safeDays = Math.max(1, Math.min(Number(days) || 7, 30));
  const keys = dayKeys(safeDays);
  const today = keys[keys.length - 1];

  const [total, daily, injectBlobs, moduleBlobs, featureBlobs] = await Promise.all([
    countPrefix("events/inject/"),
    Promise.all(keys.map(async (key) => ({
      date: key,
      count: await countPrefix(`events/inject/${key}/`),
    }))),
    blobsForDays("inject", keys),
    blobsForDays("module", keys),
    blobsForDays("feature", keys),
  ]);

  const [injects, modules, features] = await Promise.all([
    readMany(injectBlobs),
    readMany(moduleBlobs),
    readMany(featureBlobs),
  ]);

  return {
    generatedAt: new Date().toISOString(),
    rangeDays: safeDays,
    injections: {
      total,
      today: daily.find((item) => item.date === today)?.count || 0,
      range: daily.reduce((sum, item) => sum + item.count, 0),
      daily,
    },
    top: {
      executors: top(injects, "executor"),
      countries: top(injects, "country"),
      games: top(modules.length ? modules : injects, "game"),
      maps: top(modules, "map"),
      features: top(features, "feature"),
    },
    eventCounts: {
      inject: injects.length,
      module: modules.length,
      feature: features.length,
    },
  };
}

export async function recentFeedback(limit = 100) {
  const safeLimit = Math.max(1, Math.min(Number(limit) || 100, 250));
  const now = new Date();
  const blobs = [];
  for (let offset = 0; offset < 90 && blobs.length < safeLimit * 2; offset += 1) {
    const date = new Date(now);
    date.setUTCDate(now.getUTCDate() - offset);
    const day = isoDay(date);
    const items = await listAll(`feedback/${day}/`, safeLimit * 2);
    blobs.push(...items);
  }
  blobs.sort((a, b) => new Date(b.uploadedAt) - new Date(a.uploadedAt));
  const records = await readMany(blobs.slice(0, safeLimit), safeLimit);
  records.sort((a, b) => new Date(b.ts) - new Date(a.ts));
  return records;
}
