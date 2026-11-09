/* Layout bersama Ace Padel: header, drawer, footer, tema, progress, reveal, helper data.
   Diimpor oleh setiap halaman (type=module) dan oleh modul per-halaman. */
export const $ = (s, r = document) => r.querySelector(s);
export const $$ = (s, r = document) => [...r.querySelectorAll(s)];
export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const idr = new Intl.NumberFormat('id-ID');
export const fmt = (n) => idr.format(n);
/** Harga API dalam ribuan Rupiah: 220 -> "Rp220.000" */
export const rp = (k) => 'Rp' + idr.format(Math.round(Number(k) * 1000));
export const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
export const ic = (id, cls = '') => `<svg class="ic ${cls}" aria-hidden="true"><use href="#i-${id}"/></svg>`;
export const stars = (r) => `<span class="stars" aria-hidden="true">${'★'.repeat(Math.round(r))}${'☆'.repeat(5 - Math.round(r))}</span>`;

export async function api(path, ms = 7000) {
  const c = new AbortController(); const t = setTimeout(() => c.abort(), ms);
  try {
    const r = await fetch('/api' + path, { signal: c.signal });
    if (!r.ok) throw new Error(r.status);
    const j = await r.json();
    return j.data ?? j;
  } finally { clearTimeout(t); }
}

/* ---------- Sprite ikon ---------- */
const SPRITE = `<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
<symbol id="i-cal" viewBox="0 0 24 24"><path d="M8 2v4M16 2v4M3 10h18M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"/></symbol>
<symbol id="i-qr" viewBox="0 0 24 24"><path d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM20 14v3M14 20h3M20 20h1"/></symbol>
<symbol id="i-card" viewBox="0 0 24 24"><path d="M3 6h18v12H3zM3 10h18M7 15h3"/></symbol>
<symbol id="i-users" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/></symbol>
<symbol id="i-whistle" viewBox="0 0 24 24"><circle cx="9" cy="15" r="6"/><path d="M13 11l8-5-2 7M9 12v3"/></symbol>
<symbol id="i-trophy" viewBox="0 0 24 24"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0zM17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3"/></symbol>
<symbol id="i-tag" viewBox="0 0 24 24"><path d="M20 12l-8 8-9-9V3h8zM7.5 7.5h.01"/></symbol>
<symbol id="i-chart" viewBox="0 0 24 24"><path d="M3 3v18h18M7 15l4-4 3 3 5-6"/></symbol>
<symbol id="i-lock" viewBox="0 0 24 24"><path d="M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4"/></symbol>
<symbol id="i-star" viewBox="0 0 24 24"><path d="M12 2l3 7 7 .6-5.3 4.7 1.6 7.2L12 17.8 5.7 21.5l1.6-7.2L2 9.6 9 9z"/></symbol>
<symbol id="i-pin" viewBox="0 0 24 24"><path d="M12 22s7-6.2 7-12a7 7 0 0 0-14 0c0 5.8 7 12 7 12zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z"/></symbol>
<symbol id="i-arrow" viewBox="0 0 24 24"><path d="M5 12h14M13 6l6 6-6 6"/></symbol>
<symbol id="i-sun" viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></symbol>
<symbol id="i-moon" viewBox="0 0 24 24"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></symbol>
<symbol id="i-menu" viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16"/></symbol>
<symbol id="i-x" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></symbol>
<symbol id="i-check" viewBox="0 0 24 24"><path d="M5 12l5 5 9-10"/></symbol>
<symbol id="i-bell" viewBox="0 0 24 24"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21a2 2 0 0 0 4 0"/></symbol>
<symbol id="i-chev" viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></symbol>
<symbol id="i-sun2" viewBox="0 0 24 24"><path d="M3 12h18M12 3v18"/></symbol>
<symbol id="i-bolt" viewBox="0 0 24 24"><path d="M13 2L4 14h7l-1 8 9-12h-7z"/></symbol>
<symbol id="i-copy" viewBox="0 0 24 24"><path d="M9 9h11v11H9zM5 15H4V4h11v1"/></symbol>
<symbol id="i-shield" viewBox="0 0 24 24"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></symbol>
<symbol id="i-mail" viewBox="0 0 24 24"><path d="M3 5h18v14H3zM3 7l9 7 9-7"/></symbol>
</svg>`;

