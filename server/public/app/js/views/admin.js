import { get, send } from '../api.js';
import { route, go, state } from '../router.js';
import { $, $$, html, raw, mount, icon, on, busy, toast, debounce, confirmDialog, formDialog, statusBadge, badge, rupiah, num, dateId, dateTimeId, pageHead, stat, table, areaChart, empty, loadInto, imgUrl } from '../ui.js';
import { settingsView, userCell } from './shared.js';
import { bookingList } from './owner.js';

const A = ['admin'];
const reload = () => go(location.hash);

// ---------- Overview ----------
route('admin', A, async ({ el }) => {
  const d = (await get('/admin/overview')).data, dv = d.daily;
  mount(el, html`${pageHead('Overview', 'Kondisi platform Ace Padel saat ini.', d.courts.pending ? html`<a class="btn lime" href="#/admin/courts?status=pending">${icon('shield')}${d.courts.pending} lapangan menunggu</a>` : '')}
    <div class="grid g4">
      ${stat('Pengguna', num(d.users.total), 'users', null, `${d.users.players} pemain · ${d.users.owners} pemilik`)}
      ${stat('Lapangan', num(d.courts.approved), 'court', null, `${d.courts.pending} menunggu · ${d.courts.venues} venue`)}
      ${stat('Booking', num(d.bookings.total), 'ticket', dv.map((x) => x.bookings), `${d.bookings.today} hari ini`)}
      ${stat('Pendapatan', rupiah(d.revenue.paid), 'wallet', dv.map((x) => x.revenue), `14 hari: ${rupiah(d.revenue.last14)}`)}
    </div>
    <div class="grid g21"><section class="card"><div class="card-h"><h3>Pendapatan 14 hari</h3>${badge(rupiah(d.revenue.last14), 'info')}</div><div class="card-b">${areaChart(dv.map((x) => ({ label: dateId(x.date, { day: 'numeric', month: 'short' }), value: x.revenue })), rupiah)}</div></section>
      <section class="card"><div class="card-h"><h3>Venue teratas</h3></div><div class="card-b flush">${table([{ h: 'Venue', cell: (v) => html`<b>${v.venue}</b>` }, { h: 'Booking', cls: 'r num', cell: (v) => num(v.bookings) }, { h: 'Pendapatan', cls: 'r num', cell: (v) => rupiah(v.revenue) }], d.topVenues.slice(0, 6))}</div></section></div>
    <section class="card"><div class="card-h"><h3>Booking terbaru</h3><a href="#/admin/bookings">Lihat semua</a></div><div class="card-b flush">${table([
      { h: 'Pemain', cell: (b) => userCell(b.userName, b.id) }, { h: 'Lapangan', cell: (b) => b.court?.name || b.courtId }, { h: 'Jadwal', cell: (b) => `${dateId(b.date, { day: 'numeric', month: 'short' })} · ${b.slot}` },
      { h: 'Total', cls: 'r num', cell: (b) => rupiah(b.finalPrice) }, { h: 'Status', cell: (b) => statusBadge(b.status) }], d.recent.slice(0, 8), { empty: empty('Belum ada booking') })}</div></section>`);
}, { title: 'Overview' });

