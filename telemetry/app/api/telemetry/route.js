import { cleanString, countryFrom, json, readJsonLimited } from "../../../lib/http";
import { consumeRateLimit, verifySession } from "../../../lib/security";
import { insert } from "../../../lib/supabase";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export function OPTIONS() {
  return json({ ok: true });
}

export async function POST(request) {
  if (!verifySession(request)) return json({ error: "unauthorized" }, 401);

  try {
    const body = await readJsonLimited(request);
    const type = cleanString(body.type, 16);
    if (!["inject", "module", "feature"].includes(type)) return json({ error: "invalid_type" }, 400);

    const placeId = cleanString(body.placeId, 32);
    const version = cleanString(body.version, 40);
    const slug = cleanString(body.slug, 80).toLowerCase();

    if (!/^\d{1,20}$/.test(placeId) || placeId === "0") {
      return json({ error: "invalid_place" }, 400);
    }
    if (version && !/^\d{4}\.\d{2}\.\d{2}$/.test(version)) {
      return json({ error: "invalid_version" }, 400);
    }
    if (slug && !/^[a-z0-9-]{1,80}$/.test(slug)) {
      return json({ error: "invalid_slug" }, 400);
    }

    const record = {
      event_type: type,
      executor: cleanString(body.executor, 80) || "Unknown",
      country: countryFrom(request),
      game: cleanString(body.game, 80) || "Unknown",
      slug,
      map: cleanString(body.map, 80),
      feature: cleanString(body.feature, 120),
      version,
      place_id: placeId,
    };

    if (type === "feature" && !record.feature) return json({ error: "missing_feature" }, 400);

    const limits = {
      inject: [10, 600],
      module: [20, 600],
      feature: [100, 600],
    };
    const [limit, windowSeconds] = limits[type];
    const allowed = await consumeRateLimit(request, "event:" + type, limit, windowSeconds);
    if (!allowed) return json({ error: "rate_limited" }, 429);

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
