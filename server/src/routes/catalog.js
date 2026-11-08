// Endpoint publik: lapangan, ulasan, pelatih, voucher, leaderboard, statistik landing page
const express = require('express');
const { db } = require('../db');
const { ok, notFound, ALL_SLOTS, isDate, bad, court, auth, today } = require('../lib/util');

const r = express.Router();
const approved = "c.status = 'approved'";

r.get('/courts', (req, res) => {
  const { q, indoor, city, facility, sortBy } = req.query;
  let list = db.prepare(`SELECT * FROM courts c WHERE ${approved}`).all().map(court);
  const has = (s, t) => String(s).toLowerCase().includes(String(t).toLowerCase());
  if (indoor === 'true' || indoor === 'false') list = list.filter((c) => c.indoor === (indoor === 'true'));
  if (city) list = list.filter((c) => has(c.area, city));
  if (facility) list = list.filter((c) => c.facilities.some((f) => has(f, facility)));
  if (q) list = list.filter((c) => has(c.name, q) || has(c.venue, q) || has(c.area, q));
  if (sortBy === 'rating') list.sort((a, b) => b.rating - a.rating);
  else if (['price_asc', 'Harga Terendah'].includes(sortBy)) list.sort((a, b) => a.pricePerHour - b.pricePerHour);
  else if (['price_desc', 'Harga Tertinggi'].includes(sortBy)) list.sort((a, b) => b.pricePerHour - a.pricePerHour);
  ok(res, list, { count: list.length });
});

r.get('/courts/meta/cities', (req, res) => {
  const cities = [...new Set(db.prepare(`SELECT area FROM courts c WHERE ${approved}`).all().map((c) => court({ ...c, facilities: '[]' }).city))].sort();
  ok(res, cities);
});

const reviewRows = (courtId) =>
  db.prepare('SELECT r.*, u.name user_name, u.skill_level FROM reviews r JOIN users u ON u.id = r.user_id WHERE r.court_id = ? ORDER BY r.created_at DESC').all(courtId)
    .map((x) => ({ id: x.id, courtId: x.court_id, userName: x.user_name, rating: x.rating, comment: x.comment, skillLevel: x.skill_level, createdAt: x.created_at }));

r.get('/courts/:id', (req, res) => {
  const c = db.prepare(`SELECT * FROM courts c WHERE id = ? AND ${approved}`).get(req.params.id);
  if (!c) throw notFound('Lapangan tidak ditemukan');
  ok(res, { ...court(c), reviews: reviewRows(c.id) });
});

// Slot: terisi oleh booking aktif / diblokir mitra. Slot lewat (hari ini) ditandai past.
r.get('/courts/:id/slots', (req, res) => {
  const { date } = req.query;
  if (!isDate(date)) throw bad('Query date (YYYY-MM-DD) wajib');
  if (!db.prepare(`SELECT 1 FROM courts c WHERE id = ? AND ${approved}`).get(req.params.id)) throw notFound('Lapangan tidak ditemukan');
  const rows = db.prepare("SELECT slot, status FROM bookings WHERE court_id = ? AND date = ? AND status IN ('Terkonfirmasi','Check-in Selesai','Maintenance')").all(req.params.id, date);
  const taken = new Map(rows.map((x) => [x.slot, x.status]));
  const nowH = new Date(Date.now() + 7 * 3600e3).getUTCHours();
  const slots = ALL_SLOTS.map((slot) => {
    const past = date < today() || (date === today() && Number(slot.slice(0, 2)) <= nowH);
    const t = taken.has(slot) || past;
    return { slot, available: !t, taken: t, blocked: taken.get(slot) === 'Maintenance', past };
  });
  ok(res, slots, { courtId: req.params.id, date, slots });
});

r.get('/reviews/:courtId', (req, res) => ok(res, reviewRows(req.params.courtId)));

