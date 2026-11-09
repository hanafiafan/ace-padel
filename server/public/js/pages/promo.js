import { $, api, esc, rp, ic, copyText, watch } from '/js/site.js';

const off = (v) => v.percentage ? `${Math.round(v.percentage * 100)}%` : rp(v.discountAmount);
const detail = (v) => [
  v.percentage && v.maxDiscount ? `Maks. ${rp(v.maxDiscount)}` : '',
  v.minSpend ? `Min. belanja ${rp(v.minSpend)}` : 'Tanpa minimal belanja',
  v.expiresAt ? `Berlaku s.d. ${new Date(v.expiresAt).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}` : 'Tanpa batas waktu',
].filter(Boolean).join(' · ');

api('/vouchers').then((vs) => {
  vs = vs.filter((v) => v.active !== false);
  const box = $('#vouchers'); box.setAttribute('aria-busy', 'false');
  if (!vs.length) { box.innerHTML = `<div class="empty">${ic('tag')}<h3>Belum ada voucher aktif</h3><p class="muted">Cek lagi nanti, promo baru muncul di sini.</p></div>`; return; }
  box.innerHTML = vs.map((v, i) => `<div class="ticket rv${i % 2 ? ' ticket--alt' : ''}" style="--d:${i * 70}ms">
    <div class="ticket__l"><h3>${esc(v.title)}</h3><p>${esc(v.description || '')}</p><p><strong>${esc(detail(v))}</strong></p></div>
    <div class="ticket__r"><span class="ticket__off">Hemat<br>${esc(off(v))}</span><span class="ticket__code">${esc(v.code)}</span><button class="btn btn--sm copy" type="button" data-c="${esc(v.code)}">Salin kode</button></div></div>`).join('');
  watch(box);
}).catch(() => { $('#vouchers').setAttribute('aria-busy', 'false'); $('#vouchers').innerHTML = `<div class="empty"><h3>Voucher belum bisa dimuat</h3><p class="muted">Coba muat ulang halaman ini.</p></div>`; });

$('#vouchers').addEventListener('click', async (e) => {
  const b = e.target.closest('.copy'); if (!b) return;
  const ok = await copyText(b.dataset.c);
  b.textContent = ok ? 'Tersalin' : 'Salin manual'; setTimeout(() => { b.textContent = 'Salin kode'; }, 1800);
});

api('/addons').then((as) => {
  const box = $('#addons'); box.setAttribute('aria-busy', 'false');
  if (!as.length) { box.innerHTML = '<div class="empty"><h3>Belum ada add-on</h3></div>'; return; }
  box.innerHTML = as.map((a, i) => `<div class="value rv" style="--d:${i * 60}ms"><h3>${esc(a.name)}</h3><span class="price-big" style="font-size:2.6rem">${rp(a.price)}</span></div>`).join('');
  watch(box);
}).catch(() => { $('#addons').setAttribute('aria-busy', 'false'); $('#addons').innerHTML = '<div class="empty"><h3>Add-on belum bisa dimuat</h3></div>'; });
