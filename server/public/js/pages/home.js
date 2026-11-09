import { $, $$, api, esc, ic, courtCard, ticker, countUp, watch, stars } from '/js/site.js';

api('/public/stats').then((s) => {
  $$('#score .score__c').forEach((el) => {
    const v = +s[el.dataset.k] || 0;
    if (!v) { el.hidden = true; return; }
    countUp($('.score__n', el), v);
  });
  if (s.venues) { $('#hs-n').textContent = s.venues; $('#hs-l').textContent = 'venue live'; }
}).catch(() => { $('#score').hidden = true; });

api('/courts?sortBy=rating').then((cs) => {
  if (!cs.length) throw new Error('kosong');
  ticker($('#ticker'), [...new Set(cs.map((c) => `${c.venue} · ${c.city}`))]);
  $('#spot').innerHTML = cs.slice(0, 8).map((c, i) => courtCard(c, i)).join('');
  watch($('#spot'));
  return Promise.all(cs.slice(0, 5).map((c) => api('/courts/' + encodeURIComponent(c.id)).catch(() => null)));
}).then((ds) => {
  const rv = ds.filter(Boolean).flatMap((d) => (d.reviews || []).filter((r) => r.comment && r.comment.length > 40).slice(0, 1).map((r) => ({ ...r, venue: d.venue })));
  if (!rv.length) throw new Error('kosong');
  $('#reviews').innerHTML = rv.slice(0, 3).map((r) => `<figure class="quote rv"><div>${stars(r.rating)} <span class="muted">${Number(r.rating).toFixed(1)}</span></div><blockquote>${esc(r.comment)}</blockquote><figcaption><b>${esc(r.userName)}</b>${esc(r.venue)}${r.skillLevel ? ' · ' + esc(r.skillLevel) : ''}</figcaption></figure>`).join('');
  watch($('#reviews'));
}).catch(() => {
  if (!$('#spot .vcard:not(.skel)')) $('#spot').innerHTML = `<div class="empty">${ic('pin')}<h3>Venue belum bisa dimuat</h3><p class="muted">Periksa koneksi, lalu coba lagi.</p><a class="btn btn--blue" href="/venue">Buka halaman Venue</a></div>`;
  $('#reviews').innerHTML = '<div class="empty"><h3>Ulasan belum tersedia</h3><p class="muted">Ulasan pemain akan tampil di sini setelah data berhasil dimuat.</p></div>';
  $('#ticker').hidden = true;
});