/* SVG garis lapangan padel (20 x 10 m): garis tepi, jaring, garis servis, garis tengah */
export const COURT_SVG = `<svg class="hero__court" viewBox="0 0 200 100" preserveAspectRatio="xMidYMid slice" aria-hidden="true" focusable="false"><rect x="8" y="6" width="184" height="88"/><line x1="100" y1="6" x2="100" y2="94"/><line x1="30" y1="6" x2="30" y2="94"/><line x1="170" y1="6" x2="170" y2="94"/><line x1="30" y1="50" x2="170" y2="50"/></svg>`;

const NAV = [
  { t: 'Fitur', h: '/fitur', mega: [
    ['cal', 'Booking real-time', 'Slot langsung, anti bentrok', '/fitur#booking'],
    ['card', 'Pembayaran DOKU', 'QRIS, VA, e-wallet', '/fitur#pembayaran'],
    ['qr', 'E-ticket QR', 'Check-in sekali scan', '/fitur#eticket'],
    ['users', 'Mabar', 'Cari lawan sesuai level', '/fitur#mabar'],
    ['whistle', 'Coaching', 'Pelatih bersertifikat', '/fitur#coaching'],
    ['trophy', 'Leaderboard', 'Poin dan pencapaian', '/fitur#leaderboard'],
  ] },
  { t: 'Venue', h: '/venue', also: ['/venue-detail'] },
  { t: 'Pelatih', h: '/pelatih' },
  { t: 'Komunitas', h: '/komunitas', drop: [
    ['users', 'Mabar terbuka', 'Gabung match yang butuh pemain', '/komunitas#mabar'],
    ['trophy', 'Leaderboard', 'Peringkat pemain', '/komunitas#leaderboard'],
    ['star', 'Achievement', 'Cara mengumpulkan poin', '/komunitas#achievement'],
  ] },
  { t: 'Pemilik', h: '/pemilik' },
  { t: 'Promo', h: '/promo' },
  { t: 'Bantuan', h: '/bantuan', also: ['/syarat', '/privacy'], drop: [
    ['shield', 'FAQ', 'Pertanyaan yang sering muncul', '/bantuan#faq'],
    ['mail', 'Hubungi kami', 'Kirim pesan lewat email', '/bantuan#kontak'],
    ['lock', 'Syarat & Ketentuan', 'Aturan pemakaian', '/syarat'],
    ['lock', 'Kebijakan Privasi', 'Data kamu dan hak kamu', '/privacy'],
  ] },
];
const path = location.pathname.replace(/\/+$/, '').replace(/\.html$/, '') || '/';
const isCur = (n) => path === n.h || (n.also || []).includes(path);

const sub = (items) => items.map(([i, t, d, h]) => `<a href="${h}" role="menuitem">${ic(i)}<span><b>${esc(t)}</b><small>${esc(d)}</small></span></a>`).join('');

