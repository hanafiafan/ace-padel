// Panel superadmin
const express = require('express');
const { db } = require('../db');
const U = require('../lib/util');
const { ok, bad, notFound, conflict, auth, role, notify, str } = U;

const r = express.Router();
r.use(auth(), role('admin'));

const n = (sql, ...a) => db.prepare(sql).get(...a).n;
const LIVE = "status IN ('Terkonfirmasi','Check-in Selesai')";

r.get('/overview', (req, res) => {
  const t = U.today();
  const days = 14;
  const from = new Date(Date.parse(t) - (days - 1) * 86400000).toISOString().slice(0, 10);
  const series = new Map(db.prepare(`SELECT date, COUNT(*) bookings, SUM(final_price) revenue FROM bookings WHERE ${LIVE} AND date BETWEEN ? AND ? GROUP BY date`).all(from, t).map((x) => [x.date, x]));
  ok(res, {
    users: { total: n('SELECT COUNT(*) n FROM users'), players: n("SELECT COUNT(*) n FROM users WHERE role='player'"), owners: n("SELECT COUNT(*) n FROM users WHERE role='owner'"), suspended: n("SELECT COUNT(*) n FROM users WHERE status='suspended'") },
    courts: { total: n('SELECT COUNT(*) n FROM courts'), approved: n("SELECT COUNT(*) n FROM courts WHERE status='approved'"), pending: n("SELECT COUNT(*) n FROM courts WHERE status='pending'"), venues: n("SELECT COUNT(DISTINCT venue) n FROM courts WHERE status='approved'") },
    bookings: { total: n("SELECT COUNT(*) n FROM bookings WHERE status != 'Maintenance'"), active: n("SELECT COUNT(*) n FROM bookings WHERE status='Terkonfirmasi'"), checkedIn: n("SELECT COUNT(*) n FROM bookings WHERE status='Check-in Selesai'"), cancelled: n("SELECT COUNT(*) n FROM bookings WHERE status='Dibatalkan'"), today: n(`SELECT COUNT(*) n FROM bookings WHERE ${LIVE} AND date = ?`, t) },
    revenue: { total: n(`SELECT COALESCE(SUM(final_price),0) n FROM bookings WHERE ${LIVE}`), paid: n("SELECT COALESCE(SUM(final_price),0) n FROM bookings WHERE payment_status='Lunas' AND status != 'Dibatalkan'"), last14: [...series.values()].reduce((s, x) => s + x.revenue, 0) },
    daily: Array.from({ length: days }, (_, i) => { const d = new Date(Date.parse(from) + i * 86400000).toISOString().slice(0, 10); return { date: d, bookings: series.get(d)?.bookings || 0, revenue: series.get(d)?.revenue || 0 }; }),
    topVenues: db.prepare(`SELECT c.venue, COUNT(b.id) bookings, COALESCE(SUM(b.final_price),0) revenue FROM courts c LEFT JOIN bookings b ON b.court_id = c.id AND b.${LIVE} GROUP BY c.venue ORDER BY revenue DESC LIMIT 6`).all(),
    recent: db.prepare(`${U.BOOKING_SELECT} WHERE b.status != 'Maintenance' ORDER BY b.created_at DESC LIMIT 8`).all().map(U.booking),
  });
});

// ---- Pengguna ----
r.get('/users', (req, res) => {
  const { q, role: rl, status } = req.query;
  const w = ['1=1'], a = [];
  if (q) { w.push('(name LIKE ? OR email LIKE ?)'); a.push(`%${q}%`, `%${q}%`); }
  if (rl) { w.push('role = ?'); a.push(rl); }
  if (status) { w.push('status = ?'); a.push(status); }
  ok(res, db.prepare(`SELECT * FROM users WHERE ${w.join(' AND ')} ORDER BY created_at DESC LIMIT 500`).all(...a).map(U.publicUser));
});
r.patch('/users/:id', (req, res) => {
  const u = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!u) throw notFound('Pengguna tidak ditemukan');
  const { role: newRole, status } = req.body;
  if (u.id === req.user.id && (newRole || status === 'suspended')) throw bad('Tidak bisa mengubah peran/menangguhkan akun sendiri');
  if (newRole && !['player', 'owner', 'admin'].includes(newRole)) throw bad('Peran tidak valid');
  if (status && !['active', 'suspended'].includes(status)) throw bad('Status tidak valid');
  db.prepare('UPDATE users SET role = COALESCE(?, role), status = COALESCE(?, status) WHERE id = ?').run(newRole || null, status || null, u.id);
  ok(res, U.publicUser(db.prepare('SELECT * FROM users WHERE id = ?').get(u.id)), { message: 'Pengguna diperbarui' });
});

