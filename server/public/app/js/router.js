// Router hash + state bersama (dipisah dari app.js agar view bisa impor tanpa siklus).
export const state = { user: null };
export const routes = [];
export function route(pattern, roles, fn, opts = {}) {
  const keys = [];
  const re = new RegExp('^' + pattern.replace(/:(\w+)/g, (_, k) => { keys.push(k); return '([^/]+)'; }) + '$');
  routes.push({ re, keys, roles, fn, title: opts.title || '', bare: !!opts.bare });
}
export const homeFor = (u) => (u?.role === 'admin' ? '#/admin' : u?.role === 'owner' ? '#/owner' : u ? '#/me' : '#/login');
export const go = (h) => { if (location.hash === h) window.dispatchEvent(new HashChangeEvent('hashchange')); else location.hash = h; };
export const leaveHooks = [];
export const onLeave = (fn) => leaveHooks.push(fn);
export function parseHash() {
  const raw = location.hash.replace(/^#\/?/, ''), [p, q = ''] = raw.split('?');
  return { path: p.replace(/\/+$/, ''), query: Object.fromEntries(new URLSearchParams(q)) };
}
