import { get, send } from '../api.js';
import { route, go, onLeave, state } from '../router.js';
import { $, $$, html, raw, mount, icon, on, busy, toast, debounce, confirmDialog, formDialog, statusBadge, badge, rupiah, num, dateId, dateTimeId, addDays, today, pageHead, stat, table, areaChart, empty, skeleton, loadInto, imgUrl, esc } from '../ui.js';
import { bookingDrawer, settingsView, BOOK_STATUS, userCell } from './shared.js';

const R = ['owner', 'admin'];
const reload = () => go(location.hash);
const shortId = (id) => id;

// ---------- Dashboard ----------
route('owner', R, async ({ el }) => {
  const d = (await get('/owner/stats', { days: 14 })).data, t = d.today, p = d.period;
  const bk = d.daily.map((x) => x.bookings), rv = d.daily.map((x) => x.revenue);
  mount(el, html`${pageHead('Dashboard', `Ringkasan ${d.courts} lapangan Anda · ${dateId(today())}`, html`<a class="btn lime" href="#/owner/schedule">${icon('calendar')}Kelola jadwal</a>`)}
    <div class="grid g4">
      ${stat('Booking hari ini', num(t.bookings), 'ticket', bk, `${num(p.bookings)} dalam 14 hari`)}
      ${stat('Pendapatan hari ini', rupiah(t.revenue), 'wallet', rv, `14 hari: ${rupiah(p.revenue)}`)}
      ${stat('Check-in hari ini', num(t.checkedIn), 'check', null, `dari ${num(t.bookings)} booking`)}
      ${stat('Okupansi hari ini', t.occupancy + '%', 'trend', null, `${d.courts} lapangan × 14 slot`)}
    </div>
    <div class="grid g21">
      <section class="card"><div class="card-h"><h3>Pendapatan 14 hari</h3>${badge(rupiah(p.revenue), 'info')}</div><div class="card-b">${areaChart(d.daily.map((x) => ({ label: dateId(x.date, { day: 'numeric', month: 'short' }), value: x.revenue })), rupiah)}</div></section>
      <section class="card"><div class="card-h"><h3>Perlu perhatian</h3></div><div class="card-b summary">
        <div><span class="muted">Menunggu pembayaran</span><b>${num(p.pendingPayment)}</b></div><div><span class="muted">Dibatalkan (14 hari)</span><b>${num(p.cancelled)}</b></div><div><span class="muted">Total booking (14 hari)</span><b>${num(p.bookings)}</b></div>
        <a class="btn block" href="#/owner/bookings">Lihat semua booking</a></div></section>
    </div>
    <div class="grid g21">
      <section class="card"><div class="card-h"><h3>Per lapangan</h3></div><div class="card-b flush">${table([
        { h: 'Lapangan', cell: (r) => html`<b>${r.name}</b><br><small class="muted">${r.venue}</small>` }, { h: 'Booking', cls: 'r num', cell: (r) => num(r.bookings) }, { h: 'Pendapatan', cls: 'r num', cell: (r) => rupiah(r.revenue) }], d.perCourt, { empty: empty('Belum ada lapangan', 'Tambahkan lapangan pertama Anda.', html`<a class="btn primary" href="#/owner/courts">Tambah lapangan</a>`) })}</div></section>
      <section class="card"><div class="card-h"><h3>Booking mendatang</h3></div><div class="card-b flush list" id="upc">${d.upcoming.length ? d.upcoming.map((b, i) => html`<div class="list-item" role="button" tabindex="0" data-i="${i}"><div class="grow"><b>${b.userName}</b><br><small class="muted">${dateId(b.date, { weekday: 'short', day: 'numeric', month: 'short' })} · ${b.slot} · ${b.court?.name || ''}</small></div>${statusBadge(b.paymentStatus)}</div>`) : empty('Belum ada booking mendatang')}</div></section>
    </div>`);
  const open = (e, row) => bookingDrawer(d.upcoming[+row.dataset.i], 'owner', reload);
  on($('#upc', el), 'click', '[data-i]', open);
  on($('#upc', el), 'keydown', '[data-i]', (e, r) => { if (e.key === 'Enter') open(e, r); });
}, { title: 'Dashboard' });

