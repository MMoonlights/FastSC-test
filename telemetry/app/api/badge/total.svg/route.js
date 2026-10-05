import { badgeSvg, publicStats, svgResponse } from "../../../../lib/public-stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const data = await publicStats();
    return svgResponse(badgeSvg("FASTSC · TOTAL INJECTIONS", Number(data?.injections?.total || 0).toLocaleString()));
  } catch {
    return svgResponse(badgeSvg("FASTSC · TOTAL INJECTIONS", "unavailable"));
  }
}
