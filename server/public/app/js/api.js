// Klien API: token di localStorage (aman bila diblokir), 401 -> login.
let mem = '';
export const getToken = () => { try { return localStorage.getItem('ace_token') || mem; } catch { return mem; } };
export const setToken = (t) => { mem = t || ''; try { t ? localStorage.setItem('ace_token', t) : localStorage.removeItem('ace_token'); } catch { /* abaikan */ } };
export async function api(path, { method = 'GET', body, query } = {}) {
  const qs = query ? '?' + new URLSearchParams(Object.entries(query).filter(([, v]) => v !== '' && v != null)).toString() : '';
  let r, j;
  try {
    r = await fetch('/api' + path + qs, { method, headers: { ...(body ? { 'Content-Type': 'application/json' } : {}), ...(getToken() ? { Authorization: 'Bearer ' + getToken() } : {}) }, body: body ? JSON.stringify(body) : undefined });
    j = await r.json().catch(() => ({}));
  } catch { throw Object.assign(new Error('Tidak dapat terhubung ke server. Periksa koneksi Anda.'), { status: 0 }); }
  if (r.status === 401 && !path.startsWith('/auth/login') && !path.startsWith('/auth/register')) { setToken(''); location.hash = '#/login'; }
  if (!r.ok || j.success === false) throw Object.assign(new Error(j.message || 'Terjadi kesalahan (' + r.status + ')'), { status: r.status, body: j });
  return j;
}
export const get = (p, query) => api(p, { query });
export const send = (method, p, body) => api(p, { method, body });
