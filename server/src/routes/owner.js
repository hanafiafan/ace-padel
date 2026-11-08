// Panel pemilik lapangan. Admin juga boleh memakai semua endpoint ini (akses ke semua lapangan).
const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { db, tx } = require('../db');
const U = require('../lib/util');
const { cancelBooking } = require('./player');
const { ok, bad, forbid, notFound, conflict, auth, role, notify, ALL_SLOTS, str } = U;

const r = express.Router();
r.use(auth(), role('owner', 'admin'));

const isAdmin = (req) => req.user.role === 'admin';
const scope = (req) => (isAdmin(req) ? { sql: '1=1', args: [] } : { sql: 'c.owner_id = ?', args: [req.user.id] });

function ownCourt(req, id) {
  const c = db.prepare('SELECT * FROM courts WHERE id = ?').get(id);
  if (!c) throw notFound('Lapangan tidak ditemukan');
  if (!isAdmin(req) && c.owner_id !== req.user.id) throw forbid('Lapangan ini bukan milik Anda');
  return c;
}
const findBooking = (req, id) => {
  const b = db.prepare(`${U.BOOKING_SELECT} WHERE UPPER(b.id) = UPPER(?)`).get(String(id || '').trim());
  if (!b) return null;
  if (!isAdmin(req) && b.c_owner !== req.user.id) throw forbid('Tiket ini bukan untuk lapangan Anda');
  return b;
};

// ---- Lapangan ----
r.get('/courts', (req, res) => {
  const s = scope(req);
  ok(res, db.prepare(`SELECT c.* FROM courts c WHERE ${s.sql} ORDER BY c.created_at DESC, c.id`).all(...s.args).map(U.court));
});

function courtInput(body, partial = false) {
  const out = {};
  const set = (k, v) => { out[k] = v; };
  if (!partial || body.name !== undefined) set('name', str(body.name, 'Nama lapangan', { max: 100 }));
  if (!partial || body.venue !== undefined) set('venue', str(body.venue, 'Nama venue', { max: 100 }));
  if (!partial || body.area !== undefined) set('area', str(body.area, 'Area (contoh: Kemang, Jakarta)', { max: 100 }));
  if (!partial || body.pricePerHour !== undefined) {
    const p = parseInt(body.pricePerHour, 10);
    if (!(p > 0 && p < 100000)) throw bad('Harga per jam (ribuan Rupiah) tidak valid');
    set('price_per_hour', p);
  }
  if (body.indoor !== undefined) set('indoor', body.indoor ? 1 : 0);
  if (body.facilities !== undefined) set('facilities', JSON.stringify((Array.isArray(body.facilities) ? body.facilities : []).map(String).slice(0, 20)));
  if (body.description !== undefined) set('description', String(body.description).slice(0, 1000));
  if (body.image !== undefined) set('image', String(body.image).slice(0, 300));
  return out;
}

r.post('/courts', (req, res) => {
  const f = courtInput(req.body);
  const id = `c_${crypto.randomUUID().slice(0, 8)}`;
  const row = { id, owner_id: req.user.id, indoor: 1, facilities: '[]', description: '', rating: 0, ...f, status: isAdmin(req) ? 'approved' : 'pending', created_at: new Date().toISOString() };
  db.prepare(`INSERT INTO courts (${Object.keys(row)}) VALUES (${Object.keys(row).map(() => '?')})`).run(...Object.values(row));
  if (!isAdmin(req)) {
    db.prepare("SELECT id FROM users WHERE role = 'admin'").all().forEach((a) => notify(a.id, 'Pengajuan lapangan baru', `${f.venue} — ${f.name} menunggu persetujuan`, 'admin'));
  }
  ok(res, U.court(db.prepare('SELECT * FROM courts WHERE id = ?').get(id)), { message: isAdmin(req) ? 'Lapangan ditambahkan' : 'Lapangan diajukan, menunggu persetujuan admin' }, 201);
});

