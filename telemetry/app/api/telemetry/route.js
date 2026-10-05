import { cleanString, countryFrom, json, readJsonLimited } from "../../../lib/http";
import { insert } from "../../../lib/supabase";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export function OPTIONS() {
  return json({ ok: true });
}

export async function POST(request) {
  try {
    const body = await readJsonLimited(request);
    const type = cleanString(body.type, 16);
    if (!["inject", "module", "feature"].includes(type)) return json({ error: "invalid_type" }, 400);

    const record = {
      event_type: type,
      executor: cleanString(body.executor, 80) || "Unknown",
      country: countryFrom(request),
      game: cleanString(body.game, 80) || "Unknown",
      slug: cleanString(body.slug, 80),
      map: cleanString(body.map, 80),
      feature: cleanString(body.feature, 120),
      version: cleanString(body.version, 40),
      place_id: cleanString(body.placeId, 32),
    };

    if (type === "feature" && !record.feature) return json({ error: "missing_feature" }, 400);

    const response = await insert("fastsc_events", record);
    if (!response.ok) return json({ error: "write_failed" }, 500);
    return json({ ok: true }, 202);
  } catch (error) {
    const message = String(error?.message || error);
    if (message === "payload_too_large") return json({ error: message }, 413);
    if (message === "invalid_json") return json({ error: message }, 400);
    return json({ error: "write_failed" }, 500);
  }
}
