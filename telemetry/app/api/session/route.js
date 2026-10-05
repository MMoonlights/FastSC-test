import { json } from "../../../lib/http";
import { consumeRateLimit, issueSession } from "../../../lib/security";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export function OPTIONS() {
  return json({ ok: true });
}

export async function POST(request) {
  if (request.headers.get("x-fastsc-client") !== "luau-1") return json({ error: "invalid_client" }, 403);
  const allowed = await consumeRateLimit(request, "session", 20, 3600);
  if (!allowed) return json({ error: "rate_limited" }, 429);
  return json(issueSession(request), 200);
}
