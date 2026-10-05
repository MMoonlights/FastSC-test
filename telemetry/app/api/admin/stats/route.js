import { json } from "../../../../lib/http";
import { consumeRateLimit } from "../../../../lib/security";
import { rpc } from "../../../../lib/supabase";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function adminKey(request) {
  const auth = request.headers.get("authorization") || "";
  if (auth.startsWith("Bearer ")) return auth.slice(7).trim();
  return (request.headers.get("x-api-key") || "").trim();
}

export async function GET(request) {
  if (!(await consumeRateLimit(request, "admin:stats", 30, 60))) return json({ error: "rate_limited" }, 429);
  const url = new URL(request.url);
  const days = Math.max(1, Math.min(Number(url.searchParams.get("days") || 7), 30));
  const result = await rpc("fastsc_admin_stats", { p_key: adminKey(request), p_days: days });
  if (!result.ok) {
    if (String(result.data?.message || result.data).toLowerCase().includes("unauthorized")) {
      return json({ error: "unauthorized" }, 401);
    }
    return json({ error: "stats_failed" }, 500);
  }
  return json(result.data);
}