r.put('/courts/:id', (req, res) => {
  const c = ownCourt(req, req.params.id);
  const f = courtInput(req.body, true);
  if (!isAdmin(req) && c.status === 'rejected') f.status = 'pending'; // ajukan ulang
  const keys = Object.keys(f);
  if (keys.length) db.prepare(`UPDATE courts SET ${keys.map((k) => `${k} = ?`)} WHERE id = ?`).run(...Object.values(f), c.id);
  ok(res, U.court(db.prepare('SELECT * FROM courts WHERE id = ?').get(c.id)), { message: 'Lapangan diperbarui' });
});

// Upload foto (data URL base64, maks 3MB) → /uploads/<file>
r.post('/uploads', (req, res) => {
  const m = /^data:image\/(png|jpeg|webp);base64,(.+)$/.exec(String(req.body.dataUrl || ''));
  if (!m) throw bad('dataUrl harus berupa gambar png/jpeg/webp base64');
  const buf = Buffer.from(m[2], 'base64');
  if (buf.length > 3 * 1024 * 1024) throw bad('Ukuran gambar maksimal 3MB');
  const dir = path.join(__dirname, '../../data/uploads');
  fs.mkdirSync(dir, { recursive: true });
  const name = `${crypto.randomUUID()}.${m[1] === 'jpeg' ? 'jpg' : m[1]}`;
  fs.writeFileSync(path.join(dir, name), buf);
  ok(res, { url: `/uploads/${name}` }, {}, 201);
});

// ---- Booking & jadwal ----
r.get('/bookings', (req, res) => {
  const s = scope(req);
  const w = [s.sql], a = [...s.args];
  const { courtId, date, from, to, status, q } = req.query;
  if (courtId) { w.push('b.court_id = ?'); a.push(courtId); }
  if (date) { w.push('b.date = ?'); a.push(date); }
  if (from) { w.push('b.date >= ?'); a.push(from); }
  if (to) { w.push('b.date <= ?'); a.push(to); }
  if (status) { w.push('b.status = ?'); a.push(status); }
  if (q) { w.push('(b.id LIKE ? OR u.name LIKE ?)'); a.push(`%${q}%`, `%${q}%`); }
  const rows = db.prepare(`${U.BOOKING_SELECT} WHERE ${w.join(' AND ')} ORDER BY b.date DESC, b.slot DESC LIMIT 500`).all(...a).map(U.booking);
  ok(res, rows, { count: rows.length });
});

r.get('/schedule', (req, res) => {
  const c = ownCourt(req, req.query.courtId);
  if (!U.isDate(req.query.date)) throw bad('date (YYYY-MM-DD) wajib');
  const rows = db.prepare(`${U.BOOKING_SELECT} WHERE b.court_id = ? AND b.date = ? AND b.status != 'Dibatalkan'`).all(c.id, req.query.date).map(U.booking);
  ok(res, ALL_SLOTS.map((slot) => ({ slot, booking: rows.find((b) => b.slot === slot) || null })));
});

r.post('/verify-ticket', (req, res) => {
  const b = findBooking(req, req.body.bookingId);
  if (!b) return res.status(404).json({ success: false, valid: false, message: 'Kode tiket tidak ditemukan dalam sistem.' });
  const valid = b.status === 'Terkonfirmasi' && b.payment_status !== 'Menunggu' && b.date === U.today();
  const message = b.status === 'Dibatalkan' ? 'Tiket ini telah DIBATALKAN.'
    : b.status === 'Check-in Selesai' ? 'Tiket sudah dipakai check-in.'
    : b.date !== U.today() ? `Tiket berlaku untuk tanggal ${b.date}.`
    : b.payment_status === 'Menunggu' ? 'Pembayaran online belum diterima.' : 'Tiket valid dan terkonfirmasi.';
  res.status(valid ? 200 : 400).json({ success: valid, valid, message, data: U.booking(b) });
});

