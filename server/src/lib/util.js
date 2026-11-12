const { verifyToken } = require('./security');
const { db } = require('../db');

const ALL_SLOTS = Array.from({ length: 14 }, (_, i) => `${String(8 + i).padStart(2, '0')}:00`);

class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
const bad = (m) => new HttpError(400, m);
const forbid = (m = 'Akses ditolak') => new HttpError(403, m);
const notFound = (m = 'Data tidak ditemukan') => new HttpError(404, m);
const conflict = (m) => new HttpError(409, m);

const ok = (res, data, extra = {}, status = 200) => res.status(status).json({ success: true, ...extra, data });

// Waktu WIB (UTC+7) — semua aturan tanggal/slot memakai zona Indonesia Barat
const wibNow = () => new Date(Date.now() + 7 * 3600 * 1000);
const today = () => wibNow().toISOString().slice(0, 10);
const nowSlotHour = () => wibNow().getUTCHours();

const isDate = (s) => /^\d{4}-\d{2}-\d{2}$/.test(s) && !isNaN(Date.parse(s));

function validateSlotDate(date, slot) {
  if (!isDate(date)) throw bad('Format tanggal harus YYYY-MM-DD');
  if (!ALL_SLOTS.includes(slot)) throw bad('Slot tidak valid (08:00–21:00)');
  const t = today();
  if (date < t) throw bad('Tanggal sudah lewat');
  if (date === t && Number(slot.slice(0, 2)) <= nowSlotHour()) throw bad('Slot jam ini sudah lewat');
  const max = new Date(Date.parse(t) + 60 * 86400000).toISOString().slice(0, 10);
  if (date > max) throw bad('Maksimal booking 60 hari ke depan');
}

const pick = (body, keys) => Object.fromEntries(keys.filter((k) => body[k] !== undefined).map((k) => [k, body[k]]));
const str = (v, name, { min = 1, max = 200 } = {}) => {
  if (typeof v !== 'string' || v.trim().length < min || v.length > max) throw bad(`${name} wajib diisi (${min}-${max} karakter)`);
  return v.trim();
};

// ---- Auth middleware ----
function auth(required = true) {
  return (req, res, next) => {
    const h = req.headers.authorization || '';
    const data = h.startsWith('Bearer ') ? verifyToken(h.slice(7)) : null;
    if (data) {
      const u = db.prepare('SELECT * FROM users WHERE id = ?').get(data.sub);
      if (u && u.status === 'active') req.user = u;
    }
    if (required && !req.user) return res.status(401).json({ success: false, message: 'Silakan login terlebih dahulu' });
    next();
  };
}
const role = (...roles) => (req, res, next) =>
  roles.includes(req.user.role) ? next() : res.status(403).json({ success: false, message: 'Akses ditolak untuk peran Anda' });

// ---- Serializers ----
const publicUser = (u) => u && ({
  id: u.id, name: u.name, username: u.username, email: u.email, phone: u.phone, role: u.role, status: u.status,
  skillLevel: u.skill_level, preferredHand: u.preferred_hand, photoUrl: u.photo_url, authProvider: u.auth_provider,
  points: u.points, wins: u.wins, matches: u.matches, createdAt: u.created_at,
});
const imageUrl = (img) => (img && img.startsWith('assets/images/') ? `/img/${img.split('/').pop()}` : img || null);
const court = (c) => c && ({
  id: c.id, ownerId: c.owner_id, name: c.name, venue: c.venue, area: c.area,
  city: c.area.includes(',') ? c.area.split(',').pop().trim() : c.area,
  pricePerHour: c.price_per_hour, indoor: !!c.indoor, rating: c.rating, image: c.image, imageUrl: imageUrl(c.image),
  facilities: JSON.parse(c.facilities || '[]'), description: c.description, status: c.status, createdAt: c.created_at,
});
const booking = (b) => b && ({
  id: b.id, courtId: b.court_id, userId: b.user_id, userName: b.user_name || null, userEmail: b.user_email || null,
  date: b.date, slot: b.slot, pricePerHour: b.price, discount: b.discount, addOns: JSON.parse(b.add_ons || '[]'),
  addOnsTotal: b.add_ons_total, finalPrice: b.final_price, paymentMethod: b.payment_method,
  paymentStatus: b.payment_status, paymentRef: b.payment_ref, paymentUrl: /^https?:/.test(b.payment_ref || '') ? b.payment_ref : null, paymentExpiresAt: b.payment_expires_at,
  voucherCode: b.voucher_code, status: b.status, note: b.note,
  createdAt: b.created_at, checkedInAt: b.checked_in_at, cancelledAt: b.cancelled_at,
  court: b.c_id ? court({ id: b.c_id, owner_id: b.c_owner, name: b.c_name, venue: b.c_venue, area: b.c_area, price_per_hour: b.c_price, indoor: b.c_indoor, rating: b.c_rating, image: b.c_image, facilities: b.c_fac, description: b.c_desc, status: b.c_status, created_at: '' }) : undefined,
});
const BOOKING_SELECT = `SELECT b.*, u.name user_name, u.email user_email,
  c.id c_id, c.owner_id c_owner, c.name c_name, c.venue c_venue, c.area c_area, c.price_per_hour c_price,
  c.indoor c_indoor, c.rating c_rating, c.image c_image, c.facilities c_fac, c.description c_desc, c.status c_status
  FROM bookings b JOIN courts c ON c.id = b.court_id LEFT JOIN users u ON u.id = b.user_id`;

function notify(userId, title, body = '', type = 'info') {
  if (!userId) return;
  db.prepare('INSERT INTO notifications (user_id,title,body,type,created_at) VALUES (?,?,?,?,?)').run(userId, title, body, type, new Date().toISOString());
  // Juga kirim push FCM (fire-and-forget; no-op bila push belum dikonfigurasi).
  try { require('./push').sendToUser(userId, { title, body, data: { type } }); } catch {}
}

function calcDiscount(v, price) {
  if (!v || !v.active || price < v.min_spend) return 0;
  if (v.expires_at && v.expires_at < today()) return 0;
  if (v.usage_limit != null && v.used_count >= v.usage_limit) return 0;
  let d = v.percentage ? Math.round(price * v.percentage) : v.discount_amount;
  if (v.max_discount && d > v.max_discount) d = v.max_discount;
  return Math.min(d, price);
}

module.exports = { ALL_SLOTS, HttpError, bad, forbid, notFound, conflict, ok, today, isDate, validateSlotDate, pick, str, auth, role, publicUser, court, booking, BOOKING_SELECT, notify, calcDiscount, wibNow };
