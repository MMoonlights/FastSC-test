import { json } from "../../../lib/http";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  return json({ ok: true, service: "fastsc-telemetry-api", time: new Date().toISOString() });
}
