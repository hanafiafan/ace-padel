// UI kit Ace Padel: html`` aman-XSS, toast, modal/drawer, konfirmasi, tabel, badge, skeleton, grafik, format.
const MAP = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => MAP[c]);
class Raw { constructor(s) { this.s = s; } toString() { return this.s; } }
export const raw = (s) => new Raw(s);
const val = (v) => (v instanceof Raw ? v.s : Array.isArray(v) ? v.map(val).join('') : v == null || v === false ? '' : esc(v));
export const html = (st, ...v) => new Raw(st.reduce((a, s, i) => a + s + (i < v.length ? val(v[i]) : ''), ''));
export const mount = (el, h) => { el.innerHTML = h instanceof Raw ? h.s : esc(h); return el; };
export const $ = (s, r = document) => r.querySelector(s);
export const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const ons = new WeakMap();
// Delegasi event; memasang ulang (selector sama) menggantikan handler lama sehingga aman dipanggil di tiap render.
export const on = (root, type, sel, fn) => {
  const m = ons.get(root) || ons.set(root, new Map()).get(root), k = type + '|' + sel;
  if (m.has(k)) root.removeEventListener(type, m.get(k));
  const h = (e) => { const t = e.target.closest(sel); if (t && root.contains(t)) fn(e, t); };
  m.set(k, h); root.addEventListener(type, h);
};
export const debounce = (fn, ms = 300) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };

// ---------- ikon (gaya lucide) ----------
const IC = {
  dashboard: '<rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/>',
  court: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M12 5v14M3 12h18"/>',
  calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
  ticket: '<path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2z"/><path d="M13 5v2M13 17v2M13 11v2"/>',
  scan: '<path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M7 12h10"/>',
  star: '<path d="m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8-6.2-3.3-6.2 3.3L7 14.2 2 9.3l6.9-1z"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>',
  tag: '<path d="M12 2H2v10l9.3 9.3a1 1 0 0 0 1.4 0l8.6-8.6a1 1 0 0 0 0-1.4z"/><circle cx="7" cy="7" r="1.5"/>',
  coach: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  flag: '<path d="M4 22V4a1 1 0 0 1 1-1h13l-2 5 2 5H5"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z"/>',
  menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
  x: '<path d="M18 6 6 18M6 6l12 12"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.9 1.9 0 0 0 3.4 0"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/>',
  chevron: '<path d="m9 18 6-6-6-6"/>',
  left: '<path d="m15 18-6-6 6-6"/>',
  trash: '<path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m3 0v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>',
  edit: '<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/>',
  upload: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/>',
  qr: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3h-3zM20 14v.01M14 20h3M20 17v4"/>',
  wallet: '<path d="M20 7H5a2 2 0 0 1 0-4h13v4zM3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"/><path d="M17 14h4v-4h-4a2 2 0 0 0 0 4z"/>',
  trend: '<path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/>',
  alert: '<circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/>',
  lock: '<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  home: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
  more: '<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
  inbox: '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.5 5.1 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.5-6.9A2 2 0 0 0 16.7 4H7.3a2 2 0 0 0-1.8 1.1z"/>',
};
export const icon = (n, c = '') => raw(`<svg class="ic ${esc(c)}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${IC[n] || ''}</svg>`);

