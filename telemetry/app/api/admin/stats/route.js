import { isAdmin } from "../../../../lib/auth";
import { json } from "../../../../lib/http";
import { buildStats } from "../../../../lib/stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request) {
  if (!isAdmin(request)) return json({ error: "unauthorized" }, 401);
  const url = new URL(request.url);
  const days = Number(url.searchParams.get("days") || 7);
  try {
    return json(await buildStats(days));
  } catch {
    return json({ error: "stats_failed" }, 500);
  }
}
