// Verifikasi Firebase ID token (RS256) tanpa dependensi: kunci publik dari sertifikat Google.
const crypto = require('crypto');
const PROJECT = process.env.FIREBASE_PROJECT_ID || 'ace-padel-3f910';
const CERTS = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
let certs = { at: 0, keys: {} };

async function getCerts() {
  if (Date.now() - certs.at < 3600e3 && Object.keys(certs.keys).length) return certs.keys;
  certs = { at: Date.now(), keys: await fetch(CERTS).then((r) => r.json()) };
  return certs.keys;
}
const b64 = (s) => Buffer.from(s, 'base64url');

async function verifyFirebaseToken(token) {
  const [h, p, sig] = String(token || '').split('.');
  if (!h || !p || !sig) throw new Error('format');
  const head = JSON.parse(b64(h)), pay = JSON.parse(b64(p));
  const pem = (await getCerts())[head.kid];
  if (head.alg !== 'RS256' || !pem) throw new Error('kunci');
  const key = new crypto.X509Certificate(pem).publicKey;
  if (!crypto.verify('RSA-SHA256', Buffer.from(`${h}.${p}`), key, b64(sig))) throw new Error('tanda tangan');
  const now = Date.now() / 1000;
  if (pay.aud !== PROJECT || pay.iss !== `https://securetoken.google.com/${PROJECT}` || pay.exp < now || pay.iat > now + 300 || !pay.sub) throw new Error('klaim');
  if (pay.firebase?.sign_in_provider !== 'google.com' || !pay.email || pay.email_verified === false) throw new Error('penyedia');
  return pay;
}
module.exports = { verifyFirebaseToken, _setCerts: (keys) => { certs = { at: Date.now(), keys }; } };
