import { rpc } from "../../../lib/supabase";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function escapeXml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

export async function GET() {
  const result = await rpc("fastsc_public_stats", {});
  const data = result.data;
  if (!result.ok || !data) {
    return new Response('<svg xmlns="http://www.w3.org/2000/svg" width="420" height="80"><rect width="100%" height="100%" rx="16" fill="#11131a"/><text x="24" y="48" fill="#f4f5f7" font-family="Arial" font-size="18">FastSC telemetry unavailable</text></svg>', {
      status: 503,
      headers: { "Content-Type": "image/svg+xml; charset=utf-8", "Cache-Control": "no-store" },
    });
  }

  const total = Number(data?.injections?.total || 0);
  const today = Number(data?.injections?.today || 0);
  const week = Number(data?.injections?.week || 0);
  const topGame = data?.topGame?.name || "No data";
  const topExecutor = data?.topExecutor?.name || "No data";

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="740" height="174" viewBox="0 0 740 174">
  <rect width="740" height="174" rx="22" fill="#0b0d12"/>
  <rect x="1" y="1" width="738" height="172" rx="21" fill="none" stroke="#2a2e3b"/>
  <text x="32" y="48" font-family="Arial,sans-serif" font-size="15" font-weight="700" fill="#ff5674">FastSC TELEMETRY</text>
  <text x="32" y="88" font-family="Arial,sans-serif" font-size="30" font-weight="700" fill="#f6f7fa">${total.toLocaleString()} total injections</text>
  <text x="32" y="119" font-family="Arial,sans-serif" font-size="15" fill="#a6adbd">7 days: ${week.toLocaleString()} · today: ${today.toLocaleString()}</text>
  <text x="32" y="145" font-family="Arial,sans-serif" font-size="14" fill="#7f8798">Top game: ${escapeXml(topGame)} · Top executor: ${escapeXml(topExecutor)}</text>
</svg>`;

  return new Response(svg, {
    headers: {
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