r.post('/reviews', auth(), (req, res) => {
  const { courtId, comment = '' } = req.body;
  const rating = Number(req.body.rating);
  if (!(rating >= 1 && rating <= 5)) throw bad('Rating 1–5');
  if (!db.prepare('SELECT 1 FROM courts WHERE id = ?').get(courtId)) throw notFound('Lapangan tidak ditemukan');
  // hanya pemain yang pernah booking (bukan batal) yang boleh mengulas
  if (!db.prepare("SELECT 1 FROM bookings WHERE court_id = ? AND user_id = ? AND status IN ('Terkonfirmasi','Check-in Selesai')").get(courtId, req.user.id))
    throw bad('Anda hanya bisa mengulas lapangan yang pernah Anda pesan');
  const id = require('crypto').randomUUID();
  db.prepare('INSERT INTO reviews (id,court_id,user_id,rating,comment,created_at) VALUES (?,?,?,?,?,?)').run(id, courtId, req.user.id, rating, String(comment).slice(0, 1000), new Date().toISOString());
  db.prepare('UPDATE courts SET rating = ROUND((SELECT AVG(rating) FROM reviews WHERE court_id = ?), 1) WHERE id = ?').run(courtId, courtId);
  ok(res, reviewRows(courtId)[0], { message: 'Ulasan terkirim' }, 201);
});

const coach = (c) => ({
  id: c.id, name: c.name, title: c.title, rating: c.rating, reviewsCount: c.reviews_count, ratePerHour: c.rate_per_hour,
  experience: c.experience, image: c.image, imageUrl: c.image && c.image.startsWith('assets/') ? `/img/${c.image.split('/').pop()}` : c.image,
  specialties: JSON.parse(c.specialties), availableVenues: JSON.parse(c.venues), bio: c.bio, active: !!c.active,
});
r.get('/coaches', (req, res) => ok(res, db.prepare('SELECT * FROM coaches WHERE active = 1 ORDER BY rating DESC').all().map(coach)));

const voucher = (v) => ({ code: v.code, title: v.title, description: v.description, discountAmount: v.discount_amount, percentage: v.percentage, maxDiscount: v.max_discount, minSpend: v.min_spend, active: !!v.active, usageLimit: v.usage_limit, usedCount: v.used_count, expiresAt: v.expires_at });
r.get('/vouchers', (req, res) => ok(res, db.prepare('SELECT * FROM vouchers WHERE active = 1 AND (expires_at IS NULL OR expires_at >= ?)').all(today()).map(voucher)));

r.post('/vouchers/validate', (req, res) => {
  const { code, price } = req.body;
  const v = db.prepare('SELECT * FROM vouchers WHERE code = ? COLLATE NOCASE').get(String(code || '').trim());
  const { calcDiscount } = require('../lib/util');
  const d = v ? calcDiscount(v, Number(price) || 0) : 0;
  if (!v || !d) return res.status(400).json({ success: false, valid: false, message: 'Voucher tidak valid atau syarat minimum belum terpenuhi' });
  ok(res, { ...voucher(v), discount: d }, { valid: true });
});

const board = (u, i) => ({ rank: i + 1, id: u.id, name: u.name, username: u.username, photoUrl: u.photo_url, points: u.points, wins: u.wins, matches: u.matches });
r.get('/leaderboard', auth(false), (req, res) => {
  let rows = db.prepare("SELECT * FROM users WHERE role = 'player' AND status = 'active' ORDER BY points DESC, wins DESC LIMIT 100").all();
  if (req.query.scope === 'friends' && req.user) {
    const f = new Set(db.prepare('SELECT friend_id FROM friends WHERE user_id = ?').all(req.user.id).map((x) => x.friend_id));
    rows = rows.filter((u) => f.has(u.id) || u.id === req.user.id);
  }
  ok(res, rows.map((u, i) => ({ ...board(u, i), isMe: req.user?.id === u.id })));
});

// Angka live untuk landing page
r.get('/public/stats', (req, res) => {
  const n = (sql) => db.prepare(sql).get().n;
  ok(res, {
    venues: n("SELECT COUNT(DISTINCT venue) n FROM courts WHERE status = 'approved'"),
    courts: n("SELECT COUNT(*) n FROM courts WHERE status = 'approved'"),
    players: n("SELECT COUNT(*) n FROM users WHERE role = 'player'"),
    bookings: n("SELECT COUNT(*) n FROM bookings WHERE status != 'Maintenance'"),
    cities: n("SELECT COUNT(DISTINCT TRIM(SUBSTR(area, INSTR(area, ',') + 1))) n FROM courts WHERE status = 'approved'"),
  });
});

module.exports = r;
