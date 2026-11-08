import { api, get, send } from '../api.js';
import { state } from '../router.js';
import { $, html, raw, mount, icon, on, busy, toast, openModal, confirmDialog, formDialog, statusBadge, badge, rupiah, dateId, dateTimeId, pageHead, stat, avatar, skeleton } from '../ui.js';
import { qrSvg } from '../qr.js';

export const ticketHtml = (b) => html`<div class="ticket">${raw(qrSvg(b.id, 168))}<code>${b.id}</code><small class="muted">Tunjukkan kode ini saat check-in</small></div>`;

// Drawer detail booking untuk pemilik/admin ('owner') dan pemain ('player'). onChange dipanggil setelah aksi sukses.
export function bookingDrawer(b, mode, onChange) {
  const blocked = b.status === 'Maintenance', court = b.court || {};
  const kv = (k, v) => (v == null || v === '' ? '' : html`<dt>${k}</dt><dd>${v}</dd>`);
  const m = openModal({
    title: blocked ? 'Slot diblokir' : 'Detail booking', side: true,
    body: html`${blocked ? '' : ticketHtml(b)}<dl class="kv">
      ${kv('Status', statusBadge(b.status))}${blocked ? '' : kv('Pembayaran', statusBadge(b.paymentStatus))}
      ${kv(blocked ? 'Dibuat oleh' : 'Pemain', b.userName)}${kv('Lapangan', court.name ? `${court.name} · ${court.venue}` : b.courtId)}
      ${kv('Tanggal', dateId(b.date))}${kv('Jam', b.slot + ' WIB')}
      ${blocked ? kv('Alasan', b.note) : html`${kv('Harga sewa', rupiah(b.pricePerHour))}${b.discount ? kv('Diskon' + (b.voucherCode ? ` (${b.voucherCode})` : ''), '− ' + rupiah(b.discount)) : ''}${b.addOnsTotal ? kv('Add-on', (b.addOns || []).map((a) => a.name || a).join(', ') + ' · ' + rupiah(b.addOnsTotal)) : ''}${kv('Total', raw('<b>' + rupiah(b.finalPrice) + '</b>'))}${kv('Metode', b.paymentMethod)}${kv('Ref. bayar', b.paymentRef)}${kv('Catatan', b.note)}`}
      ${kv('Dibuat', dateTimeId(b.createdAt))}${kv('Check-in', b.checkedInAt ? dateTimeId(b.checkedInAt) : '')}</dl>`,
    footer: b.status === 'Terkonfirmasi' || blocked ? html`${mode === 'owner' ? html`${b.paymentStatus !== 'Lunas' && !blocked ? html`<button class="btn" data-a="paid">Tandai lunas</button>` : ''}${!blocked ? html`<button class="btn lime" data-a="checkin">Check-in</button>` : ''}` : (b.paymentStatus === 'Menunggu' ? html`<button class="btn lime" data-a="pay">Bayar sekarang</button>` : '')}<button class="btn danger" data-a="cancel">${blocked ? 'Buka blokir' : 'Batalkan'}</button>` : '',
  });
  const run = (btn, fn, msg) => busy(btn, async () => { await fn(); toast(msg); m.close(); onChange?.(); });
  on(m.el, 'click', '[data-a]', async (e, btn) => {
    const a = btn.dataset.a;
    if (a === 'paid') run(btn, () => send('POST', `/owner/bookings/${b.id}/mark-paid`), 'Pembayaran ditandai lunas');
    if (a === 'checkin') run(btn, () => send('POST', '/owner/check-in', { bookingId: b.id }), 'Check-in berhasil (+50 poin pemain)');
    if (a === 'pay') run(btn, () => send('POST', `/bookings/${b.id}/pay`), 'Pembayaran berhasil');
    if (a === 'cancel') {
      if (!(await confirmDialog({ title: blocked ? 'Buka blokir slot?' : 'Batalkan booking?', message: blocked ? 'Slot akan tersedia kembali.' : 'Booking yang dibatalkan tidak dapat dipulihkan.', confirmText: blocked ? 'Buka blokir' : 'Ya, batalkan', danger: !blocked }))) return;
      run(btn, () => (blocked ? send('POST', '/owner/toggle-slot', { courtId: b.courtId, date: b.date, slot: b.slot, action: 'unblock' }) : mode === 'owner' ? send('POST', `/owner/bookings/${b.id}/cancel`) : send('DELETE', `/bookings/${b.id}`)), blocked ? 'Blokir dibuka' : 'Booking dibatalkan');
    }
  });
  return m;
}