// ---------- Pengguna ----------
route('admin/users', A, ({ el }) => {
  mount(el, html`${pageHead('Pengguna', 'Kelola peran dan status akun.')}
    <div class="toolbar"><input class="input grow" type="search" id="q" placeholder="Cari nama atau email" aria-label="Cari pengguna"><select class="input" id="rl" aria-label="Peran"><option value="">Semua peran</option><option value="player">Pemain</option><option value="owner">Pemilik</option><option value="admin">Admin</option></select>
    <select class="input" id="st" aria-label="Status"><option value="">Semua status</option><option value="active">Aktif</option><option value="suspended">Ditangguhkan</option></select></div><section class="card" id="res"></section>`);
  const res = $('#res', el);
  const load = () => loadInto(res, async () => {
    const rows = (await get('/admin/users', { q: $('#q', el).value.trim(), role: $('#rl', el).value, status: $('#st', el).value })).data;
    mount(res, html`<div class="card-b" style="padding-bottom:0"><small class="muted">${num(rows.length)} pengguna</small></div>${table([
      { h: 'Pengguna', cell: (u) => userCell(u.name, u.email) }, { h: 'Peran', cell: (u) => statusBadge(u.role) },
      { h: 'Status', cell: (u) => (u.status === 'suspended' ? badge('Ditangguhkan', 'danger') : badge('Aktif', 'ok')) }, { h: 'Poin', cls: 'r num', cell: (u) => num(u.points) }, { h: 'Bergabung', cell: (u) => dateTimeId(u.createdAt) },
      { h: '', cls: 'r', cell: (u) => (u.id === state.user.id ? html`<small class="muted">Anda</small>` : html`<div class="acts"><button class="btn sm" data-role="${u.id}">Ubah peran</button><button class="btn sm ${u.status === 'suspended' ? '' : 'danger'}" data-st="${u.id}">${u.status === 'suspended' ? 'Aktifkan' : 'Tangguhkan'}</button></div>`) },
    ], rows, { empty: empty('Pengguna tidak ditemukan') })}`);
    on(res, 'click', '[data-role]', async (e, b) => {
      const u = rows.find((x) => x.id === b.dataset.role);
      if (await formDialog({ title: `Ubah peran ${u.name}`, fields: [{ name: 'role', label: 'Peran', type: 'select', options: [['player', 'Pemain'], ['owner', 'Pemilik Lapangan'], ['admin', 'Admin']], value: u.role }], onSubmit: async (x) => { await send('PATCH', `/admin/users/${u.id}`, { role: x.role }); toast('Peran diperbarui'); return true; } })) load();
    });
    on(res, 'click', '[data-st]', async (e, b) => {
      const u = rows.find((x) => x.id === b.dataset.st), sus = u.status !== 'suspended';
      if (!(await confirmDialog({ title: sus ? 'Tangguhkan akun?' : 'Aktifkan akun?', message: sus ? `${u.name} tidak akan bisa masuk sampai diaktifkan kembali.` : `${u.name} dapat masuk kembali.`, confirmText: sus ? 'Tangguhkan' : 'Aktifkan', danger: sus }))) return;
      busy(b, async () => { await send('PATCH', `/admin/users/${u.id}`, { status: sus ? 'suspended' : 'active' }); toast(sus ? 'Akun ditangguhkan' : 'Akun diaktifkan'); load(); });
    });
  });
  $('#q', el).oninput = debounce(load, 300); $$('select', el).forEach((s) => { s.onchange = load; }); load();
}, { title: 'Pengguna' });

// ---------- Lapangan (moderasi) ----------
route('admin/courts', A, ({ el, query }) => {
  mount(el, html`${pageHead('Lapangan', 'Tinjau pengajuan, setujui, tolak, atau tangguhkan lapangan.')}
    <div class="toolbar"><select class="input" id="st" aria-label="Status"><option value="">Semua status</option>${[['pending', 'Menunggu'], ['approved', 'Disetujui'], ['rejected', 'Ditolak'], ['suspended', 'Ditangguhkan']].map(([v, l]) => html`<option value="${v}" ${raw(query.status === v ? 'selected' : '')}>${l}</option>`)}</select></div><section class="card" id="res"></section>`);
  const res = $('#res', el), ORDER = { pending: 0, rejected: 1, suspended: 2, approved: 3 };
  const load = () => loadInto(res, async () => {
    const rows = (await get('/admin/courts', { status: $('#st', el).value })).data.sort((a, b) => ORDER[a.status] - ORDER[b.status] || a.name.localeCompare(b.name));
    mount(res, table([
      { h: 'Lapangan', cell: (c) => html`<div class="cell-user"><img class="avatar" style="border-radius:8px;width:44px;height:34px" src="${imgUrl(c)}" alt=""><div><b>${c.name}</b><small>${c.venue} · ${c.area}</small></div></div>` },
      { h: 'Pemilik', cell: (c) => c.ownerName || html`<span class="muted">Ace Padel</span>` }, { h: 'Harga', cls: 'r num', cell: (c) => rupiah(c.pricePerHour) + '/jam' }, { h: 'Status', cell: (c) => statusBadge(c.status) },
      { h: '', cls: 'r', cell: (c) => html`<div class="acts">${c.status !== 'approved' ? html`<button class="btn sm primary" data-a="approved" data-id="${c.id}">Setujui</button>` : ''}${c.status === 'pending' ? html`<button class="btn sm" data-a="rejected" data-id="${c.id}">Tolak</button>` : ''}${c.status === 'approved' ? html`<button class="btn sm" data-a="suspended" data-id="${c.id}">Tangguhkan</button>` : ''}<button class="btn sm danger icon" data-del="${c.id}" aria-label="Hapus ${c.name}">${icon('trash')}</button></div>` },
    ], rows, { empty: empty('Tidak ada lapangan', 'Tidak ada lapangan dengan status ini.') }));
    on(res, 'click', '[data-a]', async (e, b) => {
      const c = rows.find((x) => x.id === b.dataset.id), a = b.dataset.a;
      if (a === 'approved') return busy(b, async () => { await send('PATCH', `/admin/courts/${c.id}/status`, { status: 'approved' }); toast(`${c.name} disetujui dan tampil publik`); load(); });
      const ok = await formDialog({ title: a === 'rejected' ? `Tolak ${c.name}` : `Tangguhkan ${c.name}`, desc: 'Alasan akan dikirim ke pemilik lapangan.', submitText: a === 'rejected' ? 'Tolak pengajuan' : 'Tangguhkan', danger: true, fields: [{ name: 'reason', label: 'Alasan', type: 'textarea', required: true, placeholder: 'Mis. Foto lapangan belum jelas' }], onSubmit: async (x) => { await send('PATCH', `/admin/courts/${c.id}/status`, { status: a, reason: x.reason }); toast(a === 'rejected' ? 'Pengajuan ditolak' : 'Lapangan ditangguhkan'); return true; } });
      if (ok) load();
    });
    on(res, 'click', '[data-del]', async (e, b) => {
      const c = rows.find((x) => x.id === b.dataset.del);
      if (!(await confirmDialog({ title: 'Hapus lapangan?', message: `"${c.name}" akan dihapus permanen beserta datanya. Tindakan ini tidak dapat dibatalkan.`, confirmText: 'Hapus permanen', danger: true }))) return;
      busy(b, async () => { await send('DELETE', `/admin/courts/${c.id}`); toast('Lapangan dihapus'); load(); });
    });
  });
  $('#st', el).onchange = load; load();
}, { title: 'Lapangan' });