// ---------- Lapangan ----------
export function courtForm(c, { admin = false } = {}) {
  const f = [
    { name: 'name', label: 'Nama lapangan', required: true }, { name: 'venue', label: 'Nama venue', required: true },
    { name: 'area', label: 'Area', required: true, placeholder: 'Kemang, Jakarta', hint: 'Format: Kecamatan, Kota' },
    { name: 'pricePerHour', label: 'Harga per jam (ribuan Rp)', type: 'number', required: true, min: 1, step: 1, hint: '220 = Rp220.000' },
    { name: 'facilities', label: 'Fasilitas', hint: 'Pisahkan dengan koma, mis. Parkir, Shower, Kafe' },
    { name: 'indoor', label: 'Lapangan indoor', type: 'checkbox' }, { name: 'description', label: 'Deskripsi', type: 'textarea' }, { name: 'image', type: 'hidden' },
  ];
  const v = c ? { ...c, facilities: (c.facilities || []).join(', '), image: c.imageUrl && c.imageUrl.startsWith('/uploads/') ? c.imageUrl : '' } : { indoor: true };
  return formDialog({
    title: c ? 'Ubah lapangan' : 'Tambah lapangan', wide: true, fields: f, values: v, submitText: c ? 'Simpan' : admin ? 'Tambah' : 'Ajukan lapangan',
    desc: !c && !admin ? 'Lapangan baru akan ditinjau admin sebelum tampil untuk pemain.' : '',
    extra: html`<div class="field" style="margin-top:14px"><label>Foto lapangan</label><div class="upload"><img id="prev" alt="Pratinjau" src="${c ? imgUrl(c) : '/img/logo.png'}"><div><input type="file" id="file" accept="image/png,image/jpeg,image/webp" class="sr" aria-label="Pilih foto"><button class="btn" type="button" id="pick">${icon('upload')}Unggah foto</button><br><small class="muted">PNG/JPEG/WebP, maks 3 MB</small></div></div><p class="form-err" id="uperr" hidden></p></div>`,
    onReady: (m, form) => {
      $('#pick', m).onclick = () => $('#file', m).click();
      $('#file', m).onchange = (e) => {
        const file = e.target.files[0], err = $('#uperr', m); if (!file) return; err.hidden = true;
        if (file.size > 3 * 1024 * 1024) { err.textContent = 'Ukuran foto maksimal 3 MB'; err.hidden = false; return; }
        busy($('#pick', m), async () => {
          const dataUrl = await new Promise((ok, no) => { const r = new FileReader(); r.onload = () => ok(r.result); r.onerror = no; r.readAsDataURL(file); });
          const url = (await send('POST', '/owner/uploads', { dataUrl })).data.url;
          form.elements.image.value = url; $('#prev', m).src = url; toast('Foto terunggah');
        });
      };
    },
    onSubmit: async (x) => {
      const body = { name: x.name, venue: x.venue, area: x.area, pricePerHour: x.pricePerHour, indoor: x.indoor, description: x.description, facilities: x.facilities.split(',').map((s) => s.trim()).filter(Boolean) };
      if (x.image) body.image = x.image;
      const r = c ? await send('PUT', `/owner/courts/${c.id}`, body) : await send('POST', '/owner/courts', body);
      toast(r.message || 'Tersimpan'); return r.data;
    },
  });
}

route('owner/courts', R, async ({ el, user }) => {
  const admin = user.role === 'admin';
  const draw = async () => {
    const list = (await get('/owner/courts')).data;
    mount(el, html`${pageHead('Lapangan', 'Kelola lapangan dan pantau status persetujuan.', html`<button class="btn primary" id="add">${icon('plus')}Tambah lapangan</button>`)}
      ${list.length ? html`<div class="court-grid">${list.map((c, i) => html`<article class="card court-card" style="animation-delay:${i * 40}ms"><div class="court-img" style="background-image:url('${imgUrl(c)}')" role="img" aria-label="${c.name}">${statusBadge(c.status)}<span class="pill">${rupiah(c.pricePerHour)}/jam</span></div>
        <div class="court-body"><h3>${c.name}</h3><div class="muted">${icon('pin')} ${c.venue} · ${c.area}</div><div class="muted">${c.indoor ? 'Indoor' : 'Outdoor'} · ★ ${c.rating || '-'}${admin && c.ownerName ? ' · ' + c.ownerName : ''}</div>
          ${c.status === 'rejected' ? html`<p class="form-err">Pengajuan ditolak. Perbaiki data lalu ajukan ulang.</p>` : ''}${c.status === 'suspended' ? html`<p class="form-err">Lapangan ditangguhkan admin dan tidak tampil publik.</p>` : ''}${c.status === 'pending' ? html`<p class="muted">Menunggu persetujuan admin.</p>` : ''}
          <div class="row"><button class="btn sm" data-edit="${c.id}">${icon('edit')}Ubah</button>${c.status === 'rejected' ? html`<button class="btn sm lime" data-resubmit="${c.id}">Ajukan ulang</button>` : ''}<a class="btn sm" href="#/owner/schedule?court=${c.id}">${icon('calendar')}Jadwal</a></div></div></article>`)}</div>`
        : html`<div class="card">${empty('Belum ada lapangan', 'Tambahkan lapangan untuk mulai menerima booking.')}</div>`}`);
    $('#add', el).onclick = async () => { if (await courtForm(null, { admin })) draw(); };
    on(el, 'click', '[data-edit]', async (e, b) => { if (await courtForm(list.find((c) => c.id === b.dataset.edit), { admin })) draw(); });
    on(el, 'click', '[data-resubmit]', (e, b) => busy(b, async () => { await send('PUT', `/owner/courts/${b.dataset.resubmit}`, {}); toast('Diajukan ulang ke admin'); draw(); }));
  };
  await draw();
}, { title: 'Lapangan' });