r.post('/check-in', (req, res) => {
  const b = findBooking(req, req.body.bookingId);
  if (!b) throw notFound('Reservasi tidak ditemukan');
  if (b.status !== 'Terkonfirmasi') throw bad(`Booking berstatus "${b.status}" tidak bisa check-in`);
  if (b.payment_status === 'Menunggu') throw bad('Pembayaran online belum diterima');
  if (b.date !== U.today()) throw bad(`Tiket ini untuk tanggal ${b.date}`);
  tx(() => {
    db.prepare("UPDATE bookings SET status = 'Check-in Selesai', checked_in_at = ?, payment_status = CASE WHEN payment_status = 'Belum Bayar' THEN 'Lunas' ELSE payment_status END WHERE id = ?")
      .run(new Date().toISOString(), b.id);
    if (b.user_id) db.prepare('UPDATE users SET points = points + 50, matches = matches + 1 WHERE id = ?').run(b.user_id);
  });
  notify(b.user_id, 'Check-in berhasil', `Selamat bermain di ${b.c_venue}! +50 poin`, 'booking');
  ok(res, U.booking(findBooking(req, b.id)), { message: `Pemain ${b.user_name || 'tamu'} berhasil check-in. Selamat bermain!` });
});

r.post('/bookings/:id/cancel', (req, res) => {
  findBooking(req, req.params.id) || (() => { throw notFound('Booking tidak ditemukan'); })();
  ok(res, cancelBooking(req.params.id, req.user, { asStaff: true }), { message: 'Booking dibatalkan' });
});

r.post('/bookings/:id/mark-paid', (req, res) => {
  const b = findBooking(req, req.params.id);
  if (!b) throw notFound('Booking tidak ditemukan');
  if (b.status === 'Dibatalkan') throw bad('Booking sudah dibatalkan');
  db.prepare("UPDATE bookings SET payment_status = 'Lunas' WHERE id = ?").run(b.id);
  ok(res, U.booking(findBooking(req, b.id)), { message: 'Ditandai lunas' });
});

// Booking walk-in oleh kasir/pengelola
r.post('/manual-booking', (req, res) => {
  const { courtId, date, slot, customerName } = req.body;
  const c = ownCourt(req, courtId);
  U.validateSlotDate(date, slot);
  const id = `ACE-${c.id.toUpperCase()}-${slot.replace(':', '')}-${crypto.randomInt(1000, 10000)}`;
  try {
    db.prepare(`INSERT INTO bookings (id,court_id,user_id,date,slot,price,final_price,payment_method,payment_status,note,created_at)
      VALUES (?,?,NULL,?,?,?,?,?,'Lunas',?,?)`).run(id, c.id, date, slot, c.price_per_hour, c.price_per_hour, 'Bayar di tempat', `Walk-in: ${String(customerName || 'Tamu').slice(0, 80)}`, new Date().toISOString());
  } catch (e) {
    if (/UNIQUE/.test(e.message)) throw conflict('Slot sudah terisi');
    throw e;
  }
  ok(res, U.booking(findBooking(req, id)), { message: 'Booking walk-in dibuat' }, 201);
});

r.post('/toggle-slot', (req, res) => {
  const { courtId, date, slot, action = 'block', reason = 'Perawatan Rutin Lapangan' } = req.body;
  const c = ownCourt(req, courtId);
  if (!U.isDate(date) || !ALL_SLOTS.includes(slot)) throw bad('date/slot tidak valid');
  if (action === 'block') {
    try {
      db.prepare(`INSERT INTO bookings (id,court_id,user_id,date,slot,payment_method,payment_status,status,note,created_at)
        VALUES (?,?,NULL,?,?,'Khusus Pengelola','Belum Bayar','Maintenance',?,?)`)
        .run(`MAINT-${c.id.toUpperCase()}-${date}-${slot.replace(':', '')}`, c.id, date, slot, String(reason).slice(0, 120), new Date().toISOString());
    } catch (e) {
      if (/UNIQUE|PRIMARY/.test(e.message)) throw conflict('Slot ini sudah terisi booking atau sudah diblokir');
      throw e;
    }
    return ok(res, null, { message: `Slot ${slot} pada ${date} diblokir (${reason}).` });
  }
  const n = db.prepare("DELETE FROM bookings WHERE court_id = ? AND date = ? AND slot = ? AND status = 'Maintenance'").run(c.id, date, slot).changes;
  if (!n) throw notFound('Slot maintenance tidak ditemukan');
  ok(res, null, { message: `Slot ${slot} pada ${date} dibuka kembali.` });
});