route('admin/bookings', A, ({ el }) => {
  mount(el, pageHead('Booking', 'Seluruh reservasi di platform.'));
  const w = document.createElement('div'); w.style.marginTop = '20px'; el.append(w);
  bookingList({ el: w, courts: null, mode: 'owner', base: '/admin/bookings' });
}, { title: 'Booking' });

// ---------- Voucher ----------
const toDate = (s) => (s ? String(s).slice(0, 10) : '');
route('admin/vouchers', A, async ({ el }) => {
  const draw = async () => {
    const rows = (await get('/admin/vouchers')).data;
    mount(el, html`${pageHead('Voucher', 'Buat dan atur kode promo.', html`<button class="btn primary" id="add">${icon('plus')}Voucher baru</button>`)}<section class="card">${table([
      { h: 'Kode', cell: (v) => html`<b><code>${v.code}</code></b><br><small class="muted">${v.title}</small>` },
      { h: 'Diskon', cell: (v) => (v.percentage ? `${Math.round(v.percentage * 100)}%${v.maxDiscount ? ' (maks ' + rupiah(v.maxDiscount) + ')' : ''}` : rupiah(v.discountAmount)) }, { h: 'Min. belanja', cls: 'num', cell: (v) => rupiah(v.minSpend) },
      { h: 'Terpakai', cls: 'num', cell: (v) => `${v.usedCount}${v.usageLimit ? ' / ' + v.usageLimit : ''}` }, { h: 'Berlaku s/d', cell: (v) => (v.expiresAt ? dateId(toDate(v.expiresAt), { day: 'numeric', month: 'short', year: 'numeric' }) : 'Tanpa batas') },
      { h: 'Status', cell: (v) => (v.active ? badge('Aktif', 'ok') : badge('Nonaktif', 'muted')) },
      { h: '', cls: 'r', cell: (v) => html`<div class="acts"><button class="btn sm" data-tg="${v.code}">${v.active ? 'Nonaktifkan' : 'Aktifkan'}</button><button class="btn sm" data-ed="${v.code}">Batas</button><button class="btn sm danger icon" data-del="${v.code}" aria-label="Hapus ${v.code}">${icon('trash')}</button></div>` },
    ], rows, { empty: empty('Belum ada voucher') })}</section>`);
    $('#add', el).onclick = async () => {
      const ok = await formDialog({
        title: 'Voucher baru', wide: true, submitText: 'Buat voucher',
        fields: [{ name: 'code', label: 'Kode', required: true, placeholder: 'HEMAT20', hint: 'Huruf/angka' }, { name: 'title', label: 'Judul', required: true }, { name: 'description', label: 'Deskripsi', type: 'textarea' },
          { name: 'kind', label: 'Jenis diskon', type: 'select', options: [['nominal', 'Nominal (Rp)'], ['persen', 'Persentase (%)']] }, { name: 'value', label: 'Nilai diskon', type: 'number', required: true, min: 1, hint: 'Nominal dalam ribuan Rp (25 = Rp25.000) atau persen (20 = 20%)' },
          { name: 'maxDiscount', label: 'Maks. diskon (ribuan Rp)', type: 'number', min: 1, hint: 'Hanya untuk persentase' }, { name: 'minSpend', label: 'Min. belanja (ribuan Rp)', type: 'number', min: 0 }, { name: 'usageLimit', label: 'Batas pemakaian', type: 'number', min: 1 }, { name: 'expiresAt', label: 'Berlaku sampai', type: 'date' }],
        onSubmit: async (x) => {
          const body = { code: x.code, title: x.title, description: x.description, minSpend: x.minSpend || 0, usageLimit: x.usageLimit || undefined, expiresAt: x.expiresAt || undefined };
          if (x.kind === 'persen') { if (x.value > 100) throw new Error('Persentase maksimal 100'); body.percentage = x.value / 100; body.maxDiscount = x.maxDiscount || undefined; } else body.discountAmount = x.value;
          await send('POST', '/admin/vouchers', body); toast('Voucher dibuat'); return true;
        },
      });
      if (ok) draw();
    };
    on(el, 'click', '[data-tg]', (e, b) => { const v = rows.find((x) => x.code === b.dataset.tg); busy(b, async () => { await send('PATCH', `/admin/vouchers/${v.code}`, { active: !v.active }); toast(v.active ? 'Voucher dinonaktifkan' : 'Voucher diaktifkan'); draw(); }); });
    on(el, 'click', '[data-ed]', async (e, b) => {
      const v = rows.find((x) => x.code === b.dataset.ed);
      if (await formDialog({ title: `Atur ${v.code}`, fields: [{ name: 'usageLimit', label: 'Batas pemakaian', type: 'number', min: 1, value: v.usageLimit ?? '' }, { name: 'expiresAt', label: 'Berlaku sampai', type: 'date', value: toDate(v.expiresAt) }], onSubmit: async (x) => { await send('PATCH', `/admin/vouchers/${v.code}`, { usageLimit: x.usageLimit || undefined, expiresAt: x.expiresAt || undefined }); toast('Voucher diperbarui'); return true; } })) draw();
    });
    on(el, 'click', '[data-del]', async (e, b) => {
      if (!(await confirmDialog({ title: 'Hapus voucher?', message: `Voucher ${b.dataset.del} akan dihapus permanen.`, confirmText: 'Hapus', danger: true }))) return;
      busy(b, async () => { await send('DELETE', `/admin/vouchers/${b.dataset.del}`); toast('Voucher dihapus'); draw(); });
    });
  };
  await draw();
}, { title: 'Voucher' });