// ---- Lapangan: moderasi & CRUD ----
r.get('/courts', (req, res) => {
  const w = req.query.status ? 'WHERE c.status = ?' : '';
  ok(res, db.prepare(`SELECT c.*, o.name owner_name, o.email owner_email FROM courts c LEFT JOIN users o ON o.id = c.owner_id ${w} ORDER BY CASE c.status WHEN 'pending' THEN 0 ELSE 1 END, c.created_at DESC`)
    .all(...(req.query.status ? [req.query.status] : [])).map((c) => ({ ...U.court(c), ownerName: c.owner_name, ownerEmail: c.owner_email })));
});
r.patch('/courts/:id/status', (req, res) => {
  const { status, reason } = req.body;
  if (!['approved', 'rejected', 'suspended', 'pending'].includes(status)) throw bad('Status tidak valid');
  const c = db.prepare('SELECT * FROM courts WHERE id = ?').get(req.params.id);
  if (!c) throw notFound('Lapangan tidak ditemukan');
  db.prepare('UPDATE courts SET status = ? WHERE id = ?').run(status, c.id);
  const msg = { approved: 'disetujui dan kini tampil di aplikasi', rejected: `ditolak${reason ? `: ${reason}` : ''}`, suspended: 'ditangguhkan', pending: 'dikembalikan ke antrean' }[status];
  notify(c.owner_id, `Lapangan ${msg.split(' ')[0]}`, `${c.venue} — ${c.name} ${msg}`, 'admin');
  ok(res, null, { message: `Lapangan ${msg}` });
});
r.delete('/courts/:id', (req, res) => {
  if (n("SELECT COUNT(*) n FROM bookings WHERE court_id = ? AND status = 'Terkonfirmasi'", req.params.id)) throw conflict('Masih ada booking aktif. Tangguhkan lapangan saja.');
  try { db.prepare('DELETE FROM courts WHERE id = ?').run(req.params.id); } catch { throw conflict('Lapangan punya riwayat transaksi. Tangguhkan saja.'); }
  ok(res, null, { message: 'Lapangan dihapus' });
});

// ---- Voucher ----
const vrow = (v) => ({ code: v.code, title: v.title, description: v.description, discountAmount: v.discount_amount, percentage: v.percentage, maxDiscount: v.max_discount, minSpend: v.min_spend, active: !!v.active, usageLimit: v.usage_limit, usedCount: v.used_count, expiresAt: v.expires_at });
r.get('/vouchers', (req, res) => ok(res, db.prepare('SELECT * FROM vouchers ORDER BY code').all().map(vrow)));
r.post('/vouchers', (req, res) => {
  const b = req.body;
  const code = str(b.code, 'Kode', { max: 30 }).toUpperCase();
  if (!/^[A-Z0-9_-]+$/.test(code)) throw bad('Kode hanya huruf/angka');
  if (db.prepare('SELECT 1 FROM vouchers WHERE code = ?').get(code)) throw conflict('Kode sudah ada');
  const pct = b.percentage ? Number(b.percentage) : null;
  if (pct != null && !(pct > 0 && pct <= 1)) throw bad('percentage 0–1 (contoh 0.2)');
  if (!pct && !(Number(b.discountAmount) > 0)) throw bad('discountAmount (ribuan Rupiah) wajib');
  db.prepare('INSERT INTO vouchers (code,title,description,discount_amount,percentage,max_discount,min_spend,usage_limit,expires_at) VALUES (?,?,?,?,?,?,?,?,?)')
    .run(code, str(b.title, 'Judul', { max: 80 }), b.description || '', Number(b.discountAmount) || 0, pct, b.maxDiscount ? Number(b.maxDiscount) : null, Number(b.minSpend) || 0, b.usageLimit ? Number(b.usageLimit) : null, b.expiresAt || null);
  ok(res, vrow(db.prepare('SELECT * FROM vouchers WHERE code = ?').get(code)), { message: 'Voucher dibuat' }, 201);
});
r.patch('/vouchers/:code', (req, res) => {
  if (!db.prepare('SELECT 1 FROM vouchers WHERE code = ?').get(req.params.code)) throw notFound('Voucher tidak ditemukan');
  db.prepare('UPDATE vouchers SET active = COALESCE(?, active), usage_limit = COALESCE(?, usage_limit), expires_at = COALESCE(?, expires_at) WHERE code = ?')
    .run(req.body.active === undefined ? null : req.body.active ? 1 : 0, req.body.usageLimit ?? null, req.body.expiresAt ?? null, req.params.code);
  ok(res, vrow(db.prepare('SELECT * FROM vouchers WHERE code = ?').get(req.params.code)));
});
r.delete('/vouchers/:code', (req, res) => {
  if (!db.prepare('DELETE FROM vouchers WHERE code = ?').run(req.params.code).changes) throw notFound('Voucher tidak ditemukan');
  ok(res, null, { message: 'Voucher dihapus' });
});

