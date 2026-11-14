// Fitur pemain (butuh login): booking, mabar, teman, favorit, notifikasi, pelatih, pencapaian
const express = require('express');
const crypto = require('crypto');
const { db, tx } = require('../db');
const U = require('../lib/util');
const doku = require('../lib/doku');
const { ok, bad, forbid, notFound, conflict, auth, notify, ALL_SLOTS } = U;
const { HttpError: HttpErr } = U;
const wrapA = (fn) => (req, res, next) => fn(req, res, next).catch(next);
const provider = () => (doku.enabled() ? 'doku' : 'simulated');

const r = express.Router();

// ---------- Booking ----------
const ADDONS = [
  { id: 'racket', name: 'Sewa Raket Bullpadel Pro', price: 30 },
  { id: 'racket_bullpadel', name: 'Sewa Raket Bullpadel Vertex 04', price: 30 },
  { id: 'racket_babolat', name: 'Sewa Raket Babolat Technical Viper', price: 35 },
  { id: 'racket_adidas', name: 'Sewa Raket Adidas Metalbone 3.3', price: 40 },
  { id: 'racket_wilson', name: 'Sewa Raket Wilson Bela Pro V2.5', price: 35 },
  { id: 'racket_head', name: 'Sewa Raket Head Extreme Pro', price: 30 },
  { id: 'racket_nox', name: 'Sewa Raket Nox AT10 Genius 18K', price: 35 },
  { id: 'balls', name: 'Head Padel Pro+ (Can 3 Pcs)', price: 75 },
  { id: 'balls_bullpadel', name: 'Bullpadel Next Pro (Can 3 Pcs)', price: 70 },
  { id: 'balls_wilson', name: 'Wilson Padel X3 (Can 3 Pcs)', price: 75 },
  { id: 'refreshment', name: 'Paket Handuk & 2 Air Mineral', price: 15 },
  { id: 'balls_legacy', name: '1 Can Bola Baru (3 Pcs)', price: 75 },
];
const ONLINE = ['QRIS Instant', 'BCA Virtual Account', 'Mandiri Virtual Account'];
const METHODS = ['Bayar di tempat', ...ONLINE];

r.get('/addons', (req, res) => ok(res, ADDONS));

r.get('/bookings', auth(), (req, res) => {
  const rows = db.prepare(`${U.BOOKING_SELECT} WHERE b.user_id = ? ORDER BY b.date DESC, b.slot DESC`).all(req.user.id).map(U.booking);
  const active = rows.filter((b) => ['Terkonfirmasi', 'Check-in Selesai'].includes(b.status));
  const history = rows.filter((b) => b.status === 'Dibatalkan');
  ok(res, { active, history, totalActive: active.length, totalHistory: history.length });
});

r.get('/bookings/:id', auth(), (req, res) => {
  const b = db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(req.params.id);
  if (!b) throw notFound('Booking tidak ditemukan');
  if (b.user_id !== req.user.id && req.user.role !== 'admin' && b.c_owner !== req.user.id) throw forbid();
  ok(res, U.booking(b));
});

