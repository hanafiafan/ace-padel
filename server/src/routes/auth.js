const express = require('express');
const crypto = require('crypto');
const { db } = require('../db');
const { hashPassword, verifyPassword, signToken, rateLimit } = require('../lib/security');
const { verifyFirebaseToken } = require('../lib/firebase');
const { ok, bad, conflict, str, pick, auth, publicUser, HttpError } = require('../lib/util');

const r = express.Router();
const limit = rateLimit(20, 15 * 60 * 1000);
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const session = (res, u, status = 200) =>
  res.status(status).json({ success: true, token: signToken({ sub: u.id, role: u.role }), data: publicUser(u) });

function uniqueUsername(base) {
  const root = base.toLowerCase().replace(/[^a-z0-9_]/g, '').slice(0, 20) || 'player';
  let n = root;
  while (db.prepare('SELECT 1 FROM users WHERE username = ?').get(n)) n = `${root}${Math.floor(Math.random() * 9999)}`;
  return n;
}

// Daftar. role 'owner' = pemilik lapangan (venue-nya perlu disetujui admin). 'admin' tidak bisa self-register.
r.post('/register', limit, (req, res) => {
  const name = str(req.body.name, 'Nama', { min: 2, max: 80 });
  const email = str(req.body.email, 'Email', { max: 120 }).toLowerCase();
  const password = str(req.body.password, 'Password', { min: 8, max: 100 });
  const role = req.body.role === 'owner' ? 'owner' : 'player';
  if (!EMAIL.test(email)) throw bad('Format email tidak valid');
  if (db.prepare('SELECT 1 FROM users WHERE email = ?').get(email)) throw conflict('Email sudah terdaftar');
  const u = {
    id: `u_${crypto.randomUUID()}`, name, email, password_hash: hashPassword(password), role,
    username: uniqueUsername(email.split('@')[0]), phone: req.body.phone || null, created_at: new Date().toISOString(),
  };
  db.prepare(`INSERT INTO users (${Object.keys(u)}) VALUES (${Object.keys(u).map(() => '?')})`).run(...Object.values(u));
  session(res, db.prepare('SELECT * FROM users WHERE id = ?').get(u.id), 201);
});

r.post('/login', limit, (req, res) => {
  const email = String(req.body.email || '').toLowerCase();
  const u = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!u || !verifyPassword(String(req.body.password || ''), u.password_hash)) throw new HttpError(401, 'Email atau password salah');
  if (u.status !== 'active') throw new HttpError(403, 'Akun Anda ditangguhkan. Hubungi admin.');
  session(res, u);
});

// Login Google: idToken diverifikasi ke Google. Tanpa idToken ditolak (kecuali ALLOW_UNVERIFIED_GOOGLE=1 untuk dev).
const google = async (req, res) => {
  let { email, name, photoUrl, googleId, idToken } = req.body;
  if (idToken) {
    const g = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`).then((x) => x.json()).catch(() => ({}));
    const aud = process.env.GOOGLE_CLIENT_ID;
    if (!aud) throw new HttpError(503, 'Login Google belum dikonfigurasi di server');
    if (!g.email || g.email_verified === 'false' || g.aud !== aud) throw new HttpError(401, 'Token Google tidak valid');
    ({ email, name, picture: photoUrl, sub: googleId } = { ...g, name: g.name || name });
  } else if (process.env.ALLOW_UNVERIFIED_GOOGLE !== '1') {
    throw new HttpError(401, 'idToken Google diperlukan');
  }
  return googleUser(req, res, { email, name, photoUrl, googleId });
};

function googleUser(req, res, { email, name, photoUrl, googleId }) {
  if (!email) throw bad('Email Google diperlukan');
  email = email.toLowerCase();
  let u = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (u && u.status !== 'active') throw new HttpError(403, 'Akun Anda ditangguhkan.');
  if (!u) {
    const id = `u_${crypto.randomUUID()}`;
    db.prepare('INSERT INTO users (id,name,email,username,photo_url,auth_provider,google_id,created_at,role) VALUES (?,?,?,?,?,?,?,?,?)')
      .run(id, name || email.split('@')[0], email, uniqueUsername(email.split('@')[0]), photoUrl || null, 'google', googleId || null, new Date().toISOString(), req.body.role === 'owner' ? 'owner' : 'player');
    u = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
  } else {
    db.prepare('UPDATE users SET photo_url = COALESCE(?, photo_url), google_id = COALESCE(?, google_id) WHERE id = ?').run(photoUrl || null, googleId || null, u.id);
    u = db.prepare('SELECT * FROM users WHERE id = ?').get(u.id);
  }
  session(res, u);
}
r.post('/google', limit, (req, res, next) => google(req, res).catch(next));

// Login Google dari web via Firebase Auth: ID token Firebase diverifikasi di server.
r.post('/firebase', limit, async (req, res, next) => {
  try {
    const t = await verifyFirebaseToken(req.body.idToken).catch(() => { throw new HttpError(401, 'Token login tidak valid'); });
    googleUser(req, res, { email: t.email, name: t.name, photoUrl: t.picture, googleId: t.firebase?.identities?.['google.com']?.[0] || t.sub });
  } catch (e) { next(e); }
});

// Konfigurasi publik untuk klien web (Client ID bukan rahasia).
const FB = { apiKey: process.env.FIREBASE_API_KEY || 'REDACTED-FIREBASE-API-KEY', authDomain: 'ace-padel-3f910.firebaseapp.com', projectId: 'ace-padel-3f910', appId: '1:198282293168:web:b45a79839c31b3f9bab075' };
r.get('/config', (req, res) => res.json({ googleClientId: process.env.GOOGLE_CLIENT_ID || null, firebase: FB }));

r.get('/me', auth(), (req, res) => ok(res, publicUser(req.user)));

r.put('/me', auth(), (req, res) => {
  const map = { name: 'name', phone: 'phone', skillLevel: 'skill_level', preferredHand: 'preferred_hand', photoUrl: 'photo_url' };
  const f = Object.entries(map).filter(([k]) => req.body[k] !== undefined);
  if (f.length) {
    if (req.body.name !== undefined) str(req.body.name, 'Nama', { min: 2, max: 80 });
    db.prepare(`UPDATE users SET ${f.map(([, c]) => `${c} = ?`)} WHERE id = ?`).run(...f.map(([k]) => req.body[k]), req.user.id);
  }
  ok(res, publicUser(db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id)), { message: 'Profil diperbarui' });
});

r.put('/password', auth(), limit, (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (req.user.password_hash && !verifyPassword(String(currentPassword || ''), req.user.password_hash)) throw new HttpError(401, 'Password saat ini salah');
  str(newPassword, 'Password baru', { min: 8, max: 100 });
  db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(hashPassword(newPassword), req.user.id);
  ok(res, null, { message: 'Password diperbarui' });
});

module.exports = r;
