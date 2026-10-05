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
  if (!(await consumeRateLimit(request, "admin:feedback", 20, 60))) return json({ error: "rate_limited" }, 429);
  const url = new URL(request.url);
  const limit = Math.max(1, Math.min(Number(url.searchParams.get("limit") || 100), 250));
  const result = await rpc("fastsc_admin_feedback", { p_key: adminKey(request), p_limit: limit });
  if (!result.ok) {
    if (String(result.data?.message || result.data).toLowerCase().includes("unauthorized")) {
      return json({ error: "unauthorized" }, 401);
    }
    return json({ error: "feedback_failed" }, 500);
  }
  return json({
    generatedAt: new Date().toISOString(),
    count: Array.isArray(result.data) ? result.data.length : 0,
    feedback: result.data || [],
  });
}
