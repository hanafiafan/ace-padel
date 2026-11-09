import { $, api, esc, rp, ic, stars, watch } from '/js/site.js';

const BASE = 'https://acepadel.hellens.dev';
const id = new URLSearchParams(location.search).get('id');
const tz = (d) => new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jakarta', year: 'numeric', month: '2-digit', day: '2-digit' }).format(d); // YYYY-MM-DD (WIB)
const dow = new Intl.DateTimeFormat('id-ID', { weekday: 'short', timeZone: 'Asia/Jakarta' });
const full = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long', timeZone: 'Asia/Jakarta' });

const meta = (sel, attr, val) => { const el = $(sel); if (el) el.setAttribute(attr, val); };

function fail(msg) {
  $('#h1').textContent = 'Venue tidak ditemukan';
  $('#v-sub').textContent = msg;
  $('#v-about').innerHTML = `<div class="empty">${ic('pin')}<h3>Kami tidak menemukan venue ini</h3><p class="muted">${esc(msg)}</p><a class="btn btn--blue" href="/venue">Lihat semua venue</a></div>`;
  $('#slots').innerHTML = ''; $('#dates').innerHTML = ''; $('#v-cta').hidden = true;
  document.title = 'Venue tidak ditemukan | Ace Padel';
  meta('meta[name="robots"]', 'content', 'noindex');
}

function seo(c, revs) {
  const url = `${BASE}/venue-detail?id=${encodeURIComponent(c.id)}`;
  const title = `${c.venue}, ${c.area || c.city} | Ace Padel`;
  const desc = `${c.venue} (${c.indoor ? 'indoor' : 'outdoor'}) di ${c.area || c.city}. ${rp(c.pricePerHour)} per jam, rating ${Number(c.rating).toFixed(1)}. Cek slot kosong dan pesan lewat Ace Padel.`;
  document.title = title;
  meta('meta[name="description"]', 'content', desc);
  meta('link[rel="canonical"]', 'href', url);
  [['og:title', title], ['og:description', desc], ['og:url', url], ['og:image', BASE + c.imageUrl]].forEach(([p, v]) => meta(`meta[property="${p}"]`, 'content', v));
  [['twitter:title', title], ['twitter:description', desc], ['twitter:image', BASE + c.imageUrl]].forEach(([p, v]) => meta(`meta[name="${p}"]`, 'content', v));
  const ld = { '@context': 'https://schema.org', '@type': 'SportsActivityLocation', name: c.venue, description: c.description, image: BASE + c.imageUrl, url,
    address: { '@type': 'PostalAddress', streetAddress: c.area, addressLocality: c.city, addressCountry: 'ID' },
    priceRange: `${rp(c.pricePerHour)} per jam`, amenityFeature: (c.facilities || []).map((n) => ({ '@type': 'LocationFeatureSpecification', name: n, value: true })) };
  if (revs.length) ld.aggregateRating = { '@type': 'AggregateRating', ratingValue: Number(c.rating).toFixed(1), reviewCount: revs.length, bestRating: 5 };
  const s = document.createElement('script'); s.type = 'application/ld+json'; s.textContent = JSON.stringify(ld); document.head.append(s);
  const bc = $('script[type="application/ld+json"]');
  try { const b = JSON.parse(bc.textContent); bc.textContent = JSON.stringify({ ...b, itemListElement: [...b.itemListElement.slice(0, 2), { '@type': 'ListItem', position: 3, name: c.venue, item: url }] }); } catch (e) { /* abaikan */ }
}

