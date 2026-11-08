import { get, send } from '../api.js';
import { route, go, state } from '../router.js';
import { $, $$, html, raw, mount, icon, on, busy, toast, debounce, statusBadge, badge, rupiah, num, dateId, dateTimeId, addDays, today, pageHead, empty, loadInto, imgUrl, openModal, skeleton } from '../ui.js';
import { bookingDrawer, settingsView, ticketHtml } from './shared.js';

const P = ['player'];
const reload = () => go(location.hash);
const PAY = ['Bayar di tempat', 'QRIS Instant', 'BCA Virtual Account', 'Mandiri Virtual Account'];

const courtCard = (c, i) => html`<a class="card court-card" href="#/me/court/${c.id}" style="animation-delay:${i * 30}ms;text-decoration:none;color:inherit"><div class="court-img" style="background-image:url('${imgUrl(c)}')" role="img" aria-label="${c.name}">${badge(c.indoor ? 'Indoor' : 'Outdoor', 'info')}<span class="pill">${rupiah(c.pricePerHour)}/jam</span></div>
  <div class="court-body"><h3>${c.name}</h3><div class="muted">${c.venue}</div><div class="muted">${icon('pin')} ${c.area} · <span class="stars">★</span> ${c.rating || '-'}</div></div></a>`;

route('me', P, async ({ el, user }) => {
  const cities = (await get('/courts/meta/cities')).data || [];
  mount(el, html`<section class="card hero"><h2>Halo, ${user.name.split(' ')[0]}!</h2><p>Temukan lapangan padel dan booking dalam hitungan detik.</p></section>
    <div class="toolbar"><input class="input grow" type="search" id="q" placeholder="Cari lapangan atau venue" aria-label="Cari lapangan">
      <select class="input" id="in" aria-label="Jenis"><option value="">Indoor &amp; outdoor</option><option value="true">Indoor</option><option value="false">Outdoor</option></select>
      <select class="input" id="ct" aria-label="Kota"><option value="">Semua kota</option>${cities.map((c) => html`<option>${typeof c === 'string' ? c : c.city}</option>`)}</select>
      <select class="input" id="so" aria-label="Urutkan"><option value="rating">Rating tertinggi</option><option value="price_asc">Termurah</option><option value="price_desc">Termahal</option></select></div><div id="res"></div>`);
  const res = $('#res', el);
  const load = () => loadInto(res, async () => {
    const rows = (await get('/courts', { q: $('#q', el).value.trim(), indoor: $('#in', el).value, city: $('#ct', el).value, sortBy: $('#so', el).value })).data;
    mount(res, rows.length ? html`<div class="court-grid">${rows.map(courtCard)}</div>` : html`<div class="card">${empty('Lapangan tidak ditemukan', 'Coba kata kunci atau filter lain.')}</div>`);
  });
  $('#q', el).oninput = debounce(load, 300); $$('select', el).forEach((s) => { s.onchange = load; }); load();
}, { title: 'Beranda' });