function headerHTML() {
  const items = NAV.map((n, i) => {
    const sub_ = n.mega || n.drop;
    if (!sub_) return `<a href="${n.h}"${isCur(n) ? ' aria-current="page"' : ''}>${n.t}</a>`;
    return `<div class="nav__item"><button class="nav__btn${isCur(n) ? ' is-current' : ''}" type="button" aria-expanded="false" aria-controls="dd${i}" aria-haspopup="true">${n.t}${ic('chev')}</button>
      <div class="drop${n.mega ? ' drop--mega' : ''}" id="dd${i}" role="menu">${sub(sub_)}</div></div>`;
  }).join('');
  return `<div class="wrap hdr__in">
    <a class="brand" href="/" aria-label="Ace Padel, ke beranda"><img src="/img/logo.png" alt="" width="36" height="36"><span>ACE PADEL</span></a>
    <nav class="nav" aria-label="Navigasi utama">${items}</nav>
    <div class="hdr__act">
      <button class="icon-btn" id="theme" type="button" aria-label="Ganti tema terang atau gelap">${ic('moon', 'ic-moon')}${ic('sun', 'ic-sun')}</button>
      <a class="hdr__login" href="/app/#/login">Masuk</a>
      <a class="btn btn--sm hdr__cta" href="/app/#/register">Mulai Main</a>
      <button class="icon-btn burger" id="burger" type="button" aria-label="Buka menu" aria-expanded="false" aria-controls="drawer">${ic('menu')}</button>
    </div></div><div class="hdr__prog" id="prog"></div>`;
}

function drawerHTML() {
  const links = NAV.map((n, i) => `<a href="${n.h}"${isCur(n) ? ' aria-current="page"' : ''}><small>${String(i + 1).padStart(2, '0')}</small>${n.t}</a>`).join('');
  return `<div class="wrap drawer__top"><a class="brand" href="/"><img src="/img/logo.png" alt="" width="36" height="36"><span>ACE PADEL</span></a>
    <button class="icon-btn" id="drawer-x" type="button" aria-label="Tutup menu">${ic('x')}</button></div>
    <nav class="wrap drawer__links" aria-label="Menu seluruh situs">${links}</nav>
    <div class="wrap drawer__foot"><a class="btn btn--lg" href="/app/#/register">Mulai Main</a><a class="btn btn--ghost btn--lg" style="--c:#fff" href="/app/#/login">Masuk</a></div>`;
}

function footerHTML() {
  return `<div class="wrap">
    <div class="foot__grid">
      <div class="foot__brand"><a class="brand" href="/"><img src="/img/logo.png" alt="" width="36" height="36"><span>ACE PADEL</span></a>
        <p>Booking lapangan padel yang cepat dan transparan, dari cari venue sampai check-in.</p>
        <div class="badges" aria-label="Aplikasi seluler"><span class="badge"><small>Segera hadir di</small><b>Google Play</b></span><span class="badge"><small>Segera hadir di</small><b>App Store</b></span></div></div>
      <nav aria-label="Produk"><h3>Main</h3><a href="/fitur">Fitur</a><a href="/venue">Cari venue</a><a href="/pelatih">Pelatih</a><a href="/komunitas">Mabar &amp; leaderboard</a><a href="/promo">Promo &amp; harga</a></nav>
      <nav aria-label="Pemilik"><h3>Pemilik</h3><a href="/pemilik">Untuk pemilik lapangan</a><a href="/app/#/register?role=owner">Daftarkan venue</a><a href="/app/#/login">Masuk dashboard</a></nav>
      <nav aria-label="Perusahaan"><h3>Ace Padel</h3><a href="/tentang">Tentang</a><a href="/bantuan">Bantuan</a><a href="/syarat">Syarat &amp; Ketentuan</a><a href="/privacy">Kebijakan Privasi</a></nav>
      <nav aria-label="Sosial"><h3>Ikuti</h3><span>Instagram (segera)</span><span>TikTok (segera)</span><span>YouTube (segera)</span></nav>
    </div>
    <div class="foot__bar"><span>&copy; ${new Date().getFullYear()} Ace Padel by hellens.dev</span><span>Pembayaran online diproses oleh DOKU. Ace Padel tidak menyimpan data kartu atau kredensial pembayaran.</span></div>
  </div><div class="foot__big" aria-hidden="true">Ace Padel</div>`;
}

