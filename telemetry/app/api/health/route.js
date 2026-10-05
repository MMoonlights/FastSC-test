import { json } from "../../../lib/http";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  return json({
    ok: true,
    service: "fastsc-telemetry",
    storageConfigured: Boolean(process.env.BLOB_READ_WRITE_TOKEN),
    adminConfigured: Boolean(process.env.ADMIN_KEY),
    time: new Date().toISOString(),
  });
}