route('me/court/:id', P, async ({ el, params }) => {
  const [c, addons] = await Promise.all([get('/courts/' + params.id).then((r) => r.data), get('/addons').then((r) => r.data).catch(() => [])]);
  let date = today(), slot = '', disc = 0, vcode = '';
  const days = Array.from({ length: 7 }, (_, i) => addDays(today(), i));
  mount(el, html`<a href="#/me" class="btn ghost sm">${icon('left')}Kembali</a>
    <div class="court-hero" style="background-image:url('${imgUrl(c)}')" role="img" aria-label="${c.name}"></div>
    <div class="grid g21"><div style="display:grid;gap:20px;align-content:start">
      <section class="card"><div class="card-b"><div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center"><h1>${c.name}</h1>${badge(c.indoor ? 'Indoor' : 'Outdoor', 'info')}</div>
        <p class="muted" style="margin-top:6px">${c.venue} · ${c.area} · ★ ${c.rating || '-'} · <b style="color:var(--ink)">${rupiah(c.pricePerHour)}/jam</b></p><p style="margin-top:12px">${c.description}</p>
        <div class="row" style="display:flex;gap:6px;flex-wrap:wrap;margin-top:12px">${(c.facilities || []).map((f) => badge(f))}</div></div></section>
      <section class="card"><div class="card-h"><h3>Pilih jadwal</h3></div><div class="card-b" style="display:grid;gap:14px"><div class="chips" id="days" role="tablist" aria-label="Tanggal">${days.map((d) => html`<button class="chip date ${d === date ? 'on' : ''}" data-d="${d}" role="tab">${dateId(d, { weekday: 'short' })}<b>${dateId(d, { day: 'numeric' })}</b><small>${dateId(d, { month: 'short' })}</small></button>`)}</div><div id="sl"></div></div></section>
      ${(c.reviews || []).length ? html`<section class="card"><div class="card-h"><h3>Ulasan</h3></div><div class="card-b flush list">${c.reviews.slice(0, 5).map((r) => html`<div class="list-item"><div class="grow"><b>${r.userName}</b> <span class="stars">${'★'.repeat(Math.round(r.rating))}</span><p>${r.comment}</p></div></div>`)}</div></section>` : ''}</div>
      <aside class="card" style="align-self:start;position:sticky;top:80px"><div class="card-h"><h3>Ringkasan</h3></div><div class="card-b" style="display:grid;gap:14px" id="sum"></div></aside></div>`);
  const sl = $('#sl', el), sum = $('#sum', el);
  const total = () => { const ad = addons.filter((a) => $$('[name=ad]:checked', sum).some((x) => x.value === String(a.id))).reduce((s, a) => s + a.price, 0); return { ad, tot: Math.max(c.pricePerHour + ad - disc, 0) }; };
  const paintTotals = () => { const t = total(); $('#tot', sum).textContent = rupiah(t.tot); $('#adv', sum).textContent = rupiah(t.ad); $('#dsv', sum).textContent = '− ' + rupiah(disc); };
  const drawSum = () => {
    mount(sum, html`<div class="summary"><div><span class="muted">Jadwal</span><b>${slot ? `${dateId(date, { day: 'numeric', month: 'short' })} · ${slot}` : 'Belum dipilih'}</b></div></div>
      ${addons.length ? html`<fieldset style="border:0;padding:0;margin:0"><legend class="muted" style="margin-bottom:6px">Add-on</legend>${addons.map((a) => html`<label class="check"><input type="checkbox" name="ad" value="${a.id}"><span>${a.name} (${rupiah(a.price)})</span></label>`)}</fieldset>` : ''}
      <div class="field"><label for="vc">Kode voucher</label><div style="display:flex;gap:8px"><input class="input" id="vc" value="${vcode}" placeholder="ACEWEEKEND" autocapitalize="characters"><button class="btn" id="vb" type="button">Pakai</button></div><small id="vm"></small></div>
      <div class="field"><label for="pm">Metode pembayaran</label><select class="input" id="pm">${PAY.map((p) => html`<option>${p}</option>`)}</select></div>
      <div class="summary"><div><span class="muted">Sewa</span><span>${rupiah(c.pricePerHour)}</span></div><div><span class="muted">Add-on</span><span id="adv"></span></div><div><span class="muted">Diskon</span><span id="dsv"></span></div><div class="tot"><span>Total</span><span id="tot"></span></div></div>
      <button class="btn lime lg block" id="bk" ${raw(slot ? '' : 'disabled')}>Booking sekarang</button>`);
    paintTotals();
    sum.onchange = (e) => { if (e.target.name === 'ad') paintTotals(); };
    $('#vb', sum).onclick = (e) => busy(e.currentTarget, async () => {
      vcode = $('#vc', sum).value.trim().toUpperCase(); const vm = $('#vm', sum);
      if (!vcode) { disc = 0; paintTotals(); vm.textContent = ''; return; }
      try { disc = (await send('POST', '/vouchers/validate', { code: vcode, price: c.pricePerHour })).data.discount || 0; vm.textContent = `Voucher berlaku: hemat ${rupiah(disc)}`; vm.style.color = 'var(--ok)'; } catch (x) { disc = 0; vm.textContent = x.message; vm.style.color = 'var(--danger)'; }
      paintTotals();
    });
    $('#bk', sum).onclick = (e) => busy(e.currentTarget, async () => {
      const r = await send('POST', '/bookings', { courtId: c.id, date, slot, paymentMethod: $('#pm', sum).value, voucherCode: disc ? vcode : undefined, addOns: $$('[name=ad]:checked', sum).map((x) => x.value) });
      toast('Booking berhasil!'); bookingDrawer(r.data, 'player', null); go('#/me/bookings');
    });
  };
  const drawSlots = () => loadInto(sl, async () => {
    slot = ''; const sr = await get(`/courts/${c.id}/slots`, { date }), rows = sr.slots || sr.data || [];
    mount(sl, html`<div class="slots">${rows.map((s) => html`<button class="slot ${s.available ? '' : 'blocked'}" data-s="${s.slot}" ${raw(s.available ? '' : 'disabled')} aria-pressed="false"><b>${s.slot}</b><small>${s.available ? 'Tersedia' : s.past ? 'Lewat' : s.blocked ? 'Ditutup' : 'Penuh'}</small></button>`)}</div>`);
    drawSum();
  });
  on($('#days', el), 'click', '[data-d]', (e, b) => { date = b.dataset.d; $$('.chip', el).forEach((x) => x.classList.toggle('on', x === b)); drawSlots(); });
  on(sl, 'click', '[data-s]', (e, b) => { slot = b.dataset.s; $$('.slot', sl).forEach((x) => { x.classList.toggle('sel', x === b); x.setAttribute('aria-pressed', x === b); }); const keep = { v: $('#vc', sum)?.value, p: $('#pm', sum)?.value, a: $$('[name=ad]:checked', sum).map((x) => x.value) }; drawSum(); $('#vc', sum).value = keep.v; $('#pm', sum).value = keep.p; keep.a.forEach((v) => { const x = $(`[name=ad][value="${v}"]`, sum); if (x) x.checked = true; }); paintTotals(); });
  drawSlots();
}, { title: 'Detail lapangan' });

