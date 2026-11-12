// Registrasi token perangkat untuk push FCM.
const express = require('express');
const { db } = require('../db');
const U = require('../lib/util');
const { ok, bad, auth } = U;

const r = express.Router();

// Simpan / perbarui token milik user yang login.
r.post('/devices', auth(), (req, res) => {
  const token = U.str(req.body.token);
  if (!token) return bad(res, 'token wajib diisi');
  const platform = U.str(req.body.platform) || 'android';
  db.prepare(
    `INSERT INTO device_tokens (token,user_id,platform,created_at) VALUES (?,?,?,?)
     ON CONFLICT(token) DO UPDATE SET user_id=excluded.user_id, platform=excluded.platform`,
  ).run(token, req.user.id, platform, new Date().toISOString());
  ok(res, { registered: true });
});

// Lepas token (mis. saat logout).
r.delete('/devices', auth(), (req, res) => {
  const token = U.str(req.body.token);
  if (token) {
    db.prepare('DELETE FROM device_tokens WHERE token = ? AND user_id = ?').run(
      token,
      req.user.id,
    );
  }
  ok(res, { removed: true });
});

module.exports = r;
