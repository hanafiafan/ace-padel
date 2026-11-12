// Pengirim push FCM (opsional). No-op bila firebase-admin belum di-install
// atau service account belum di-set — server tetap jalan normal.
// Aktifkan: `npm i firebase-admin` + env FIREBASE_SERVICE_ACCOUNT (JSON string)
// atau GOOGLE_APPLICATION_CREDENTIALS (path file). Lihat FCM_SETUP.md.
const { db } = require('../db');

let admin = null;
let tried = false;

function init() {
  if (tried) return admin;
  tried = true;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT; // JSON string
  const file = process.env.GOOGLE_APPLICATION_CREDENTIALS; // path
  if (!raw && !file) return null; // tidak dikonfigurasi → push dimatikan
  try {
    admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: raw
          ? admin.credential.cert(JSON.parse(raw))
          : admin.credential.applicationDefault(),
      });
    }
    return admin;
  } catch (e) {
    console.warn('[push] firebase-admin nonaktif:', e.message);
    admin = null;
    return null;
  }
}

/** Fire-and-forget push ke semua device milik user. Aman dipanggil selalu. */
async function sendToUser(userId, { title, body = '', data = {} } = {}) {
  const a = init();
  if (!a || !userId || !title) return;
  const tokens = db
    .prepare('SELECT token FROM device_tokens WHERE user_id = ?')
    .all(userId)
    .map((r) => r.token);
  if (!tokens.length) return;
  try {
    const res = await a.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)]),
      ),
    });
    res.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code || '';
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-argument')
        ) {
          try {
            db.prepare('DELETE FROM device_tokens WHERE token = ?').run(tokens[i]);
          } catch {}
        }
      }
    });
  } catch (e) {
    console.warn('[push] gagal kirim:', e.message);
  }
}

module.exports = { sendToUser };