const SKILLS = ['Pemula (Beginner)', 'Menengah (Intermediate)', 'Mahir (Advanced)', 'Profesional'];
const HANDS = ['Tangan Kanan (Right-handed)', 'Tangan Kiri (Left-handed)'];
export async function settingsView({ el }) {
  const u = (await get('/auth/me')).data, player = u.role === 'player';
  let st = null; if (player) { try { st = (await get('/me/stats')).data; } catch { /* opsional */ } }
  mount(el, html`${pageHead(player ? 'Profil' : 'Pengaturan akun', u.email)}
    ${st ? html`<div class="grid g4"><div class="card stat"><div class="stat-label muted">Poin</div><div class="stat-val">${st.points}</div></div><div class="card stat"><div class="stat-label muted">Peringkat</div><div class="stat-val">#${st.rank ?? '-'}</div></div><div class="card stat"><div class="stat-label muted">Menang / Main</div><div class="stat-val">${st.wins}/${st.matches}</div></div><div class="card stat"><div class="stat-label muted">Jam bermain</div><div class="stat-val">${st.hoursPlayed}</div></div></div>` : ''}
    <div class="grid g2">
      <form class="card" id="pf" novalidate><div class="card-h"><h3>Data diri</h3>${avatar(u)}</div><div class="card-b"><div class="formgrid">
        <div class="field"><label for="n">Nama</label><input class="input" id="n" name="name" value="${u.name}" required></div>
        <div class="field"><label for="p">No. HP</label><input class="input" id="p" name="phone" value="${u.phone || ''}" type="tel"></div>
        ${player ? html`<div class="field"><label for="s">Level</label><select class="input" id="s" name="skillLevel">${[...new Set([...SKILLS, u.skillLevel].filter(Boolean))].map((s) => html`<option ${raw(s === u.skillLevel ? 'selected' : '')}>${s}</option>`)}</select></div>
        <div class="field"><label for="h">Tangan dominan</label><select class="input" id="h" name="preferredHand">${[...new Set([...HANDS, u.preferredHand].filter(Boolean))].map((s) => html`<option ${raw(s === u.preferredHand ? 'selected' : '')}>${s}</option>`)}</select></div>` : ''}
      </div><p class="form-err" role="alert" hidden></p><div style="margin-top:16px"><button class="btn primary" type="submit">Simpan perubahan</button></div></div></form>
      <form class="card" id="wf" novalidate><div class="card-h"><h3>Ganti kata sandi</h3>${icon('lock')}</div><div class="card-b"><div class="formgrid">
        <div class="field"><label for="cp">Kata sandi saat ini</label><input class="input" id="cp" name="cur" type="password" required autocomplete="current-password"></div>
        <div class="field"><label for="np">Kata sandi baru</label><input class="input" id="np" name="nw" type="password" required minlength="8" autocomplete="new-password"><small>Minimal 8 karakter.</small></div>
      </div><p class="form-err" role="alert" hidden></p><div style="margin-top:16px"><button class="btn" type="submit">Perbarui kata sandi</button></div></div></form>
    </div>`);
  const wire = (form, fn) => form.addEventListener('submit', (e) => {
    e.preventDefault(); const err = $('.form-err', form); err.hidden = true;
    if (!form.checkValidity()) return form.reportValidity();
    busy($('button[type=submit]', form), async () => { try { await fn(form); } catch (x) { err.textContent = x.message; err.hidden = false; } });
  });
  wire($('#pf', el), async (f) => {
    const body = { name: f.name.value.trim(), phone: f.phone.value.trim() };
    if (player) { body.skillLevel = f.skillLevel.value; body.preferredHand = f.preferredHand.value; }
    state.user = (await send('PUT', '/auth/me', body)).data; toast('Profil diperbarui');
  });
  wire($('#wf', el), async (f) => { await send('PUT', '/auth/password', { currentPassword: f.cur.value, newPassword: f.nw.value }); f.reset(); toast('Kata sandi diperbarui'); });
}

export const BOOK_STATUS = [['', 'Semua status'], ['Terkonfirmasi', 'Terkonfirmasi'], ['Check-in Selesai', 'Check-in selesai'], ['Dibatalkan', 'Dibatalkan'], ['Maintenance', 'Diblokir']];
export const userCell = (name, sub) => html`<div class="cell-user">${avatar({ name })}<div><b>${name}</b><small>${sub}</small></div></div>`;