r.post('/bookings', auth(), (req, res) => {
  const { courtId, date, slot, voucherCode, paymentMethod = 'Bayar di tempat' } = req.body;
  if (!courtId || !date || !slot) throw bad('courtId, date, dan slot wajib diisi');
  if (!METHODS.includes(paymentMethod)) throw bad('Metode pembayaran tidak dikenal');
  const dateStr = String(date).split('T')[0];
  U.validateSlotDate(dateStr, slot);
  const c = db.prepare("SELECT * FROM courts WHERE id = ? AND status = 'approved'").get(courtId);
  if (!c) throw notFound('Lapangan tidak ditemukan');

  // harga add-on dihitung server, bukan dipercaya dari klien
  const want = Array.isArray(req.body.addOns) ? req.body.addOns : [];
  const picked = want.map((w) => ADDONS.find((a) => a.id === w || a.name === w)).filter(Boolean);
  const addOnsTotal = picked.reduce((s, a) => s + a.price, 0);

  const created = tx(() => {
    let discount = 0, code = null;
    if (voucherCode) {
      const v = db.prepare('SELECT * FROM vouchers WHERE code = ? COLLATE NOCASE').get(String(voucherCode).trim());
      discount = v ? U.calcDiscount(v, c.price_per_hour) : 0;
      if (!discount) throw bad('Voucher tidak valid atau syarat minimum belum terpenuhi');
      code = v.code;
      db.prepare('UPDATE vouchers SET used_count = used_count + 1 WHERE code = ?').run(v.code);
    }
    const online = ONLINE.includes(paymentMethod);
    const id = `ACE-${c.id.toUpperCase()}-${slot.replace(':', '')}-${crypto.randomInt(1000, 10000)}`;
    // Provider DOKU: URL bayar dibuat lewat POST /bookings/:id/checkout. Mode simulasi: referensi palsu untuk demo.
    const ref = provider() === 'doku' || !online ? null
      : paymentMethod === 'QRIS Instant' ? `QRIS-${id}`
      : `${paymentMethod.startsWith('BCA') ? '12345' : '88608'}${crypto.randomInt(1e9, 1e10)}`;
    try {
      db.prepare(`INSERT INTO bookings (id,court_id,user_id,date,slot,price,discount,add_ons,add_ons_total,final_price,payment_method,payment_status,payment_ref,payment_expires_at,voucher_code,created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
        id, c.id, req.user.id, dateStr, slot, c.price_per_hour, discount, JSON.stringify(picked.map((a) => a.name)), addOnsTotal,
        Math.max(0, c.price_per_hour + addOnsTotal - discount), paymentMethod, online ? 'Menunggu' : 'Belum Bayar', ref,
        online ? new Date(Date.now() + 15 * 60e3).toISOString() : null, code, new Date().toISOString());
    } catch (e) {
      if (/UNIQUE/.test(e.message)) throw conflict('Slot jam tersebut sudah dipesan pemain lain.');
      throw e;
    }
    return id;
  });
  notify(req.user.id, 'Booking dikonfirmasi', `${c.venue} • ${dateStr} ${slot}`, 'booking');
  notify(c.owner_id, 'Booking baru', `${req.user.name} memesan ${c.name} • ${dateStr} ${slot}`, 'booking');
  ok(res, U.booking(db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(created)), { message: 'Booking berhasil dikonfirmasi' }, 201);
});

function cancelBooking(id, actor, { asStaff = false } = {}) {
  const b = db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(id);
  if (!b) throw notFound('Booking tidak ditemukan');
  if (!asStaff && b.user_id !== actor.id) throw forbid();
  if (b.status !== 'Terkonfirmasi') throw bad(`Booking berstatus "${b.status}" tidak dapat dibatalkan`);
  db.prepare("UPDATE bookings SET status = 'Dibatalkan', cancelled_at = ?, payment_status = CASE WHEN payment_status = 'Lunas' THEN 'Dikembalikan' ELSE payment_status END WHERE id = ?")
    .run(new Date().toISOString(), id);
  notify(b.user_id, 'Booking dibatalkan', `${b.c_venue} • ${b.date} ${b.slot}`, 'booking');
  if (b.c_owner && b.c_owner !== actor.id) notify(b.c_owner, 'Booking dibatalkan', `${b.id} dibatalkan`, 'booking');
  return U.booking(db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(id));
}
r.delete('/bookings/:id', auth(), (req, res) =>
  ok(res, cancelBooking(req.params.id, req.user), { message: 'Reservasi dibatalkan dan slot kembali terbuka' }));

// Simulasi gateway pembayaran. PAYMENT_MODE=live mematikan ini → pakai webhook di bawah.
r.post('/bookings/:id/pay', auth(), (req, res) => {
  if (process.env.PAYMENT_MODE === 'live' || provider() === 'doku') throw forbid('Pembayaran live hanya lewat webhook gateway');
  const b = db.prepare('SELECT * FROM bookings WHERE id = ?').get(req.params.id);
  if (!b || b.user_id !== req.user.id) throw notFound('Booking tidak ditemukan');
  if (b.status !== 'Terkonfirmasi' || b.payment_status !== 'Menunggu') throw bad('Booking ini tidak menunggu pembayaran');
  db.prepare("UPDATE bookings SET payment_status = 'Lunas' WHERE id = ?").run(b.id);
  notify(req.user.id, 'Pembayaran diterima', `${b.id} lunas via ${b.payment_method}`, 'payment');
  ok(res, U.booking(db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(b.id)), { message: 'Pembayaran berhasil' });
});

r.get('/payments/config', (req, res) => ok(res, { provider: provider() }));

function markPaid(b, via) {
  if (b.status !== 'Terkonfirmasi' || b.payment_status === 'Lunas') return false;
  db.prepare("UPDATE bookings SET payment_status = 'Lunas' WHERE id = ?").run(b.id);
  notify(b.user_id, 'Pembayaran diterima', `${b.id} lunas via ${via || b.payment_method}`, 'payment');
  return true;
}

// Buat/ambil halaman bayar DOKU untuk booking online milik user
r.post('/bookings/:id/checkout', auth(), wrapA(async (req, res) => {
  if (!doku.enabled()) throw bad('Gateway DOKU belum dikonfigurasi di server');
  const b = db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(req.params.id);
  if (!b || b.user_id !== req.user.id) throw notFound('Booking tidak ditemukan');
  if (b.status !== 'Terkonfirmasi' || b.payment_status !== 'Menunggu') throw bad('Booking ini tidak menunggu pembayaran');
  if (/^https?:/.test(b.payment_ref || '')) return ok(res, U.booking(b), { paymentUrl: b.payment_ref });
  const left = Math.max(1, Math.floor((Date.parse(b.payment_expires_at) - Date.now()) / 60000));
  let url;
  try {
    url = await doku.createCheckout({
      invoice: b.id, amountRp: b.final_price * 1000, method: b.payment_method, dueMinutes: left,
      customer: { name: req.user.name, email: req.user.email }, itemName: `Sewa ${b.c_name} - ${b.c_venue} ${b.date} ${b.slot}`,
      callbackUrl: `${doku.env().publicUrl || `${req.protocol}://${req.get('host')}`}/app/#/me/bookings?paid=${encodeURIComponent(b.id)}`,
    });
  } catch (e) {
    console.error('DOKU checkout gagal:', e.message, JSON.stringify(e.doku || {}).slice(0, 400));
    throw new HttpErr(424, 'Gagal membuat pembayaran DOKU. Coba lagi atau pilih Bayar di tempat.');
  }
  db.prepare('UPDATE bookings SET payment_ref = ? WHERE id = ?').run(url, b.id);
  ok(res, U.booking(db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(b.id)), { paymentUrl: url });
}));

