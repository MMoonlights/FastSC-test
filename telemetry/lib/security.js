import crypto from "node:crypto";
import { rpc } from "./supabase";

const secret = process.env.TELEMETRY_SIGNING_SECRET;
if (!secret) throw new Error("Telemetry signing secret is not configured");

function hmac(value) {
  return crypto.createHmac("sha256", secret).update(value).digest("base64url");
}

function clientIp(request) {
  const forwarded = request.headers.get("x-vercel-forwarded-for")
    || request.headers.get("x-forwarded-for")
    || request.headers.get("x-real-ip")
    || "unknown";
  return String(forwarded).split(",")[0].trim();
}

function ipBinding(request) {
  return hmac("ip:" + clientIp(request));
}

function bearer(request) {
  const auth = request.headers.get("authorization") || "";
  return auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
}

function safeEqual(a, b) {
  try {
    const left = Buffer.from(String(a));
    const right = Buffer.from(String(b));
    return left.length === right.length && crypto.timingSafeEqual(left, right);
  } catch {
    return false;
  }
}

export function issueSession(request) {
  const payload = Buffer.from(JSON.stringify({
    v: 1,
    exp: Math.floor(Date.now() / 1000) + 900,
    ip: ipBinding(request),
    nonce: crypto.randomBytes(12).toString("base64url"),
  })).toString("base64url");
  const signature = hmac("token:" + payload);
  return {
    token: payload + "." + signature,
    expiresIn: 900,
  };
}

export function verifySession(request) {
  const token = bearer(request);
  const split = token.split(".");
  if (split.length !== 2) return false;

  const [payload, signature] = split;
  if (!safeEqual(signature, hmac("token:" + payload))) return false;

  try {
    const decoded = JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
    const now = Math.floor(Date.now() / 1000);
    if (decoded.v !== 1 || !Number.isInteger(decoded.exp)) return false;
    if (decoded.exp < now || decoded.exp > now + 930) return false;
    if (!safeEqual(decoded.ip, ipBinding(request))) return false;
    return true;
  } catch {
    return false;
  }
}

export async function consumeRateLimit(request, scope, limit, windowSeconds) {
  const day = new Date().toISOString().slice(0, 10);
  const bucket = hmac("rate:" + day + ":" + scope + ":" + clientIp(request));
  const result = await rpc("fastsc_consume_rate_limit", {
    p_bucket: bucket,
    p_limit: limit,
    p_window_seconds: windowSeconds,
  });
  return result.ok && result.data === true;
}