// ---------- format ----------
export const rupiah = (k) => 'Rp' + Math.round(Number(k || 0) * 1000).toLocaleString('id-ID');
export const num = (n) => Number(n || 0).toLocaleString('id-ID');
const WIB = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jakarta' });
export const today = () => WIB.format(new Date());
export const addDays = (d, n) => { const t = new Date(d + 'T12:00:00Z'); t.setUTCDate(t.getUTCDate() + n); return t.toISOString().slice(0, 10); };
export const dateId = (d, o = { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' }) => (d ? new Date(d + 'T12:00:00Z').toLocaleDateString('id-ID', { timeZone: 'UTC', ...o }) : '-');
export const dateTimeId = (iso) => (iso ? new Date(iso).toLocaleString('id-ID', { timeZone: 'Asia/Jakarta', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '-');
export const initials = (n) => String(n || '?').split(/\s+/).slice(0, 2).map((s) => s[0]).join('').toUpperCase();
export const imgUrl = (c) => c?.imageUrl || '/img/logo.png';

// ---------- badge ----------
const TONES = {
  'Terkonfirmasi': ['info', 'Terkonfirmasi'], 'Check-in Selesai': ['ok', 'Check-in'], 'Dibatalkan': ['danger', 'Dibatalkan'], 'Maintenance': ['muted', 'Diblokir'],
  'Lunas': ['ok', 'Lunas'], 'Menunggu': ['warn', 'Menunggu bayar'], 'Belum Bayar': ['muted', 'Bayar di tempat'], 'Dikembalikan': ['info', 'Dikembalikan'], 'Kedaluwarsa': ['danger', 'Kedaluwarsa'],
  pending: ['warn', 'Menunggu'], approved: ['ok', 'Disetujui'], rejected: ['danger', 'Ditolak'], suspended: ['muted', 'Ditangguhkan'],
  active: ['ok', 'Aktif'], inactive: ['muted', 'Nonaktif'], admin: ['info', 'Admin'], owner: ['warn', 'Pemilik'], player: ['muted', 'Pemain'],
};
export const badge = (text, tone = 'muted') => html`<span class="badge ${tone}">${text}</span>`;
export const statusBadge = (s) => { const [t, l] = TONES[s] || ['muted', s]; return badge(l, t); };

// ---------- komponen kecil ----------
export const skeleton = (n = 3, h = 64) => html`<div class="skels" aria-busy="true" aria-label="Memuat">${Array.from({ length: n }, () => html`<div class="skel" style="height:${h}px"></div>`)}</div>`;
export const empty = (title, text = '', action = '') => html`<div class="empty">${icon('inbox')}<h3>${title}</h3><p>${text}</p>${action}</div>`;
export const errorState = (msg) => html`<div class="empty err">${icon('alert')}<h3>Gagal memuat</h3><p>${msg}</p><button class="btn" data-retry>Coba lagi</button></div>`;
export const avatar = (u) => (u?.photoUrl ? html`<img class="avatar" src="${u.photoUrl}" alt="">` : html`<span class="avatar" aria-hidden="true">${initials(u?.name)}</span>`);
export const pageHead = (title, sub = '', actions = '') => html`<header class="pagehead"><div><h1>${title}</h1>${sub ? html`<p>${sub}</p>` : ''}</div><div class="actions">${actions}</div></header>`;
export const stat = (label, value, ic, spark, hint = '') => html`<div class="card stat"><div class="stat-top"><span class="stat-ic">${icon(ic)}</span><span class="stat-label">${label}</span></div><div class="stat-val">${value}</div><div class="stat-foot"><span class="muted">${hint}</span>${spark ? sparkline(spark) : ''}</div></div>`;

export function table(cols, rows, { empty: em } = {}) {
  if (!rows.length) return em || empty('Belum ada data');
  return html`<div class="tablewrap"><table class="table stack"><thead><tr>${cols.map((c) => html`<th class="${c.cls || ''}">${c.h}</th>`)}</tr></thead><tbody>${rows.map((r, i) => html`<tr data-i="${i}">${cols.map((c) => html`<td class="${c.cls || ''}" data-label="${c.h}">${c.cell(r, i)}</td>`)}</tr>`)}</tbody></table></div>`;
}

// ---------- grafik SVG ----------
export function sparkline(vals) {
  const w = 80, h = 28, max = Math.max(...vals, 1), pts = vals.map((v, i) => [(i / Math.max(vals.length - 1, 1)) * w, h - 3 - (v / max) * (h - 6)]);
  const d = pts.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join('');
  return raw(`<svg class="spark" viewBox="0 0 ${w} ${h}" aria-hidden="true"><path d="${d}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`);
}
let gid = 0;
export function areaChart(data, fmt = num) {
  const W = 640, H = 220, P = { l: 8, r: 8, t: 12, b: 8 }, max = Math.max(...data.map((d) => d.value), 1) * 1.1, id = 'g' + ++gid;
  const X = (i) => P.l + (i / Math.max(data.length - 1, 1)) * (W - P.l - P.r), Y = (v) => P.t + (1 - v / max) * (H - P.t - P.b);
  const line = data.map((d, i) => (i ? 'L' : 'M') + X(i).toFixed(1) + ' ' + Y(d.value).toFixed(1)).join('');
  const area = `${line}L${X(data.length - 1)} ${H - P.b}L${X(0)} ${H - P.b}Z`;
  const grid = [0, 1, 2, 3].map((i) => `<line x1="${P.l}" x2="${W - P.r}" y1="${P.t + (i / 3) * (H - P.t - P.b)}" y2="${P.t + (i / 3) * (H - P.t - P.b)}" class="gl"/>`).join('');
  const dots = data.map((d, i) => `<circle cx="${X(i).toFixed(1)}" cy="${Y(d.value).toFixed(1)}" r="9" class="hit" tabindex="0"><title>${esc(d.label)}: ${esc(fmt(d.value))}</title></circle><circle cx="${X(i).toFixed(1)}" cy="${Y(d.value).toFixed(1)}" r="3.5" class="dot" pointer-events="none"/>`).join('');
  return raw(`<div class="chart"><svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Grafik"><defs><linearGradient id="${id}" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="var(--blue)" stop-opacity=".35"/><stop offset="1" stop-color="var(--blue)" stop-opacity="0"/></linearGradient></defs>${grid}<path d="${area}" fill="url(#${id})"/><path d="${line}" class="ln"/>${dots}</svg><div class="chart-x"><span>${esc(data[0]?.label || '')}</span><span>${esc(data[data.length - 1]?.label || '')}</span></div></div>`);
}

// ---------- toast ----------
export function toast(msg, type = 'ok') {
  let box = $('#toasts');
  if (!box) { box = document.createElement('div'); box.id = 'toasts'; box.setAttribute('role', 'status'); box.setAttribute('aria-live', 'polite'); document.body.append(box); }
  const t = document.createElement('div'); t.className = 'toast ' + type;
  mount(t, html`${icon(type === 'ok' ? 'check' : 'alert')}<span>${msg}</span>`);
  box.append(t); setTimeout(() => { t.classList.add('out'); setTimeout(() => t.remove(), 250); }, 3800);
}

// ---------- modal / drawer ----------
export function openModal({ title, body = '', footer = '', side = false, wide = false, onClose } = {}) {
  const prev = document.activeElement, ov = document.createElement('div');
  ov.className = 'overlay'; ov.dataset.side = side ? '1' : '';
  mount(ov, html`<div class="dialog ${side ? 'drawer' : ''} ${wide ? 'wide' : ''}" role="dialog" aria-modal="true" aria-label="${title}"><div class="dlg-head"><h2>${title}</h2><button class="btn icon ghost" data-close aria-label="Tutup">${icon('x')}</button></div><div class="dlg-body">${body}</div>${footer ? html`<div class="dlg-foot">${footer}</div>` : ''}</div>`);
  document.body.append(ov); document.body.classList.add('noscroll');
  const dlg = $('.dialog', ov);
  const close = (v) => { if (!ov.isConnected) return; ov.classList.add('out'); document.body.classList.remove('noscroll'); setTimeout(() => ov.remove(), 150); document.removeEventListener('keydown', key); prev?.focus?.(); onClose?.(v); };
  const key = (e) => {
    if (ov !== $$('.overlay').pop()) return;
    if (e.key === 'Escape') close();
    if (e.key === 'Tab') { const f = $$('button,[href],input,select,textarea,[tabindex]:not([tabindex="-1"])', dlg).filter((x) => !x.disabled && x.offsetParent !== null); if (!f.length) return; const a = f[0], z = f[f.length - 1]; if (e.shiftKey && document.activeElement === a) { z.focus(); e.preventDefault(); } else if (!e.shiftKey && document.activeElement === z) { a.focus(); e.preventDefault(); } }
  };
  document.addEventListener('keydown', key);
  ov.addEventListener('mousedown', (e) => { if (e.target === ov) close(); });
  on(ov, 'click', '[data-close]', () => close());
  setTimeout(() => ($('[autofocus],input:not([type=hidden]),select,textarea', dlg) || $('[data-close]', dlg)).focus(), 30);
  return { el: ov, dlg, body: $('.dlg-body', ov), foot: $('.dlg-foot', ov), close };
}

export function confirmDialog({ title = 'Yakin?', message = '', confirmText = 'Ya, lanjutkan', danger = false } = {}) {
  return new Promise((res) => {
    let done = false;
    const m = openModal({ title, body: html`<p class="dlg-msg">${message}</p>`, footer: html`<button class="btn" data-close>Batal</button><button class="btn ${danger ? 'danger' : 'primary'}" data-ok>${confirmText}</button>`, onClose: () => { if (!done) res(false); } });
    on(m.el, 'click', '[data-ok]', () => { done = true; res(true); m.close(); });
  });
}

// field: {name,label,type,required,options:[[v,l]],value,placeholder,hint,min,max,step}
const fieldHtml = (f, v) => {
  const id = 'f_' + f.name, req = f.required ? 'required' : '', val_ = v ?? f.value ?? '';
  let ctl;
  if (f.type === 'hidden') return html`<input type="hidden" name="${f.name}" value="${val_}">`;
  if (f.type === 'textarea') ctl = html`<textarea class="input" id="${id}" name="${f.name}" rows="${f.rows || 3}" ${raw(req)} placeholder="${f.placeholder || ''}">${val_}</textarea>`;
  else if (f.type === 'select') ctl = html`<select class="input" id="${id}" name="${f.name}" ${raw(req)}>${(f.options || []).map(([ov, ol]) => html`<option value="${ov}" ${raw(String(ov) === String(val_) ? 'selected' : '')}>${ol}</option>`)}</select>`;
  else if (f.type === 'checkbox') return html`<label class="check"><input type="checkbox" name="${f.name}" ${raw(val_ ? 'checked' : '')}><span>${f.label}</span></label>`;
  else ctl = html`<input class="input" id="${id}" name="${f.name}" type="${f.type || 'text'}" value="${val_}" ${raw(req)} placeholder="${f.placeholder || ''}" ${raw(f.min != null ? `min="${esc(f.min)}"` : '')} ${raw(f.max != null ? `max="${esc(f.max)}"` : '')} ${raw(f.step ? `step="${esc(f.step)}"` : '')} ${raw(f.minlength ? `minlength="${esc(f.minlength)}"` : '')} autocomplete="${f.autocomplete || 'off'}">`;
  return html`<div class="field"><label for="${id}">${f.label}${f.required ? html`<i aria-hidden="true">*</i>` : ''}</label>${ctl}${f.hint ? html`<small>${f.hint}</small>` : ''}</div>`;
};
export const formFields = (fields, values = {}) => html`${fields.map((f) => fieldHtml(f, values[f.name]))}`;
export function readForm(form, fields) {
  const o = {};
  fields.forEach((f) => { const el = form.elements[f.name]; if (!el) return; o[f.name] = f.type === 'checkbox' ? el.checked : f.type === 'number' ? (el.value === '' ? null : Number(el.value)) : el.value.trim(); });
  return o;
}
// Bungkus tombol: nonaktif + spinner saat proses; error -> toast
export async function busy(btn, fn) {
  if (btn.disabled) return;
  btn.disabled = true; btn.classList.add('loading');
  try { return await fn(); } catch (e) { toast(e.message || 'Terjadi kesalahan', 'err'); } finally { if (btn.isConnected) { btn.disabled = false; btn.classList.remove('loading'); } }
}
export function formDialog({ title, desc = '', fields, values = {}, submitText = 'Simpan', danger = false, wide = false, extra = '', onReady, onSubmit }) {
  return new Promise((res) => {
    let result = null;
    const m = openModal({ title, wide, body: html`<form novalidate id="dlgform">${desc ? html`<p class="dlg-msg">${desc}</p>` : ''}<div class="formgrid">${formFields(fields, values)}</div>${extra}<p class="form-err" role="alert" hidden></p></form>`, footer: html`<button class="btn" data-close type="button">Batal</button><button class="btn ${danger ? 'danger' : 'primary'}" type="submit" form="dlgform">${submitText}</button>`, onClose: () => res(result) });
    const form = $('form', m.el), err = $('.form-err', m.el);
    onReady?.(m.el, form);
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      if (!form.checkValidity()) { form.reportValidity(); return; }
      err.hidden = true;
      busy($('button[type=submit]', m.el), async () => {
        try { result = await onSubmit(readForm(form, fields)); m.close(); } catch (x) { err.textContent = x.message || 'Gagal menyimpan'; err.hidden = false; }
      });
    });
  });
}
export async function loadInto(el, fn) {
  mount(el, skeleton(4, 72));
  try { await fn(); } catch (e) {
    mount(el, errorState(e.message || 'Terjadi kesalahan'));
    $('[data-retry]', el)?.addEventListener('click', () => loadInto(el, fn));
  }
}