// ---- Pelatih ----
const crow = (c) => ({ id: c.id, name: c.name, title: c.title, rating: c.rating, reviewsCount: c.reviews_count, ratePerHour: c.rate_per_hour, experience: c.experience, image: c.image, specialties: JSON.parse(c.specialties), availableVenues: JSON.parse(c.venues), bio: c.bio, active: !!c.active });
r.get('/coaches', (req, res) => ok(res, db.prepare('SELECT * FROM coaches ORDER BY name').all().map(crow)));
r.post('/coaches', (req, res) => {
  const b = req.body;
  const id = `coach_${require('crypto').randomUUID().slice(0, 6)}`;
  const rate = parseInt(b.ratePerHour, 10);
  if (!(rate > 0)) throw bad('ratePerHour (ribuan Rupiah) wajib');
  db.prepare('INSERT INTO coaches (id,name,title,rate_per_hour,experience,image,specialties,venues,bio) VALUES (?,?,?,?,?,?,?,?,?)')
    .run(id, str(b.name, 'Nama', { max: 80 }), b.title || '', rate, b.experience || '', b.image || null, JSON.stringify(b.specialties || []), JSON.stringify(b.availableVenues || []), b.bio || '');
  ok(res, crow(db.prepare('SELECT * FROM coaches WHERE id = ?').get(id)), { message: 'Pelatih ditambahkan' }, 201);
});
r.patch('/coaches/:id', (req, res) => {
  const b = req.body;
  if (!db.prepare('SELECT 1 FROM coaches WHERE id = ?').get(req.params.id)) throw notFound('Pelatih tidak ditemukan');
  db.prepare('UPDATE coaches SET name = COALESCE(?,name), title = COALESCE(?,title), rate_per_hour = COALESCE(?,rate_per_hour), bio = COALESCE(?,bio), active = COALESCE(?,active) WHERE id = ?')
    .run(b.name ?? null, b.title ?? null, b.ratePerHour ? parseInt(b.ratePerHour, 10) : null, b.bio ?? null, b.active === undefined ? null : b.active ? 1 : 0, req.params.id);
  ok(res, crow(db.prepare('SELECT * FROM coaches WHERE id = ?').get(req.params.id)));
});

// ---- Booking, ulasan, mabar ----
r.get('/bookings', (req, res) => {
  const { status, q } = req.query;
  const w = ["b.status != 'Maintenance'"], a = [];
  if (status) { w.push('b.status = ?'); a.push(status); }
  if (q) { w.push('(b.id LIKE ? OR u.name LIKE ? OR c.venue LIKE ?)'); a.push(`%${q}%`, `%${q}%`, `%${q}%`); }
  ok(res, db.prepare(`${U.BOOKING_SELECT} WHERE ${w.join(' AND ')} ORDER BY b.created_at DESC LIMIT 300`).all(...a).map(U.booking));
});
r.delete('/reviews/:id', (req, res) => {
  const rv = db.prepare('SELECT court_id FROM reviews WHERE id = ?').get(req.params.id);
  if (!rv) throw notFound('Ulasan tidak ditemukan');
  db.prepare('DELETE FROM reviews WHERE id = ?').run(req.params.id);
  db.prepare('UPDATE courts SET rating = COALESCE((SELECT ROUND(AVG(rating),1) FROM reviews WHERE court_id = ?), rating) WHERE id = ?').run(rv.court_id, rv.court_id);
  ok(res, null, { message: 'Ulasan dihapus' });
});
r.delete('/matches/:id', (req, res) => {
  if (!db.prepare('DELETE FROM matches WHERE id = ?').run(req.params.id).changes) throw notFound('Mabar tidak ditemukan');
  ok(res, null, { message: 'Mabar dihapus' });
});

module.exports = r;