// ---------- Jadwal ----------
route('owner/schedule', R, async ({ el, query }) => {
  const courts = (await get('/owner/courts')).data;
  if (!courts.length) return mount(el, html`${pageHead('Jadwal')}<div class="card">${empty('Belum ada lapangan', 'Tambahkan lapangan terlebih dahulu.', html`<a class="btn primary" href="#/owner/courts">Ke Lapangan</a>`)}</div>`);
  let courtId = courts.find((c) => c.id === query.court)?.id || courts[0].id, date = query.date || today();
  mount(el, html`${pageHead('Jadwal', 'Klik slot kosong untuk memblokir atau membuat booking walk-in.')}
    <div class="toolbar"><select class="input" id="cs" aria-label="Lapangan">${courts.map((c) => html`<option value="${c.id}" ${raw(c.id === courtId ? 'selected' : '')}>${c.name} — ${c.venue}</option>`)}</select>
      <button class="btn icon" id="pv" aria-label="Hari sebelumnya">${icon('left')}</button><input class="input" type="date" id="ds" value="${date}" aria-label="Tanggal"><button class="btn icon" id="nx" aria-label="Hari berikutnya">${icon('chevron')}</button><button class="btn" id="td">Hari ini</button></div>
    <div class="legend"><span><i style="border-style:dashed"></i>Kosong</span><span><i style="background:var(--info-bg)"></i>Booking</span><span><i style="background:var(--ok-bg)"></i>Sudah check-in</span><span><i style="background:var(--line)"></i>Diblokir</span></div>
    <div id="grid"></div>`);
  const grid = $('#grid', el);
  const draw = () => loadInto(grid, async () => {
    const rows = (await get('/owner/schedule', { courtId, date })).data, court = courts.find((c) => c.id === courtId);
    mount(grid, html`<div class="slots">${rows.map((r, i) => { const b = r.booking, cls = !b ? 'free' : b.status === 'Maintenance' ? 'blocked' : b.status === 'Check-in Selesai' ? 'in' : 'booked';
      return html`<button class="slot ${cls}" data-i="${i}" aria-label="${r.slot}, ${!b ? 'kosong' : b.status === 'Maintenance' ? 'diblokir' : 'dipesan ' + b.userName}"><b>${r.slot}</b><small>${!b ? 'Kosong' : b.status === 'Maintenance' ? 'Blokir: ' + (b.note || '-') : b.userName}</small>${b && cls !== 'blocked' ? html`<small>${statusBadge(b.paymentStatus)}</small>` : ''}</button>`; })}</div>`);
    on(grid, 'click', '.slot', async (e, btn) => {
      const r = rows[+btn.dataset.i];
      if (r.booking) return bookingDrawer({ ...r.booking, court: r.booking.court || court }, 'owner', draw);
      const res = await formDialog({
        title: `Slot ${r.slot} · ${dateId(date)}`, desc: court.name, submitText: 'Simpan',
        fields: [{ name: 'action', label: 'Tindakan', type: 'select', options: [['walkin', 'Booking walk-in (tamu datang langsung)'], ['block', 'Blokir slot (perawatan / acara)']] }, { name: 'customerName', label: 'Nama pelanggan (walk-in)', placeholder: 'Mis. Budi' }, { name: 'reason', label: 'Alasan blokir', placeholder: 'Mis. Perawatan lapangan' }],
        onSubmit: async (x) => {
          if (x.action === 'walkin') { if (!x.customerName) throw new Error('Nama pelanggan wajib diisi'); await send('POST', '/owner/manual-booking', { courtId, date, slot: r.slot, customerName: x.customerName }); toast('Booking walk-in dibuat'); }
          else { if (!x.reason) throw new Error('Alasan blokir wajib diisi'); await send('POST', '/owner/toggle-slot', { courtId, date, slot: r.slot, action: 'block', reason: x.reason }); toast('Slot diblokir'); }
          return true;
        },
      });
      if (res) draw();
    });
  });
  const setDate = (d) => { if (!d) return; date = d; $('#ds', el).value = d; draw(); };
  $('#cs', el).onchange = (e) => { courtId = e.target.value; draw(); };
  $('#ds', el).onchange = (e) => setDate(e.target.value);
  $('#pv', el).onclick = () => setDate(addDays(date, -1)); $('#nx', el).onclick = () => setDate(addDays(date, 1)); $('#td', el).onclick = () => setDate(today());
  draw();
}, { title: 'Jadwal' });

