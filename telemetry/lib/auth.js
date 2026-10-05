export function isAdmin(request) {
  const expected = process.env.ADMIN_KEY;
  if (!expected) return false;
  const auth = request.headers.get("authorization") || "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  const apiKey = (request.headers.get("x-api-key") || "").trim();
  return bearer === expected || apiKey === expected;
}
