const url = process.env.FASTSC_SUPABASE_URL || "https://stkmzwhmuxzvaptuwcvr.supabase.co";
const key = process.env.FASTSC_SUPABASE_KEY || "sb_publishable_OTMS_8cGZB5lm2iKTeWntw_nEaZgyXx";

export async function supabase(path, init = {}) {
  return fetch(url + path, {
    ...init,
    headers: {
      apikey: key,
      Authorization: "Bearer " + key,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
    cache: "no-store",
  });
}

export async function insert(table, value) {
  return supabase("/rest/v1/" + table, {
    method: "POST",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify(value),
  });
}

export async function rpc(name, value) {
  const response = await supabase("/rest/v1/rpc/" + name, {
    method: "POST",
    body: JSON.stringify(value || {}),
  });
  const text = await response.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  return { ok: response.ok, status: response.status, data };
}
