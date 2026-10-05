import { escapeXml, publicStats, svgResponse } from "../../../lib/public-stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const data = await publicStats();
    const total = Number(data?.injections?.total || 0);
    const today = Number(data?.injections?.today || 0);
    const place = data?.topPlace || {};
    const placeName = place.game && place.game !== "Unknown"
      ? place.game
      : (place.placeId ? "Place " + place.placeId : "No data");
    const placeId = place.placeId ? " · " + place.placeId : "";

    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="760" height="178" viewBox="0 0 760 178" role="img" aria-label="FastSC telemetry">
  <rect width="760" height="178" rx="20" fill="#0b0d12"/>
  <rect x="1" y="1" width="758" height="176" rx="19" fill="none" stroke="#2a2e3b"/>
  <text x="28" y="35" font-family="Arial,sans-serif" font-size="14" font-weight="700" fill="#ff5674">FASTSC TELEMETRY</text>

  <text x="28" y="72" font-family="Arial,sans-serif" font-size="12" fill="#8f96a8">TOTAL INJECTIONS</text>
  <text x="28" y="102" font-family="Arial,sans-serif" font-size="27" font-weight="700" fill="#f6f7fa">${total.toLocaleString()}</text>

  <text x="250" y="72" font-family="Arial,sans-serif" font-size="12" fill="#8f96a8">TODAY</text>
  <text x="250" y="102" font-family="Arial,sans-serif" font-size="27" font-weight="700" fill="#f6f7fa">${today.toLocaleString()}</text>

  <text x="430" y="72" font-family="Arial,sans-serif" font-size="12" fill="#8f96a8">POPULAR PLACE · 7D</text>
  <text x="430" y="99" font-family="Arial,sans-serif" font-size="19" font-weight="700" fill="#f6f7fa">${escapeXml(placeName)}</text>
  <text x="430" y="124" font-family="Arial,sans-serif" font-size="13" fill="#8f96a8">${escapeXml(placeId || "No place yet")}</text>
</svg>`;

    return svgResponse(svg);
  } catch {
    return svgResponse('<svg xmlns="http://www.w3.org/2000/svg" width="420" height="80"><rect width="100%" height="100%" rx="16" fill="#11131a"/><text x="24" y="48" fill="#f4f5f7" font-family="Arial" font-size="18">FastSC telemetry unavailable</text></svg>');
  }
}
