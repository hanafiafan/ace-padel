import { $, $$, api, esc, rp, ic, watch } from '/js/site.js';

let all = [], spec = '';
const list = $('#list'), dlg = $('#dlg');

const card = (c, i) => `<article class="coach rv" style="--d:${i * 60}ms">
  <img class="coach__img" src="${esc(c.imageUrl)}" alt="Pelatih ${esc(c.name)}" width="150" height="150" loading="lazy">
  <div><h3>${esc(c.name)}</h3><small>${esc(c.title)}</small>
    <div class="coach__m"><span>${ic('star')} ${Number(c.rating).toFixed(2)} <span class="muted">(${esc(c.reviewsCount ?? 0)} ulasan)</span></span><b>${rp(c.ratePerHour)}<small style="display:inline"> /jam</small></b></div>
    <div class="tags">${(c.specialties || []).map((s) => `<span>${esc(s)}</span>`).join('')}</div></div>
  <button class="btn btn--blue btn--sm" type="button" data-id="${esc(c.id)}">Lihat profil</button></article>`;

function render() {
  const r = all.filter((c) => !spec || (c.specialties || []).includes(spec));
  $('#count').textContent = `${r.length} pelatih`;
  list.setAttribute('aria-busy', 'false');
  list.innerHTML = r.length ? r.map(card).join('') : `<div class="empty"><h3>Belum ada pelatih untuk spesialisasi ini</h3><button class="btn btn--blue" type="button" id="er">Tampilkan semua</button></div>`;
  watch(list);
  $('#er')?.addEventListener('click', () => { spec = ''; setSpec(); render(); });
}
const setSpec = () => $$('#spec .chip').forEach((c) => c.setAttribute('aria-pressed', String(c.dataset.s === spec)));

api('/coaches').then((cs) => {
  all = cs.filter((c) => c.active !== false);
  const specs = [...new Set(all.flatMap((c) => c.specialties || []))];
  $('#spec').insertAdjacentHTML('beforeend', specs.map((s) => `<button class="chip" type="button" data-s="${esc(s)}" aria-pressed="false"><span>${esc(s)}</span></button>`).join(''));
  render();
}).catch(() => {
  list.setAttribute('aria-busy', 'false');
  list.innerHTML = `<div class="empty"><h3>Pelatih belum bisa dimuat</h3><p class="muted">Koneksi ke server bermasalah. Coba lagi beberapa saat.</p><button class="btn btn--blue" type="button" onclick="location.reload()">Muat ulang</button></div>`;
});

$('#spec').addEventListener('click', (e) => { const b = e.target.closest('.chip'); if (!b) return; spec = b.dataset.s; setSpec(); render(); });

list.addEventListener('click', (e) => {
  const b = e.target.closest('button[data-id]'); if (!b) return;
  const c = all.find((x) => x.id === b.dataset.id); if (!c) return;
  $('#dlg-b').innerHTML = `<div style="display:grid;grid-template-columns:96px 1fr;gap:16px;align-items:center"><img class="coach__img" style="width:96px;height:96px" src="${esc(c.imageUrl)}" alt="Pelatih ${esc(c.name)}" width="150" height="150"><div><h2 class="d h-md" id="dlg-t" style="font-style:italic">${esc(c.name)}</h2><small class="muted">${esc(c.title)}</small></div></div>
    <p>${esc(c.bio || '')}</p>
    <div class="coach__m"><span>${ic('star')} ${Number(c.rating).toFixed(2)} (${esc(c.reviewsCount ?? 0)} ulasan)</span><b>${rp(c.ratePerHour)} /jam</b></div>
    <div><span class="lbl">Pengalaman</span><p>${esc(c.experience || '-')}</p></div>
    <div><span class="lbl">Spesialisasi</span><div class="tags">${(c.specialties || []).map((s) => `<span>${esc(s)}</span>`).join('')}</div></div>
    <div><span class="lbl">Tersedia di venue</span><div class="tags">${(c.availableVenues || []).map((s) => `<span>${esc(s)}</span>`).join('') || '<span>-</span>'}</div></div>
    <a class="btn btn--blue btn--lg" href="/app/#/me">Pesan sesi di aplikasi</a>`;
  dlg.showModal();
});
$('#dlg-x').addEventListener('click', () => dlg.close());
dlg.addEventListener('click', (e) => { if (e.target === dlg) dlg.close(); });
