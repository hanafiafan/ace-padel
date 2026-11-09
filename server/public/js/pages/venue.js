import { $, $$, api, esc, rp, ic, courtCard, watch } from '/js/site.js';

const f = { q: $('#q'), city: $('#city'), sort: $('#sort'), pmax: $('#pmax') };
const chips = $$('.chip[data-t]');
let all = [], maxPrice = 0;
const P = new URLSearchParams(location.search);
let type = P.get('type') === 'indoor' ? 'true' : P.get('type') === 'outdoor' ? 'false' : '';

const setChips = () => chips.forEach((c) => c.setAttribute('aria-pressed', String(c.dataset.t === type)));
setChips();
f.q.value = P.get('q') || '';
if (['rating', 'price_asc', 'price_desc'].includes(P.get('sort'))) f.sort.value = P.get('sort');

const norm = (s) => String(s || '').toLowerCase();

function sync() {
  const u = new URLSearchParams();
  if (f.q.value.trim()) u.set('q', f.q.value.trim());
  if (f.city.value) u.set('city', f.city.value);
  if (type) u.set('type', type === 'true' ? 'indoor' : 'outdoor');
  if (f.sort.value !== 'rating') u.set('sort', f.sort.value);
  if (+f.pmax.value < maxPrice) u.set('max', f.pmax.value);
  history.replaceState(null, '', location.pathname + (u.toString() ? '?' + u : ''));
  return u.toString() !== '';
}

function render() {
  const q = norm(f.q.value.trim()), pm = +f.pmax.value;
  $('#pout').textContent = pm >= maxPrice ? 'semua' : rp(pm);
  let r = all.filter((c) => (!q || norm(`${c.venue} ${c.name} ${c.area} ${c.city}`).includes(q))
    && (!f.city.value || c.city === f.city.value)
    && (!type || String(c.indoor) === type)
    && c.pricePerHour <= pm);
  const s = f.sort.value;
  r = r.sort((a, b) => s === 'price_asc' ? a.pricePerHour - b.pricePerHour : s === 'price_desc' ? b.pricePerHour - a.pricePerHour : b.rating - a.rating);
  const filtered = sync();
  $('#reset').hidden = !filtered;
  $('#count').textContent = `${r.length} venue ditemukan`;
  const list = $('#list'); list.setAttribute('aria-busy', 'false');
  list.innerHTML = r.length ? r.map((c, i) => courtCard(c, i)).join('') : `<div class="empty">${ic('pin')}<h3>Tidak ada venue yang cocok</h3><p class="muted">Coba kata kunci lain, pilih semua kota, atau naikkan batas harga.</p><button class="btn btn--blue" type="button" id="empty-reset">Reset filter</button></div>`;
  watch(list);
  $('#empty-reset')?.addEventListener('click', reset);
}

function reset() { f.q.value = ''; f.city.value = ''; f.sort.value = 'rating'; f.pmax.value = maxPrice; type = ''; setChips(); render(); }

api('/courts?sortBy=rating').then((cs) => {
  all = cs;
  maxPrice = Math.max(...cs.map((c) => c.pricePerHour), 0);
  const minPrice = Math.min(...cs.map((c) => c.pricePerHour), 0);
  f.pmax.min = Math.max(0, Math.floor(minPrice / 10) * 10); f.pmax.max = Math.ceil(maxPrice / 10) * 10; maxPrice = +f.pmax.max;
  f.pmax.value = Math.min(maxPrice, +P.get('max') || maxPrice);
  [...new Set(cs.map((c) => c.city))].sort().forEach((c) => f.city.insertAdjacentHTML('beforeend', `<option value="${esc(c)}">${esc(c)}</option>`));
  if ([...f.city.options].some((o) => o.value === P.get('city'))) f.city.value = P.get('city');
  render();
}).catch(() => {
  $('#count').textContent = 'Venue belum bisa dimuat';
  $('#list').setAttribute('aria-busy', 'false');
  $('#list').innerHTML = `<div class="empty">${ic('pin')}<h3>Gagal memuat venue</h3><p class="muted">Koneksi ke server bermasalah. Periksa jaringan lalu coba lagi.</p><button class="btn btn--blue" type="button" onclick="location.reload()">Muat ulang</button></div>`;
});

let t;
f.q.addEventListener('input', () => { clearTimeout(t); t = setTimeout(render, 120); });
[f.city, f.sort, f.pmax].forEach((el) => el.addEventListener('input', render));
chips.forEach((c) => c.addEventListener('click', () => { type = c.dataset.t; setChips(); render(); }));
$('#reset').addEventListener('click', reset);
$('#filters').addEventListener('submit', (e) => e.preventDefault());