function render(c) {
  const revs = c.reviews || [];
  seo(c, revs);
  $('#v-img').src = c.imageUrl; $('#v-img').alt = `Lapangan ${c.name} di ${c.venue}`;
  $('#v-img').width = 520; $('#v-img').height = 397;
  $('#h1').textContent = c.venue;
  $('#v-crumb').textContent = c.venue;
  $('#v-kind').textContent = c.indoor ? 'Indoor' : 'Outdoor';
  $('#v-sub').textContent = c.name;
  $('#v-facts').innerHTML = `<span>${ic('pin')}${esc(c.area || c.city)}</span><span>${ic('star')}${Number(c.rating).toFixed(1)} rating</span><span>${ic('tag')}${rp(c.pricePerHour)} / jam</span>`;
  $('#v-about').innerHTML = `<h2 class="h-md d" style="margin-bottom:14px">Tentang venue</h2><p class="lead" style="max-width:68ch">${esc(c.description || 'Deskripsi belum tersedia.')}</p>`;
  $('#v-fac').innerHTML = (c.facilities || []).map((x) => `<li>${esc(x)}</li>`).join('') || '<li>Belum ada data fasilitas</li>';
  $('#v-price').textContent = rp(c.pricePerHour);
  $('#v-rev').innerHTML = revs.length ? revs.map((r) => `<article class="review"><div>${stars(r.rating)} <span class="muted">${Number(r.rating).toFixed(1)}</span></div><b>${esc(r.userName)}</b><p>${esc(r.comment || '')}</p>${r.skillLevel ? `<small class="muted">${esc(r.skillLevel)}</small>` : ''}</article>`).join('') : '<div class="empty"><h3>Belum ada ulasan</h3><p class="muted">Ulasan muncul setelah pemain menyelesaikan booking di venue ini.</p></div>';
  watch();
  dates();
}

let current;
function dates() {
  const now = new Date(); const box = $('#dates');
  box.innerHTML = Array.from({ length: 7 }, (_, i) => { const d = new Date(now.getTime() + i * 864e5); return `<button class="dchip" type="button" data-d="${tz(d)}" data-full="${esc(full.format(d))}" aria-pressed="${i === 0}"><small>${i === 0 ? 'Hari ini' : esc(dow.format(d))}</small><b>${tz(d).slice(8)}</b></button>`; }).join('');
  box.addEventListener('click', (e) => { const b = e.target.closest('.dchip'); if (!b) return; [...box.children].forEach((x) => x.setAttribute('aria-pressed', x === b)); slots(b.dataset.d); });
  slots(tz(now));
}

async function slots(date) {
  current = date;
  const el = $('#slots'); el.setAttribute('aria-busy', 'true');
  el.innerHTML = Array.from({ length: 10 }, () => '<div class="skel" style="min-height:56px" aria-hidden="true"></div>').join('');
  try {
    const d = await api(`/courts/${encodeURIComponent(id)}/slots?date=${date}`);
    if (current !== date) return;
    const list = d.slots || d;
    const free = list.filter((s) => s.available).length;
    el.innerHTML = list.map((s) => s.available ? `<div class="slot ok" role="img" aria-label="${s.slot}, tersedia">${esc(s.slot)}</div>` : `<div class="slot no" role="img" aria-label="${s.slot}, ${s.past ? 'sudah lewat' : s.blocked ? 'ditutup' : 'terisi'}">${esc(s.slot)}<small>${s.past ? 'lewat' : s.blocked ? 'ditutup' : 'terisi'}</small></div>`).join('')
      + `<p class="muted" style="grid-column:1/-1" role="status">${free} dari ${list.length} jam tersedia</p>`;
  } catch (e) {
    el.innerHTML = `<div class="empty" style="padding:20px"><p>Slot belum bisa dimuat.</p><button class="btn btn--sm btn--blue" type="button" id="retry">Coba lagi</button></div>`;
    $('#retry').addEventListener('click', () => slots(date));
  }
  el.setAttribute('aria-busy', 'false');
}

if (!id) fail('Alamat halaman ini belum memuat ID venue. Pilih venue dari daftar.');
else api('/courts/' + encodeURIComponent(id)).then(render).catch((e) => fail(String(e.message) === '404' ? 'Venue dengan ID tersebut tidak ada atau belum disetujui.' : 'Data venue belum bisa dimuat. Coba lagi beberapa saat.'));