// Sinkronkan status ke DOKU (dipakai setelah user kembali dari halaman bayar)
r.get('/bookings/:id/payment-status', auth(), wrapA(async (req, res) => {
  const b = db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(req.params.id);
  if (!b || b.user_id !== req.user.id) throw notFound('Booking tidak ditemukan');
  if (doku.enabled() && b.payment_status === 'Menunggu' && /^https?:/.test(b.payment_ref || '')) {
    const st = await doku.checkStatus(b.id).catch(() => 'UNKNOWN');
    if (st === 'SUCCESS') markPaid(b, 'DOKU');
  }
  const fresh = db.prepare(`${U.BOOKING_SELECT} WHERE b.id = ?`).get(b.id);
  ok(res, U.booking(fresh), { paid: fresh.payment_status === 'Lunas' });
}));

// Notifikasi HTTP dari DOKU → set URL ini di DOKU Dashboard (Settings > Payment Settings > Notification URL)
r.post('/payments/doku/notify', (req, res) => {
  if (!doku.verifyNotification(req)) return res.status(401).json({ success: false, message: 'Signature tidak valid' });
  const inv = req.body?.order?.invoice_number;
  const b = inv && db.prepare('SELECT * FROM bookings WHERE id = ?').get(inv);
  if (b && req.body?.transaction?.status === 'SUCCESS' && Number(req.body.order.amount) === b.final_price * 1000) markPaid(b, 'DOKU');
  res.json({ success: true });
});

// Webhook gateway sungguhan (Midtrans/Xendit dsb.) — diamankan secret bersama
r.post('/payments/webhook', (req, res) => {
  const secret = process.env.PAYMENT_WEBHOOK_SECRET;
  if (!secret || req.headers['x-webhook-secret'] !== secret) return res.status(401).json({ success: false, message: 'Unauthorized' });
  const { bookingId, status } = req.body;
  const b = db.prepare('SELECT * FROM bookings WHERE id = ?').get(bookingId);
  if (!b) throw notFound();
  if (status === 'paid' && b.status === 'Terkonfirmasi') {
    db.prepare("UPDATE bookings SET payment_status = 'Lunas' WHERE id = ?").run(b.id);
    notify(b.user_id, 'Pembayaran diterima', `${b.id} lunas`, 'payment');
  }
  ok(res, null);
});

