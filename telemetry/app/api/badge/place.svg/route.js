import { badgeSvg, publicStats, svgResponse } from "../../../../lib/public-stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const data = await publicStats();
    const place = data?.topPlace || {};
    const name = place.game && place.game !== "Unknown" ? place.game : (place.placeId ? "Place " + place.placeId : "No data");
    const suffix = place.placeId ? " · " + place.placeId : "";
    return svgResponse(badgeSvg("FASTSC · POPULAR PLACE", name + suffix, 520));
  } catch {
    return svgResponse(badgeSvg("FASTSC · POPULAR PLACE", "unavailable", 520));
  }
}
