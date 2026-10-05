import { json } from "../../../lib/http";
import { publicStats } from "../../../lib/public-stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    return json(await publicStats(), 200, {
      "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300",
    });
  } catch {
    return json({ error: "stats_unavailable" }, 503);
  }
}