// ---------- Mabar ----------
const matchRow = (m, me) => {
  const players = db.prepare('SELECT u.id, u.name FROM match_players mp JOIN users u ON u.id = mp.user_id WHERE mp.match_id = ?').all(m.id);
  return {
    id: m.id, courtId: m.court_id, court: U.court(db.prepare('SELECT * FROM courts WHERE id = ?').get(m.court_id)),
    dateString: m.date_label, time: m.time, title: m.title, hostId: m.host_id, hostName: m.host_name, skillLevel: m.skill_level,
    currentPlayers: players.length, maxPlayers: m.max_players, pricePerPlayer: m.price_per_player,
    players: players.map((p) => p.name), isJoined: !!me && players.some((p) => p.id === me.id),
  };
};
r.get('/matches', auth(false), (req, res) =>
  ok(res, db.prepare('SELECT m.*, u.name host_name FROM matches m JOIN users u ON u.id = m.host_id ORDER BY m.created_at DESC').all().map((m) => matchRow(m, req.user))));

r.post('/matches', auth(), (req, res) => {
  const { courtId, dateString, time, title, skillLevel = 'Semua Level (Casual)', pricePerPlayer = 0 } = req.body;
  const maxPlayers = Number(req.body.maxPlayers) || 4;
  if (!courtId || !dateString || !time || !title) throw bad('courtId, dateString, time, dan title wajib diisi');
  if (maxPlayers < 2 || maxPlayers > 8) throw bad('maxPlayers 2–8');
  if (!db.prepare("SELECT 1 FROM courts WHERE id = ? AND status = 'approved'").get(courtId)) throw notFound('Lapangan tidak ditemukan');
  const id = `m_${crypto.randomUUID().slice(0, 8)}`;
  tx(() => {
    db.prepare('INSERT INTO matches (id,court_id,host_id,date_label,time,title,skill_level,max_players,price_per_player,created_at) VALUES (?,?,?,?,?,?,?,?,?,?)')
      .run(id, courtId, req.user.id, String(dateString).slice(0, 60), String(time).slice(0, 60), String(title).slice(0, 120), skillLevel, maxPlayers, Math.max(0, Number(pricePerPlayer) || 0), new Date().toISOString());
    db.prepare('INSERT INTO match_players VALUES (?,?)').run(id, req.user.id);
  });
  ok(res, matchRow(db.prepare('SELECT m.*, u.name host_name FROM matches m JOIN users u ON u.id = m.host_id WHERE m.id = ?').get(id), req.user), { message: 'Slot mabar dibuat' }, 201);
});

r.post('/matches/:id/join', auth(), (req, res) => {
  const m = db.prepare('SELECT m.*, u.name host_name FROM matches m JOIN users u ON u.id = m.host_id WHERE m.id = ?').get(req.params.id);
  if (!m) throw notFound('Mabar tidak ditemukan');
  const joined = db.prepare('SELECT 1 FROM match_players WHERE match_id = ? AND user_id = ?').get(m.id, req.user.id);
  if (joined) {
    if (m.host_id === req.user.id) throw bad('Host tidak bisa keluar dari mabar sendiri');
    db.prepare('DELETE FROM match_players WHERE match_id = ? AND user_id = ?').run(m.id, req.user.id);
  } else {
    tx(() => {
      const n = db.prepare('SELECT COUNT(*) n FROM match_players WHERE match_id = ?').get(m.id).n;
      if (n >= m.max_players) throw conflict('Slot mabar sudah penuh');
      db.prepare('INSERT INTO match_players VALUES (?,?)').run(m.id, req.user.id);
    });
    notify(m.host_id, 'Pemain baru bergabung', `${req.user.name} bergabung di "${m.title}"`, 'match');
  }
  ok(res, matchRow(m, req.user), { joined: !joined }); // matchRow dihitung ulang dari DB
});

