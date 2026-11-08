import { api, getToken, setToken } from './api.js';
import { $, $$, html, mount, icon, on, openModal, toast, avatar, errorState } from './ui.js';
import { state, routes, homeFor, go, leaveHooks, parseHash } from './router.js';
import './views/auth.js';
import './views/owner.js';
import './views/admin.js';
import './views/player.js';

const NAV = {
  owner: [['', 'Dashboard', 'dashboard'], ['courts', 'Lapangan', 'court'], ['schedule', 'Jadwal', 'calendar'], ['bookings', 'Booking', 'ticket'], ['checkin', 'Check-in', 'scan'], ['reviews', 'Ulasan', 'star'], ['settings', 'Pengaturan', 'settings']],
  admin: [['', 'Overview', 'dashboard'], ['users', 'Pengguna', 'users'], ['courts', 'Lapangan', 'court'], ['bookings', 'Booking', 'ticket'], ['vouchers', 'Voucher', 'tag'], ['coaches', 'Pelatih', 'coach'], ['moderation', 'Moderasi', 'flag'], ['settings', 'Pengaturan', 'settings']],
  me: [['', 'Beranda', 'home'], ['bookings', 'Booking saya', 'ticket'], ['notifications', 'Notifikasi', 'bell'], ['settings', 'Profil', 'settings']],
};
const TITLES = { owner: 'Panel Pemilik', admin: 'Panel Admin', me: 'Portal Pemain' };
const hrefOf = (sec, id) => `#/${sec}${id ? '/' + id : ''}`;

const themeNow = () => document.documentElement.dataset.theme || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
const paintThemeBtn = () => { const b = $('#themeBtn'); if (b) mount(b, themeNow() === 'dark' ? icon('sun') : icon('moon')); };
function toggleTheme() {
  const t = themeNow() === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem('ace_theme', t); } catch { /* abaikan */ }
  paintThemeBtn();
}

let shellSection = '', shellUser = '';
export function logout() { setToken(''); state.user = null; document.body.classList.remove('nav-open'); shellSection = ''; go('#/login'); }

function buildShell(sec) {
  const u = state.user, items = NAV[sec].map(([id, l, ic]) => ({ href: hrefOf(sec, id), l, ic, id }));
  const extra = [];
  if (sec === 'admin') extra.push({ href: '#/owner', l: 'Panel Pemilik', ic: 'court' });
  if (sec === 'owner' && u.role === 'admin') extra.push({ href: '#/admin', l: 'Panel Admin', ic: 'shield' });
  const bottom = items.slice(0, 4);
  mount($('#root'), html`<div class="shell">
    <aside class="sidebar" id="sidebar" aria-label="Navigasi utama">
      <a class="brand" href="/"><img src="/favicon.png" alt=""><span>ACE PADEL<small>${TITLES[sec]}</small></span></a>
      <nav class="nav" id="nav">${items.map((i) => html`<a href="${i.href}" data-id="${i.id}">${icon(i.ic)}<span>${i.l}</span></a>`)}
        ${extra.length ? html`<div class="nav-label">Panel lain</div>${extra.map((i) => html`<a href="${i.href}" data-x="1">${icon(i.ic)}<span>${i.l}</span></a>`)}` : ''}</nav>
      <div class="side-foot"><div class="me">${avatar(u)}<div><b>${u.name}</b><small>${u.role === 'admin' ? 'Administrator' : u.role === 'owner' ? 'Pemilik Lapangan' : 'Pemain'}</small></div></div>
        <a class="btn" href="/">${icon('home')}Situs Ace Padel</a><button class="btn" id="logoutBtn">${icon('logout')}Keluar</button></div>
    </aside>
    <div class="scrim" id="scrim"></div>
    <div class="main">
      <div class="topbar"><button class="btn icon ghost menu-btn" id="menuBtn" aria-label="Buka menu">${icon('menu')}</button>
        <button class="cmdk-trigger" id="cmdk" aria-label="Cari halaman">${icon('search')}<span>Cari halaman…</span><kbd>Ctrl K</kbd></button><div class="sp"></div>
        <button class="btn icon ghost" id="themeBtn" aria-label="Ganti tema"></button></div>
      <main class="view" id="view" tabindex="-1"></main>
    </div>
    <nav class="bottomnav" aria-label="Navigasi bawah">${bottom.map((i) => html`<a href="${i.href}" data-id="${i.id}">${icon(i.ic)}<span>${i.l}</span></a>`)}<button id="moreBtn" aria-label="Menu lainnya">${icon('more')}<span>Lainnya</span></button></nav>
  </div>`);
  paintThemeBtn();
  const closeNav = () => document.body.classList.remove('nav-open');
  $('#menuBtn').onclick = () => document.body.classList.add('nav-open');
  $('#moreBtn').onclick = () => document.body.classList.add('nav-open');
  $('#scrim').onclick = closeNav; $('#themeBtn').onclick = toggleTheme; $('#logoutBtn').onclick = logout;
  $('#nav').addEventListener('click', (e) => { if (e.target.closest('a')) closeNav(); });
  $('#cmdk').onclick = () => palette(items.concat(extra));
}

