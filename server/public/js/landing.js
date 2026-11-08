const $ = (s, r = document) => r.querySelector(s);
const root = document.documentElement;
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const rb = (n) => `Rp${n}rb/jam`;

/* Tema */
const dark = () => root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
$('#theme').addEventListener('click', () => {
  const t = dark() ? 'light' : 'dark';
  root.dataset.theme = t;
  try { localStorage.setItem('ace-theme', t); } catch (e) {}
});

/* Menu mobile */
const nav = $('#nav'), burger = $('#burger');
burger.addEventListener('click', () => {
  const o = nav.classList.toggle('open');
  burger.setAttribute('aria-expanded', o);
  burger.setAttribute('aria-label', o ? 'Tutup menu' : 'Buka menu');
});
$('#menu').addEventListener('click', (e) => { if (e.target.tagName === 'A') { nav.classList.remove('open'); burger.setAttribute('aria-expanded', false); } });
$('#yr').textContent = new Date().getFullYear();

/* Scroll reveal */
const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: 0.12 });
const watch = () => document.querySelectorAll('.reveal:not(.in)').forEach((el) => io.observe(el));
watch();

/* Spotlight bento */
document.querySelectorAll('.spot').forEach((el) => el.addEventListener('pointermove', (e) => {
  const r = el.getBoundingClientRect();
  el.style.setProperty('--mx', e.clientX - r.left + 'px'); el.style.setProperty('--my', e.clientY - r.top + 'px');
}));

/* Counter */
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
const fmt = new Intl.NumberFormat('id-ID');
const cio = new IntersectionObserver((es) => es.forEach((e) => {
  if (!e.isIntersecting) return;
  cio.unobserve(e.target);
  const el = e.target, to = +el.dataset.to;
  if (reduce || !to) { el.textContent = fmt.format(to); return; }
  const t0 = performance.now();
  const tick = (t) => { const p = Math.min(1, (t - t0) / 1400); el.textContent = fmt.format(Math.round(to * (1 - Math.pow(1 - p, 3)))); if (p < 1) requestAnimationFrame(tick); };
  requestAnimationFrame(tick);
}), { threshold: 0.5 });
document.querySelectorAll('.count').forEach((c) => cio.observe(c));

/* API */
const api = async (p) => {
  const c = new AbortController(); const t = setTimeout(() => c.abort(), 6000);
  try { const r = await fetch('/api' + p, { signal: c.signal }); if (!r.ok) throw 0; const j = await r.json(); return j.data; }
  finally { clearTimeout(t); }
};

const FALLBACK_VENUES = ['Padel Pro Kemang', 'Social Padel Menteng', 'Verde Sports Hub PIK 2', 'Space Padel PIK 2', 'Jungle Padel Canggu', 'Rekket BSD', 'Nine Monas', 'Tao Ubud'];
const marquee = (names) => {
  const h = names.map((n) => `<span>${esc(n)}</span>`).join('');
  $('#marquee').innerHTML = h + h; // digandakan untuk loop mulus
};
marquee(FALLBACK_VENUES);

api('/public/stats').then((s) => {
  document.querySelectorAll('.stat').forEach((el) => {
    const v = +s[el.dataset.k] || 0;
    if (!v) { el.hidden = true; return; } // jangan tampilkan angka 0
    const c = $('.count', el); c.dataset.to = v; cio.unobserve(c); cio.observe(c);
  });
}).catch(() => {
  const d = { venues: 16, courts: 16, players: 12, cities: 5 };
  document.querySelectorAll('.stat').forEach((el) => { const v = d[el.dataset.k]; if (!v) { el.hidden = true; return; } const c = $('.count', el); c.dataset.to = v; cio.unobserve(c); cio.observe(c); });
});

api('/courts?sortBy=rating').then((courts) => {
  if (!courts.length) throw 0;
  marquee([...new Set(courts.map((c) => c.venue))]);
  $('#courts').innerHTML = courts.slice(0, 10).map((c) => `
    <a class="card" href="/app/#/login" aria-label="${esc(c.venue)}, ${esc(c.name)}">
      <div class="card__img"><img src="${esc(c.imageUrl)}" alt="Lapangan ${esc(c.name)} di ${esc(c.venue)}" width="600" height="450" loading="lazy" decoding="async">
        <span class="card__tag">${c.indoor ? 'Indoor' : 'Outdoor'}</span>
        <span class="card__rate"><svg class="ic"><use href="#i-star"/></svg>${Number(c.rating).toFixed(1)}</span></div>
      <div class="card__b"><h3>${esc(c.venue)}</h3><small><svg class="ic"><use href="#i-pin"/></svg>${esc(c.area || c.city)}</small><span class="card__p">${rb(c.pricePerHour)}</span></div>
    </a>`).join('');
}).catch(() => { $('#courts').innerHTML = '<p class="wrap lead">Daftar lapangan sedang dimuat ulang. <a class="link" href="/app/#/login">Buka aplikasi</a> untuk melihat semua venue.</p>'; });

api('/coaches').then((cs) => {
  if (!cs.length) throw 0;
  $('#coachList').innerHTML = cs.slice(0, 4).map((c) => `
    <article class="coach reveal"><img src="${esc(c.imageUrl)}" alt="Pelatih ${esc(c.name)}" width="88" height="88" loading="lazy">
      <div><h3>${esc(c.name)}</h3><small>${esc(c.title)}</small>
      <div class="coach__m"><span><svg class="ic"><use href="#i-star"/></svg> ${Number(c.rating).toFixed(2)}</span><b>${rb(c.ratePerHour)}</b></div></div></article>`).join('');
  watch();
}).catch(() => { $('#coachList').innerHTML = '<p class="lead">Pelatih bersertifikat tersedia di aplikasi.</p>'; });

api('/leaderboard').then((l) => {
  if (!l.length) throw 0;
  $('#lb').innerHTML = l.slice(0, 3).map((p) => `
    <li><span class="lb__r">${p.rank}</span><div><b>${esc(p.name)}</b><small>@${esc(p.username)} &middot; ${p.wins} menang / ${p.matches} match</small></div>
    <div class="lb__pt">${fmt.format(p.points)}<small>poin</small></div></li>`).join('');
}).catch(() => { $('#lb').innerHTML = '<li><span class="lb__r">1</span><div><b>Peringkat tampil di aplikasi</b><small>Main untuk mengumpulkan poin</small></div><span></span></li>'; });

api('/vouchers').then((v) => {
  v = v.filter((x) => x.active !== false);
  if (!v.length) throw 0;
  $('#vouchers').innerHTML = v.slice(0, 3).map((x) => `
    <div class="vch"><code>${esc(x.code)}</code><b>${esc(x.title)}</b><span>${esc(x.description || '')}</span></div>`).join('');
}).catch(() => { $('#vouchers').innerHTML = '<div class="vch"><b>Promo tersedia di aplikasi</b><span>Masuk untuk melihat voucher aktif.</span></div>'; });