// ---- Statistik dashboard ----
r.get('/stats', (req, res) => {
  const s = scope(req);
  const days = Math.min(Math.max(parseInt(req.query.days, 10) || 14, 1), 90);
  const t = U.today();
  const from = new Date(Date.parse(t) - (days - 1) * 86400000).toISOString().slice(0, 10);
  const live = "b.status IN ('Terkonfirmasi','Check-in Selesai')";
  const courtCount = db.prepare(`SELECT COUNT(*) n FROM courts c WHERE ${s.sql} AND c.status = 'approved'`).get(...s.args).n;
  const one = (extra, ...a) => db.prepare(`SELECT COUNT(*) n, COALESCE(SUM(b.final_price),0) rev FROM bookings b JOIN courts c ON c.id = b.court_id WHERE ${s.sql} AND ${extra}`).get(...s.args, ...a);
  const today = one(`${live} AND b.date = ?`, t);
  const series = db.prepare(`SELECT b.date, COUNT(*) bookings, SUM(b.final_price) revenue FROM bookings b JOIN courts c ON c.id = b.court_id WHERE ${s.sql} AND ${live} AND b.date BETWEEN ? AND ? GROUP BY b.date`).all(...s.args, from, t);
  const byDate = new Map(series.map((x) => [x.date, x]));
  const daily = Array.from({ length: days }, (_, i) => {
    const d = new Date(Date.parse(from) + i * 86400000).toISOString().slice(0, 10);
    return { date: d, bookings: byDate.get(d)?.bookings || 0, revenue: byDate.get(d)?.revenue || 0 };
  });
  const perCourt = db.prepare(`SELECT c.id, c.name, c.venue, COUNT(b.id) bookings, COALESCE(SUM(b.final_price),0) revenue FROM courts c LEFT JOIN bookings b ON b.court_id = c.id AND ${live} AND b.date BETWEEN ? AND ? WHERE ${s.sql} GROUP BY c.id ORDER BY revenue DESC`).all(from, t, ...s.args);
  const total = one(`${live} AND b.date BETWEEN ? AND ?`, from, t);
  ok(res, {
    days, courts: courtCount,
    today: { bookings: today.n, revenue: today.rev, checkedIn: one("b.status = 'Check-in Selesai' AND b.date = ?", t).n, occupancy: courtCount ? Math.round((today.n / (courtCount * ALL_SLOTS.length)) * 100) : 0 },
    period: { bookings: total.n, revenue: total.rev, cancelled: one("b.status = 'Dibatalkan' AND b.date BETWEEN ? AND ?", from, t).n, pendingPayment: one("b.payment_status = 'Menunggu' AND b.status = 'Terkonfirmasi'").n },
    daily, perCourt,
    upcoming: db.prepare(`${U.BOOKING_SELECT} WHERE ${s.sql} AND b.status = 'Terkonfirmasi' AND b.date >= ? ORDER BY b.date, b.slot LIMIT 8`).all(...s.args, t).map(U.booking),
  });
});

r.get('/reviews', (req, res) => {
  const s = scope(req);
  ok(res, db.prepare(`SELECT r.*, u.name user_name, c.name court_name, c.venue FROM reviews r JOIN courts c ON c.id = r.court_id JOIN users u ON u.id = r.user_id WHERE ${s.sql} ORDER BY r.created_at DESC LIMIT 100`).all(...s.args)
    .map((x) => ({ id: x.id, courtName: x.court_name, venue: x.venue, userName: x.user_name, rating: x.rating, comment: x.comment, createdAt: x.created_at })));
});

module.exports = r;