// ---------- Booking ----------
export function bookingList({ el, courts, mode, base, extraCols = [] }) {
  mount(el, html`<div class="toolbar"><input class="input grow" type="search" id="q" placeholder="Cari nama pemain / kode booking" aria-label="Cari booking">
    <select class="input" id="st" aria-label="Status">${BOOK_STATUS.map(([v, l]) => html`<option value="${v}">${l}</option>`)}</select>
    ${courts ? html`<select class="input" id="cs" aria-label="Lapangan"><option value="">Semua lapangan</option>${courts.map((c) => html`<option value="${c.id}">${c.name}</option>`)}</select>` : ''}
    ${mode === 'owner' ? html`<input class="input" type="date" id="fr" aria-label="Dari tanggal" title="Dari tanggal"><input class="input" type="date" id="to" aria-label="Sampai tanggal" title="Sampai tanggal">` : ''}</div>
    <section class="card"><div id="res"></div></section>`);
  const res = $('#res', el);
  const load = () => loadInto(res, async () => {
    const r = await get(base, { q: $('#q', el).value.trim(), status: $('#st', el).value, courtId: $('#cs', el)?.value, from: $('#fr', el)?.value, to: $('#to', el)?.value });
    const rows = r.data;
    mount(res, html`<div class="card-b" style="padding-bottom:0"><small class="muted">${num(rows.length)} booking</small></div>${table([
      { h: 'Kode', cell: (b) => html`<code title="${b.id}">${shortId(b.id)}</code>` }, { h: 'Pemain', cell: (b) => userCell(b.userName, b.userEmail || '') },
      { h: 'Lapangan', cell: (b) => b.court?.name || b.courtId }, { h: 'Jadwal', cell: (b) => html`${dateId(b.date, { day: 'numeric', month: 'short' })} · ${b.slot}` },
      { h: 'Total', cls: 'r num', cell: (b) => rupiah(b.finalPrice) }, { h: 'Status', cell: (b) => statusBadge(b.status) }, { h: 'Pembayaran', cell: (b) => (b.status === 'Maintenance' ? '-' : statusBadge(b.paymentStatus)) }, ...extraCols,
    ], rows, { empty: empty('Tidak ada booking', 'Coba ubah filter pencarian.') })}`);
    res.querySelectorAll('tbody tr').forEach((tr) => tr.classList.add('click'));
    res.onclick = (e) => { const tr = e.target.closest('tr[data-i]'); if (tr && !e.target.closest('button,a')) bookingDrawer(rows[+tr.dataset.i], mode, load); };
  });
  const dl = debounce(load, 300);
  $('#q', el).oninput = dl; $$('select,input[type=date]', el).forEach((x) => { x.onchange = load; });
  load();
}
route('owner/bookings', R, async ({ el }) => {
  const courts = (await get('/owner/courts')).data;
  const wrap = document.createElement('div'); mount(el, pageHead('Booking', 'Semua reservasi di lapangan Anda.')); el.append(wrap); wrap.style.marginTop = '20px';
  bookingList({ el: wrap, courts, mode: 'owner', base: '/owner/bookings' });
}, { title: 'Booking' });