// ---------- Teman & favorit ----------
const findPlayer = (key) => db.prepare("SELECT * FROM users WHERE (id = ? OR username = ?) AND role = 'player'").get(key, key);
r.get('/friends', auth(), (req, res) => {
  const rows = db.prepare('SELECT u.* FROM friends f JOIN users u ON u.id = f.friend_id WHERE f.user_id = ? ORDER BY u.points DESC').all(req.user.id);
  ok(res, rows.map((u) => ({ id: u.id, name: u.name, username: u.username, points: u.points, wins: u.wins, matches: u.matches })));
});
r.post('/friends/add', auth(), (req, res) => {
  const p = findPlayer(String(req.body.playerId || ''));
  if (!p) throw notFound('Pemain tidak ditemukan');
  if (p.id === req.user.id) throw bad('Tidak bisa menambahkan diri sendiri');
  db.prepare('INSERT OR IGNORE INTO friends VALUES (?,?)').run(req.user.id, p.id);
  notify(p.id, 'Teman baru', `${req.user.name} menambahkan Anda sebagai teman`, 'friend');
  ok(res, { id: p.id, username: p.username });
});
r.post('/friends/remove', auth(), (req, res) => {
  const p = findPlayer(String(req.body.playerId || ''));
  if (p) db.prepare('DELETE FROM friends WHERE user_id = ? AND friend_id = ?').run(req.user.id, p.id);
  ok(res, null);
});
r.get('/players/search', auth(), (req, res) => {
  const q = `%${String(req.query.q || '').replace(/^@/, '')}%`;
  ok(res, db.prepare("SELECT id,name,username,points FROM users WHERE role='player' AND status='active' AND id != ? AND (name LIKE ? OR username LIKE ?) LIMIT 20").all(req.user.id, q, q));
});

r.get('/favorites', auth(), (req, res) =>
  ok(res, db.prepare('SELECT court_id FROM favorites WHERE user_id = ?').all(req.user.id).map((x) => x.court_id)));
r.post('/favorites/:courtId', auth(), (req, res) => {
  if (!db.prepare('SELECT 1 FROM courts WHERE id = ?').get(req.params.courtId)) throw notFound('Lapangan tidak ditemukan');
  const had = db.prepare('DELETE FROM favorites WHERE user_id = ? AND court_id = ?').run(req.user.id, req.params.courtId).changes;
  if (!had) db.prepare('INSERT INTO favorites VALUES (?,?)').run(req.user.id, req.params.courtId);
  ok(res, { favorite: !had });
});

// ---------- Notifikasi ----------
r.get('/notifications', auth(), (req, res) => {
  const rows = db.prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 100').all(req.user.id)
    .map((n) => ({ id: n.id, title: n.title, body: n.body, type: n.type, read: !!n.read, createdAt: n.created_at }));
  ok(res, rows, { unread: rows.filter((n) => !n.read).length });
});
r.post('/notifications/read-all', auth(), (req, res) => {
  db.prepare('UPDATE notifications SET read = 1 WHERE user_id = ?').run(req.user.id);
  ok(res, null);
});
r.post('/notifications/:id/read', auth(), (req, res) => {
  db.prepare('UPDATE notifications SET read = 1 WHERE id = ? AND user_id = ?').run(req.params.id, req.user.id);
  ok(res, null);
});

// ---------- Metode bayar favorit ----------
r.get('/payment-method', auth(), (req, res) =>
  ok(res, { method: db.prepare('SELECT method FROM payment_methods WHERE user_id = ?').get(req.user.id)?.method || 'Bayar di tempat', options: METHODS }));
r.put('/payment-method', auth(), (req, res) => {
  if (!METHODS.includes(req.body.method)) throw bad('Metode tidak dikenal');
  db.prepare('DELETE FROM payment_methods WHERE user_id = ?').run(req.user.id);
  db.prepare('INSERT INTO payment_methods (user_id, method, is_default) VALUES (?,?,1)').run(req.user.id, req.body.method);
  ok(res, { method: req.body.method });
});

// ---------- Pelatih ----------
const sessionRow = (s) => ({ id: s.id, coachId: s.coach_id, coachName: s.coach_name, venue: s.venue, date: s.date, slot: s.slot, focus: s.focus, price: s.price, status: s.status });
r.get('/coach-sessions', auth(), (req, res) =>
  ok(res, db.prepare('SELECT s.*, c.name coach_name FROM coach_sessions s JOIN coaches c ON c.id = s.coach_id WHERE s.user_id = ? ORDER BY s.date DESC, s.slot').all(req.user.id).map(sessionRow)));