// ---------- Pelatih ----------
route('admin/coaches', A, async ({ el }) => {
  const draw = async () => {
    const rows = (await get('/admin/coaches')).data;
    const form = (c) => formDialog({
      title: c ? 'Ubah pelatih' : 'Tambah pelatih', wide: true, submitText: c ? 'Simpan' : 'Tambah', values: c || {},
      fields: [{ name: 'name', label: 'Nama', required: true }, { name: 'title', label: 'Gelar / jabatan' }, { name: 'ratePerHour', label: 'Tarif per jam (ribuan Rp)', type: 'number', required: true, min: 1 }, ...(c ? [] : [{ name: 'experience', label: 'Pengalaman' }]), { name: 'bio', label: 'Bio', type: 'textarea' }],
      onSubmit: async (x) => { await (c ? send('PATCH', `/admin/coaches/${c.id}`, x) : send('POST', '/admin/coaches', x)); toast(c ? 'Pelatih diperbarui' : 'Pelatih ditambahkan'); return true; },
    });
    mount(el, html`${pageHead('Pelatih', 'Daftar pelatih yang tampil di aplikasi.', html`<button class="btn primary" id="add">${icon('plus')}Tambah pelatih</button>`)}<section class="card">${table([
      { h: 'Pelatih', cell: (c) => userCell(c.name, c.title) }, { h: 'Tarif', cls: 'num', cell: (c) => rupiah(c.ratePerHour) + '/jam' }, { h: 'Rating', cell: (c) => `★ ${c.rating}` },
      { h: 'Status', cell: (c) => (c.active ? badge('Aktif', 'ok') : badge('Nonaktif', 'muted')) },
      { h: '', cls: 'r', cell: (c) => html`<div class="acts"><button class="btn sm" data-ed="${c.id}">${icon('edit')}Ubah</button><button class="btn sm" data-tg="${c.id}">${c.active ? 'Nonaktifkan' : 'Aktifkan'}</button></div>` },
    ], rows, { empty: empty('Belum ada pelatih') })}</section>`);
    $('#add', el).onclick = async () => { if (await form(null)) draw(); };
    on(el, 'click', '[data-ed]', async (e, b) => { if (await form(rows.find((c) => c.id === b.dataset.ed))) draw(); });
    on(el, 'click', '[data-tg]', (e, b) => { const c = rows.find((x) => x.id === b.dataset.tg); busy(b, async () => { await send('PATCH', `/admin/coaches/${c.id}`, { active: !c.active }); toast('Status pelatih diperbarui'); draw(); }); });
  };
  await draw();
}, { title: 'Pelatih' });

