import { isAdmin } from "../../../../lib/auth";
import { json } from "../../../../lib/http";
import { recentFeedback } from "../../../../lib/stats";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request) {
  if (!isAdmin(request)) return json({ error: "unauthorized" }, 401);
  const url = new URL(request.url);
  const limit = Number(url.searchParams.get("limit") || 100);
  try {
    const feedback = await recentFeedback(limit);
    return json({ generatedAt: new Date().toISOString(), count: feedback.length, feedback });
  } catch {
    return json({ error: "feedback_failed" }, 500);
  }
}