function mount() {
  document.body.insertAdjacentHTML('afterbegin', SPRITE);
  const root = document.documentElement;

  const hdr = $('#site-header');
  if (hdr) hdr.innerHTML = headerHTML();
  const main = $('#main');
  const drawer = document.createElement('div');
  drawer.className = 'drawer'; drawer.id = 'drawer'; drawer.setAttribute('role', 'dialog'); drawer.setAttribute('aria-modal', 'true'); drawer.setAttribute('aria-label', 'Menu');
  drawer.innerHTML = drawerHTML();
  document.body.append(drawer);
  const ft = $('#site-footer');
  if (ft) ft.innerHTML = footerHTML();
  const top = document.createElement('button');
  top.className = 'totop'; top.type = 'button'; top.setAttribute('aria-label', 'Kembali ke atas'); top.innerHTML = ic('arrow');
  document.body.append(top);
  top.addEventListener('click', () => scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' }));

  /* Tema */
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  $('#theme')?.addEventListener('click', () => {
    const t = isDark() ? 'light' : 'dark';
    root.dataset.theme = t;
    try { localStorage.setItem('ace-theme', t); } catch (e) { /* abaikan */ }
  });
  if (isDark()) root.classList.add('is-dark');
  new MutationObserver(() => root.classList.toggle('is-dark', isDark())).observe(root, { attributes: true, attributeFilter: ['data-theme'] });

  /* Dropdown desktop */
  const btns = $$('.nav__btn');
  const closeAll = (except) => btns.forEach((b) => { if (b !== except) { b.setAttribute('aria-expanded', 'false'); $('#' + b.getAttribute('aria-controls')).classList.remove('is-open'); } });
  const toggle = (b, open) => { closeAll(b); b.setAttribute('aria-expanded', open); $('#' + b.getAttribute('aria-controls')).classList.toggle('is-open', open); };
  btns.forEach((b) => {
    const item = b.parentElement; let t;
    b.addEventListener('click', () => toggle(b, b.getAttribute('aria-expanded') !== 'true'));
    item.addEventListener('mouseenter', () => { clearTimeout(t); toggle(b, true); });
    item.addEventListener('mouseleave', () => { t = setTimeout(() => toggle(b, false), 160); });
    item.addEventListener('focusout', (e) => { if (!item.contains(e.relatedTarget)) toggle(b, false); });
    item.addEventListener('keydown', (e) => { if (e.key === 'Escape') { toggle(b, false); b.focus(); } });
  });
  document.addEventListener('click', (e) => { if (!e.target.closest('.nav__item')) closeAll(); });

  /* Drawer mobile: fokus terkunci, Escape menutup, konten utama inert */
  const burger = $('#burger'); let lastFocus;
  const focusables = () => $$('a[href],button', drawer).filter((e) => !e.disabled);
  const setDrawer = (open) => {
    drawer.classList.toggle('is-open', open);
    burger?.setAttribute('aria-expanded', open); burger?.setAttribute('aria-label', open ? 'Tutup menu' : 'Buka menu');
    document.body.style.overflow = open ? 'hidden' : '';
    [main, ft, hdr].forEach((el) => { if (el) el.inert = open; });
    if (open) { lastFocus = document.activeElement; $('#drawer-x').focus(); } else lastFocus?.focus?.();
  };
  burger?.addEventListener('click', () => setDrawer(true));
  $('#drawer-x').addEventListener('click', () => setDrawer(false));
  drawer.addEventListener('click', (e) => { if (e.target.closest('a')) { drawer.classList.remove('is-open'); document.body.style.overflow = ''; [main, ft, hdr].forEach((el) => { if (el) el.inert = false; }); } });
  drawer.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') return setDrawer(false);
    if (e.key !== 'Tab') return;
    const f = focusables(), a = f[0], z = f[f.length - 1];
    if (e.shiftKey && document.activeElement === a) { e.preventDefault(); z.focus(); } else if (!e.shiftKey && document.activeElement === z) { e.preventDefault(); a.focus(); }
  });
  matchMedia('(min-width:1040px)').addEventListener('change', (e) => { if (e.matches && drawer.classList.contains('is-open')) setDrawer(false); });

  /* Progress scroll, back-to-top, parallax */
  const prog = $('#prog'); const par = $$('[data-par]');
  let tick = false;
  const onScroll = () => {
    if (tick) return; tick = true;
    requestAnimationFrame(() => {
      const y = scrollY, h = document.documentElement.scrollHeight - innerHeight;
      if (prog) prog.style.transform = `scaleX(${h > 0 ? Math.min(1, y / h) : 0})`;
      top.classList.toggle('is-on', y > 700);
      if (!reduce) par.forEach((el) => { el.style.transform = `translate3d(0, ${(y * (+el.dataset.par || .1)).toFixed(1)}px, 0)`; });
      tick = false;
    });
  };
  addEventListener('scroll', onScroll, { passive: true }); onScroll();
}