// ---------- Check-in ----------
route('owner/checkin', R, ({ el }) => {
  const canScan = 'BarcodeDetector' in window && navigator.mediaDevices?.getUserMedia;
  mount(el, html`${pageHead('Check-in', 'Verifikasi tiket pemain saat tiba di lapangan.')}
    <div class="grid g2"><section class="card"><div class="card-h"><h3>Kode tiket</h3>${icon('scan')}</div><div class="card-b">
      <form id="cf" style="display:flex;gap:8px;flex-wrap:wrap"><input class="input" id="code" style="flex:1 1 200px" placeholder="Tempel / ketik ID booking, mis. ACE-C1-1000-1474" required aria-label="ID booking" autocomplete="off" autocapitalize="characters"><button class="btn primary" type="submit">Verifikasi</button></form>
      <div style="margin-top:12px">${canScan ? html`<button class="btn" id="scan">${icon('qr')}Scan dengan kamera</button>` : html`<small class="muted">Scan kamera tidak didukung browser ini. Masukkan kode secara manual.</small>`}</div>
      <div id="cam" hidden style="margin-top:12px"><video class="cam" id="vid" playsinline muted></video><button class="btn sm" id="stop" style="margin-top:8px">Hentikan kamera</button></div></div></section>
    <section id="out" aria-live="polite">${html`<div class="card">${empty('Menunggu kode tiket', 'Hasil verifikasi akan tampil di sini.')}</div>`}</section></div>`);
  const out = $('#out', el), code = $('#code', el);
  let stream = null, timer = 0;
  const stopCam = () => { clearInterval(timer); stream?.getTracks().forEach((t) => t.stop()); stream = null; $('#cam', el).hidden = true; };
  onLeave(stopCam);
  const fail = (msg, b) => mount(out, html`<div class="result bad">${icon('x')}<h2>Tiket tidak valid</h2><p>${msg}</p>${b ? html`<dl class="kv"><dt>Pemain</dt><dd>${b.userName}</dd><dt>Jadwal</dt><dd>${dateId(b.date)} · ${b.slot}</dd><dt>Status</dt><dd>${statusBadge(b.status)} ${statusBadge(b.paymentStatus)}</dd></dl>` : ''}</div>`);
  const verify = async (id) => {
    id = id.trim(); if (!id) return;
    mount(out, skeleton(1, 160));
    try {
      const r = await send('POST', '/owner/verify-ticket', { bookingId: id }), b = r.data;
      mount(out, html`<div class="result ok">${icon('check')}<h2>Tiket valid</h2><p>${r.message}</p><dl class="kv"><dt>Pemain</dt><dd>${b.userName}</dd><dt>Lapangan</dt><dd>${b.court?.name || b.courtId}</dd><dt>Jadwal</dt><dd>${dateId(b.date)} · ${b.slot}</dd><dt>Pembayaran</dt><dd>${statusBadge(b.paymentStatus)}</dd></dl><button class="btn lime lg" id="do">Check-in sekarang</button></div>`);
      $('#do', out).onclick = (e) => busy(e.currentTarget, async () => {
        await send('POST', '/owner/check-in', { bookingId: b.id });
        mount(out, html`<div class="result ok">${icon('check')}<h2>Check-in berhasil</h2><p>${b.userName} · ${b.court?.name || ''} · ${b.slot}</p><small>Pemain mendapat +50 poin.</small></div>`); toast('Check-in berhasil'); code.value = ''; code.focus();
      });
    } catch (e) { fail(e.message, e.body?.data); }
  };
  $('#cf', el).addEventListener('submit', (e) => { e.preventDefault(); verify(code.value); });
  $('#stop', el)?.addEventListener('click', stopCam);
  $('#scan', el)?.addEventListener('click', async () => {
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      const v = $('#vid', el); v.srcObject = stream; await v.play(); $('#cam', el).hidden = false;
      const det = new window.BarcodeDetector({ formats: ['qr_code'] });
      timer = setInterval(async () => { try { const f = await det.detect(v); if (f[0]) { stopCam(); code.value = f[0].rawValue; verify(f[0].rawValue); } } catch { /* frame gagal */ } }, 350);
    } catch { stopCam(); toast('Kamera tidak dapat diakses. Izinkan akses kamera atau ketik kode manual.', 'err'); }
  });
  code.focus();
}, { title: 'Check-in' });

// ---------- Ulasan ----------
route('owner/reviews', R, async ({ el }) => {
  const rows = (await get('/owner/reviews')).data;
  mount(el, html`${pageHead('Ulasan', 'Apa kata pemain tentang lapangan Anda.')}<section class="card">${rows.length ? html`<div class="list">${rows.map((r) => html`<div class="list-item"><div class="grow"><b>${r.userName}</b> <span class="stars" aria-label="${r.rating} dari 5">${'★'.repeat(Math.round(r.rating))}</span> <small class="muted">${r.rating}</small><p>${r.comment || html`<i class="muted">Tanpa komentar</i>`}</p><small class="muted">${r.courtName} · ${r.venue} · ${dateTimeId(r.createdAt)}</small></div></div>`)}</div>` : empty('Belum ada ulasan', 'Ulasan pemain akan muncul di sini.')}</section>`);
}, { title: 'Ulasan' });

route('owner/settings', R, settingsView, { title: 'Pengaturan' });
