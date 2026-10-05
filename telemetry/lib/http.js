export function cleanString(value, max = 80) {
  if (value === null || value === undefined) return "";
  return String(value).replace(/[\u0000-\u001f\u007f]/g, "").trim().slice(0, max);
}

export function countryFrom(request) {
  const raw = request.headers.get("x-vercel-ip-country") || "XX";
  const value = cleanString(raw, 2).toUpperCase();
  return /^[A-Z]{2}$/.test(value) ? value : "XX";
}

export function corsHeaders(extra = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization,x-api-key,X-FastSC-Client",
    "Access-Control-Max-Age": "86400",
    ...extra,
  };
}

export function json(data, status = 200, extra = {}) {
  return Response.json(data, {
    status,
    headers: corsHeaders({
      "Cache-Control": "no-store",
      ...extra,
    }),
  });
}

export async function readJsonLimited(request, maxBytes = 8192) {
  const length = Number(request.headers.get("content-length") || 0);
  if (length > maxBytes) throw new Error("payload_too_large");
  const text = await request.text();
  if (text.length > maxBytes) throw new Error("payload_too_large");
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    throw new Error("invalid_json");
  }
}
