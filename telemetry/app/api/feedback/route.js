import { cleanString, countryFrom, json, readJsonLimited } from "../../../lib/http";
import { writeFeedback } from "../../../lib/blob";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export function OPTIONS() {
  return json({ ok: true });
}

export async function POST(request) {
  try {
    const body = await readJsonLimited(request, 4096);
    const message = cleanString(body.message, 2000);
    if (message.length < 2) return json({ error: "feedback_too_short" }, 400);

    const record = {
      schema: 1,
      type: "feedback",
      ts: new Date().toISOString(),
      country: countryFrom(request),
      message,
      executor: cleanString(body.executor, 80) || "Unknown",
      game: cleanString(body.game, 80) || "Unknown",
      slug: cleanString(body.slug, 80),
      map: cleanString(body.map, 80),
      version: cleanString(body.version, 40),
      placeId: cleanString(body.placeId, 32),
    };

    await writeFeedback(record);
    return json({ ok: true }, 202);
  } catch (error) {
    const message = String(error?.message || error);
    if (message === "payload_too_large") return json({ error: message }, 413);
    if (message === "invalid_json") return json({ error: message }, 400);
    return json({ error: "write_failed" }, 500);
  }
}