route('me/bookings', P, async ({ el }) => {
  const d = await get('/bookings');
  let tab = 'active';
  const draw = () => {
    const rows = tab === 'active' ? d.data?.active || d.active : d.data?.history || d.history;
    mount(el, html`${pageHead('Booking saya', 'Tiket dan riwayat reservasi Anda.', html`<a class="btn lime" href="#/me">${icon('plus')}Booking baru</a>`)}
      <div class="tabs" role="tablist"><button role="tab" data-t="active" aria-selected="${String(tab === 'active')}">Aktif (${(d.data?.active || d.active).length})</button><button role="tab" data-t="history" aria-selected="${String(tab === 'history')}">Riwayat (${(d.data?.history || d.history).length})</button></div>
      ${rows.length ? html`<div class="court-grid">${rows.map((b, i) => html`<article class="card court-card" style="animation-delay:${i * 30}ms"><div class="court-body"><div style="display:flex;justify-content:space-between;gap:8px"><h3>${b.court?.name || b.courtId}</h3>${statusBadge(b.status)}</div><div class="muted">${b.court?.venue || ''}</div><div><b>${dateId(b.date)}</b> · ${b.slot}</div><div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><b>${rupiah(b.finalPrice)}</b>${statusBadge(b.paymentStatus)}</div>
        ${b.paymentStatus === 'Menunggu' && b.paymentRef ? html`<div class="muted">Ref. bayar: <code>${b.paymentRef}</code></div>` : ''}<div class="row"><button class="btn sm" data-i="${i}">${icon('qr')}Tiket${b.status === 'Terkonfirmasi' ? ' & aksi' : ''}</button></div></div></article>`)}</div>`
        : html`<div class="card">${empty(tab === 'active' ? 'Belum ada booking aktif' : 'Riwayat kosong', 'Pilih lapangan favorit Anda dan booking sekarang.', html`<a class="btn primary" href="#/me">Cari lapangan</a>`)}</div>`}`);
    on(el, 'click', '[data-t]', (e, b) => { tab = b.dataset.t; draw(); });
    on(el, 'click', '[data-i]', (e, b) => bookingDrawer(rows[+b.dataset.i], 'player', reload));
  };
  draw();
}, { title: 'Booking saya' });

route('me/notifications', P, async ({ el }) => {
  const r = await get('/notifications'), rows = r.data;
  mount(el, html`${pageHead('Notifikasi', `${r.unread || 0} belum dibaca`, rows.length ? html`<button class="btn" id="ra">${icon('check')}Tandai semua dibaca</button>` : '')}
    <section class="card">${rows.length ? html`<div class="list">${rows.map((n) => html`<div class="list-item ${n.read ? '' : 'unread'}"><span class="stat-ic">${icon('bell')}</span><div class="grow"><b>${n.title}</b><p class="muted">${n.body}</p></div><small class="muted">${dateTimeId(n.createdAt)}</small></div>`)}</div>` : empty('Belum ada notifikasi')}</section>`);
  $('#ra', el)?.addEventListener('click', (e) => busy(e.currentTarget, async () => { await send('POST', '/notifications/read-all'); reload(); }));
}, { title: 'Notifikasi' });

route('me/settings', P, settingsView, { title: 'Profil' });
