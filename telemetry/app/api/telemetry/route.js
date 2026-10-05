import { cleanString, countryFrom, json, readJsonLimited } from "../../../lib/http";
import { writeEvent } from "../../../lib/blob";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const allowed = new Set(["inject", "module", "feature"]);

export function OPTIONS() {
  return json({ ok: true });
}

export async function POST(request) {
  try {
    const body = await readJsonLimited(request);
    const type = cleanString(body.type, 16);
    if (!allowed.has(type)) return json({ error: "invalid_type" }, 400);

    const record = {
      schema: 1,
      type,
      ts: new Date().toISOString(),
      country: countryFrom(request),
      executor: cleanString(body.executor, 80) || "Unknown",
      game: cleanString(body.game, 80) || "Unknown",
      slug: cleanString(body.slug, 80),
      map: cleanString(body.map, 80),
      feature: cleanString(body.feature, 120),
      version: cleanString(body.version, 40),
      placeId: cleanString(body.placeId, 32),
    };

    if (type === "feature" && !record.feature) {
      return json({ error: "missing_feature" }, 400);
    }

    await writeEvent(type, record);
    return json({ ok: true }, 202);
  } catch (error) {
    const message = String(error?.message || error);
    if (message === "payload_too_large") return json({ error: message }, 413);
    if (message === "invalid_json") return json({ error: message }, 400);
    return json({ error: "write_failed" }, 500);
  }
}