r.post('/coach-sessions', auth(), (req, res) => {
  const { coachId, venue = '', date, slot, focus = '' } = req.body;
  const coach = db.prepare('SELECT * FROM coaches WHERE id = ? AND active = 1').get(coachId);
  if (!coach) throw notFound('Pelatih tidak ditemukan');
  U.validateSlotDate(date, slot);
  const id = `cs_${crypto.randomUUID().slice(0, 8)}`;
  try {
    db.prepare('INSERT INTO coach_sessions (id,coach_id,user_id,venue,date,slot,focus,price,created_at) VALUES (?,?,?,?,?,?,?,?,?)')
      .run(id, coach.id, req.user.id, venue, date, slot, String(focus).slice(0, 200), coach.rate_per_hour, new Date().toISOString());
  } catch (e) {
    if (/UNIQUE/.test(e.message)) throw conflict('Pelatih sudah dibooking pada jam tersebut');
    throw e;
  }
  notify(req.user.id, 'Sesi coaching dikonfirmasi', `${coach.name} • ${date} ${slot}`, 'coach');
  ok(res, sessionRow({ ...db.prepare('SELECT * FROM coach_sessions WHERE id = ?').get(id), coach_name: coach.name }), { message: 'Sesi coaching dipesan' }, 201);
});
r.delete('/coach-sessions/:id', auth(), (req, res) => {
  const n = db.prepare("UPDATE coach_sessions SET status = 'Dibatalkan' WHERE id = ? AND user_id = ? AND status = 'Terkonfirmasi'").run(req.params.id, req.user.id).changes;
  if (!n) throw notFound('Sesi tidak ditemukan');
  ok(res, null, { message: 'Sesi dibatalkan' });
});

// ---------- Profil: statistik & pencapaian (dihitung dari data nyata) ----------
function userProgress(u) {
  const q = (sql, ...a) => db.prepare(sql).get(u.id, ...a);
  const played = q("SELECT COUNT(*) n FROM bookings WHERE user_id = ? AND status IN ('Terkonfirmasi','Check-in Selesai')").n;
  const checked = q("SELECT COUNT(*) n FROM bookings WHERE user_id = ? AND status = 'Check-in Selesai'").n;
  const early = q("SELECT COUNT(*) n FROM bookings WHERE user_id = ? AND status != 'Dibatalkan' AND slot < '12:00'").n;
  const venues = q("SELECT COUNT(DISTINCT c.venue) n FROM bookings b JOIN courts c ON c.id = b.court_id WHERE b.user_id = ? AND b.status IN ('Terkonfirmasi','Check-in Selesai')").n;
  const rank = db.prepare("SELECT COUNT(*) + 1 n FROM users WHERE role='player' AND points > ?").get(u.points).n;
  return { played, checked, early, venues, rank };
}
r.get('/me/stats', auth(), (req, res) => {
  const p = userProgress(req.user);
  ok(res, { activeBookings: p.played, hoursPlayed: p.checked, points: req.user.points, wins: req.user.wins, matches: req.user.matches, rank: p.rank });
});
r.get('/achievements', auth(), (req, res) => {
  const u = req.user, p = userProgress(u);
  const A = (key, title, desc, progress, target) => ({ key, title, desc, progress: Math.min(progress, target), target, unlocked: progress >= target });
  ok(res, [
    A('first_serve', 'First Serve', 'Selesaikan booking pertama', p.played, 1),
    A('rajin_main', 'Rajin Main', 'Main 10 kali', p.checked, 10),
    A('early_bird', 'Early Bird', 'Booking slot pagi 5x', p.early, 5),
    A('globetrotter', 'Globetrotter', 'Main di 4 venue berbeda', p.venues, 4),
    A('win_streak', 'Win Streak', 'Menang 5 kali', u.wins, 5),
    A('centurion', 'Centurion', 'Capai 100 jam main', p.checked, 100),
    A('top3', 'Top 3', 'Masuk 3 besar leaderboard', p.rank <= 3 && u.points > 0 ? 1 : 0, 1),
    A('ace_master', 'Ace Master', 'Kumpulkan 3000 poin', u.points, 3000),
  ]);
});

module.exports = r;
module.exports.cancelBooking = cancelBooking;