// ---------- Moderasi ----------
route('admin/moderation', A, async ({ el }) => {
  const courts = (await get('/courts')).data;
  let tab = 'matches', courtId = courts[0]?.id;
  mount(el, html`${pageHead('Moderasi', 'Hapus konten yang melanggar aturan.')}<div class="tabs" role="tablist"><button role="tab" data-t="matches" aria-selected="true">Mabar</button><button role="tab" data-t="reviews" aria-selected="false">Ulasan</button></div><div id="tb"></div>`);
  const tb = $('#tb', el);
  const draw = () => loadInto(tb, async () => {
    if (tab === 'matches') {
      const rows = (await get('/matches')).data;
      mount(tb, html`<section class="card" style="margin-top:16px">${table([{ h: 'Mabar', cell: (m) => html`<b>${m.title}</b><br><small class="muted">${m.court?.name || m.courtId} · ${m.dateString} ${m.time}</small>` }, { h: 'Host', cell: (m) => m.hostName }, { h: 'Pemain', cls: 'num', cell: (m) => `${m.currentPlayers}/${m.maxPlayers}` },
        { h: '', cls: 'r', cell: (m) => html`<button class="btn sm danger" data-dm="${m.id}">${icon('trash')}Hapus</button>` }], rows, { empty: empty('Tidak ada mabar aktif') })}</section>`);
      on(tb, 'click', '[data-dm]', async (e, b) => { if (!(await confirmDialog({ title: 'Hapus mabar?', message: 'Mabar akan dihapus untuk semua peserta.', confirmText: 'Hapus', danger: true }))) return; busy(b, async () => { await send('DELETE', `/admin/matches/${b.dataset.dm}`); toast('Mabar dihapus'); draw(); }); });
    } else {
      const rows = courtId ? (await get(`/reviews/${courtId}`)).data : [];
      mount(tb, html`<div class="toolbar" style="margin-top:16px"><select class="input" id="cs" aria-label="Lapangan" style="max-width:420px">${courts.map((c) => html`<option value="${c.id}" ${raw(c.id === courtId ? 'selected' : '')}>${c.name} — ${c.venue}</option>`)}</select></div>
        <section class="card">${table([{ h: 'Ulasan', cell: (r) => html`<b>${r.userName}</b> <span class="stars">${'★'.repeat(Math.round(r.rating))}</span><br><small>${r.comment}</small>` }, { h: 'Tanggal', cell: (r) => dateTimeId(r.createdAt) },
        { h: '', cls: 'r', cell: (r) => html`<button class="btn sm danger" data-dr="${r.id}">${icon('trash')}Hapus</button>` }], rows, { empty: empty('Belum ada ulasan', 'Lapangan ini belum memiliki ulasan.') })}</section>`);
      $('#cs', tb).onchange = (e) => { courtId = e.target.value; draw(); };
      on(tb, 'click', '[data-dr]', async (e, b) => { if (!(await confirmDialog({ title: 'Hapus ulasan?', message: 'Rating lapangan akan dihitung ulang.', confirmText: 'Hapus', danger: true }))) return; busy(b, async () => { await send('DELETE', `/admin/reviews/${b.dataset.dr}`); toast('Ulasan dihapus'); draw(); }); });
    }
  });
  on(el, 'click', '[data-t]', (e, b) => { tab = b.dataset.t; $$('[data-t]', el).forEach((x) => x.setAttribute('aria-selected', x === b)); draw(); });
  draw();
}, { title: 'Moderasi' });

route('admin/settings', A, settingsView, { title: 'Pengaturan' });