/* ---------- Reveal & count-up ---------- */
const rio = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); rio.unobserve(e.target); } }), { threshold: 0.12 });
export const watch = (root = document) => $$('.rv:not(.in)', root).forEach((el) => rio.observe(el));

const cio = new IntersectionObserver((es) => es.forEach((e) => {
  if (!e.isIntersecting) return; cio.unobserve(e.target);
  const el = e.target, to = +el.dataset.to || 0;
  if (reduce || !to) { el.textContent = fmt(to); return; }
  const t0 = performance.now();
  const step = (t) => { const p = Math.min(1, (t - t0) / 1300); el.textContent = fmt(Math.round(to * (1 - Math.pow(1 - p, 3)))); if (p < 1) requestAnimationFrame(step); };
  requestAnimationFrame(step);
}), { threshold: 0.4 });
export const countUp = (el, to) => { el.dataset.to = to; cio.unobserve(el); cio.observe(el); };

/* Ticker: duplikasi isi supaya loop mulus */
export function ticker(el, names) {
  const h = names.map((n) => `<span>${esc(n)}</span>`).join('');
  el.innerHTML = `<div class="ticker__track" aria-hidden="true">${h}${h}</div><span class="vh">Venue mitra: ${esc(names.join(', '))}</span>`;
}

/* Kartu venue */
export const courtCard = (c, i = 0) => `<a class="vcard rv" style="--d:${Math.min(i, 8) * 50}ms" href="/venue-detail?id=${encodeURIComponent(c.id)}" aria-label="${esc(c.venue)}, ${esc(c.name)}, ${rp(c.pricePerHour)} per jam">
  <div class="vcard__img"><img src="${esc(c.imageUrl)}" alt="Lapangan ${esc(c.name)} di ${esc(c.venue)}" width="520" height="397" loading="lazy" decoding="async">
  <span class="vcard__tag">${c.indoor ? 'Indoor' : 'Outdoor'}</span><span class="vcard__rate">${ic('star')}${Number(c.rating).toFixed(1)}</span></div>
  <div class="vcard__b"><h3>${esc(c.venue)}</h3><small>${ic('pin')}${esc(c.area || c.city)}</small><span class="vcard__p">${rp(c.pricePerHour)} <small>/ jam</small></span></div></a>`;

export const skeletons = (n, cls = 'vcard') => Array.from({ length: n }, () => `<div class="skel ${cls}" aria-hidden="true"></div>`).join('');

/* Salin ke clipboard dengan fallback */
export async function copyText(txt) {
  try { await navigator.clipboard.writeText(txt); return true; } catch (e) {
    const ta = document.createElement('textarea'); ta.value = txt; ta.style.position = 'fixed'; ta.style.opacity = '0'; document.body.append(ta); ta.select();
    let ok = false; try { ok = document.execCommand('copy'); } catch (err) { /* abaikan */ } ta.remove(); return ok;
  }
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => { mount(); watch(); }); else { mount(); watch(); }