function palette(items) {
  const cmds = [...items.map((i) => ({ l: i.l, ic: i.ic, run: () => go(i.href) })), { l: 'Ganti tema terang/gelap', ic: 'moon', run: toggleTheme }, { l: 'Keluar', ic: 'logout', run: logout }];
  const m = openModal({ title: 'Cari halaman', body: html`<input class="input" id="cq" placeholder="Ketik nama halaman atau aksi…" aria-label="Cari" autocomplete="off"><div class="cmd-list" id="cl"></div>` });
  const draw = () => {
    const q = $('#cq', m.el).value.toLowerCase(), f = cmds.filter((c) => c.l.toLowerCase().includes(q));
    mount($('#cl', m.el), f.length ? html`${f.map((c, i) => html`<button data-i="${cmds.indexOf(c)}" class="${i === 0 ? 'on' : ''}">${icon(c.ic)}<span>${c.l}</span></button>`)}` : html`<p class="muted" style="padding:12px">Tidak ada hasil.</p>`);
  };
  draw();
  $('#cq', m.el).addEventListener('input', draw);
  const pick = (i) => { m.close(); cmds[i].run(); };
  on(m.el, 'click', '#cl button', (e, b) => pick(+b.dataset.i));
  m.el.addEventListener('keydown', (e) => {
    const bs = $$('#cl button', m.el), cur = bs.findIndex((b) => b.classList.contains('on'));
    if (e.key === 'Enter' && bs.length) { e.preventDefault(); pick(+bs[Math.max(cur, 0)].dataset.i); }
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') { e.preventDefault(); bs.forEach((b) => b.classList.remove('on')); const n = bs[(cur + (e.key === 'ArrowDown' ? 1 : -1) + bs.length) % bs.length]; n?.classList.add('on'); n?.scrollIntoView({ block: 'nearest' }); }
  });
}
document.addEventListener('keydown', (e) => { if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k' && $('#cmdk')) { e.preventDefault(); $('#cmdk').click(); } });

let token = 0;
async function render() {
  const my = ++token;
  leaveHooks.splice(0).forEach((f) => { try { f(); } catch { /* abaikan */ } });
  const { path, query } = parseHash();
  if (!path) return go(homeFor(state.user));
  const hit = routes.map((r) => ({ r, m: r.re.exec(path) })).find((x) => x.m);
  if (!hit) { toast('Halaman tidak ditemukan', 'err'); return go(homeFor(state.user)); }
  const { r, m } = hit, params = Object.fromEntries(r.keys.map((k, i) => [k, decodeURIComponent(m[i + 1])]));
  if (r.roles) {
    if (!state.user) return go('#/login');
    if (!r.roles.includes(state.user.role)) { toast('Anda tidak memiliki akses ke halaman itu', 'err'); return go(homeFor(state.user)); }
  } else if (state.user && r.bare) return go(homeFor(state.user));
  const ctx = { params, query, user: state.user, path, alive: () => my === token };
  if (r.bare) { shellSection = ''; document.body.classList.remove('nav-open'); document.title = r.title + ' — Ace Padel'; const root = $('#root'); root.innerHTML = ''; return r.fn({ ...ctx, el: root }); }
  const sec = path.split('/')[0];
  if (shellSection !== sec || shellUser !== state.user.id) { buildShell(sec); shellSection = sec; shellUser = state.user.id; }
  $$('#nav a, .bottomnav a').forEach((a) => {
    const h = a.getAttribute('href').slice(1), cur = '/' + path;
    h === cur || (a.dataset.id && cur.startsWith(h + '/')) ? a.setAttribute('aria-current', 'page') : a.removeAttribute('aria-current');
  });
  const view = $('#view'), el = document.createElement('div');
  view.replaceChildren(el); window.scrollTo(0, 0);
  document.title = (r.title || TITLES[sec]) + ' — Ace Padel';
  try { await r.fn({ ...ctx, el }); } catch (e) { mount(el, errorState(e.message)); $('[data-retry]', el)?.addEventListener('click', render); }
}

async function boot() {
  if (getToken()) { try { state.user = (await api('/auth/me')).data; } catch { setToken(''); } }
  window.addEventListener('hashchange', render);
  render();
}
boot();
