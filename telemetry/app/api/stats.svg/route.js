import { buildStats } from "../../../lib/stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function xml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

export async function GET() {
  try {
    const stats = await buildStats(7);
    const topGame = stats.top.games[0]?.name || "No data";
    const topExecutor = stats.top.executors[0]?.name || "No data";
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="740" height="174" viewBox="0 0 740 174" role="img" aria-label="FastSC telemetry statistics">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#151821"/>
      <stop offset="1" stop-color="#090a0f"/>
    </linearGradient>
    <linearGradient id="accent" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ff355d"/>
      <stop offset="1" stop-color="#ff7a45"/>
    </linearGradient>
  </defs>
  <rect width="740" height="174" rx="22" fill="url(#bg)"/>
  <rect x="1" y="1" width="738" height="172" rx="21" fill="none" stroke="#2a2e3b"/>
  <rect x="28" y="28" width="5" height="118" rx="2.5" fill="url(#accent)"/>
  <text x="52" y="54" font-family="Inter,Segoe UI,Arial,sans-serif" font-size="15" font-weight="700" fill="#ff5674">FastSC TELEMETRY</text>
  <text x="52" y="91" font-family="Inter,Segoe UI,Arial,sans-serif" font-size="30" font-weight="800" fill="#f6f7fa">${stats.injections.total.toLocaleString()} total injections</text>
  <text x="52" y="120" font-family="Inter,Segoe UI,Arial,sans-serif" font-size="15" fill="#a6adbd">7 days: ${stats.injections.range.toLocaleString()} · today: ${stats.injections.today.toLocaleString()}</text>
  <text x="52" y="144" font-family="Inter,Segoe UI,Arial,sans-serif" font-size="14" fill="#7f8798">Top game: ${xml(topGame)} · Top executor: ${xml(topExecutor)}</text>
</svg>`;

    return new Response(svg, {
      headers: {
        "Content-Type": "image/svg+xml; charset=utf-8",
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
        "X-Content-Type-Options": "nosniff",
      },
    });
  } catch {
    return new Response('<svg xmlns="http://www.w3.org/2000/svg" width="420" height="80"><rect width="100%" height="100%" rx="16" fill="#11131a"/><text x="24" y="48" fill="#f4f5f7" font-family="Arial" font-size="18">FastSC telemetry unavailable</text></svg>', {
      status: 503,
      headers: { "Content-Type": "image/svg+xml; charset=utf-8", "Cache-Control": "no-store" },
    });
  }
}
