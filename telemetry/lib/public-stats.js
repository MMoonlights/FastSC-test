import { rpc } from "./supabase";

export async function publicStats() {
  const result = await rpc("fastsc_public_stats", {});
  if (!result.ok || !result.data) throw new Error("stats_unavailable");
  return result.data;
}

export function escapeXml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

export function badgeSvg(label, value, width = 420) {
  const safeLabel = escapeXml(label);
  const safeValue = escapeXml(value);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="72" viewBox="0 0 ${width} 72" role="img" aria-label="${safeLabel}: ${safeValue}">
  <rect width="${width}" height="72" rx="14" fill="#0b0d12"/>
  <rect x="1" y="1" width="${width - 2}" height="70" rx="13" fill="none" stroke="#2a2e3b"/>
  <text x="20" y="29" font-family="Arial,sans-serif" font-size="13" font-weight="700" fill="#ff5674">${safeLabel}</text>
  <text x="20" y="52" font-family="Arial,sans-serif" font-size="20" font-weight="700" fill="#f6f7fa">${safeValue}</text>
</svg>`;
}

export function svgResponse(svg) {
  return new Response(svg, {
    headers: {
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
