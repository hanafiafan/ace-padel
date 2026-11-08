const crypto = require('crypto');

const SECRET = process.env.JWT_SECRET || 'dev-only-secret-change-me';
if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET wajib di-set di production');
}

const b64u = (b) => Buffer.from(b).toString('base64url');

function hashPassword(pw) {
  const salt = crypto.randomBytes(16);
  return `${salt.toString('hex')}:${crypto.scryptSync(pw, salt, 64).toString('hex')}`;
}

function verifyPassword(pw, stored) {
  if (!stored) return false;
  const [salt, hash] = stored.split(':');
  const a = Buffer.from(hash, 'hex');
  const b = crypto.scryptSync(pw, Buffer.from(salt, 'hex'), 64);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// JWT HS256 (cukup untuk single-service; tanpa dependency)
function signToken(payload, ttlSec = 60 * 60 * 24 * 30) {
  const h = b64u(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const p = b64u(JSON.stringify({ ...payload, exp: Math.floor(Date.now() / 1000) + ttlSec }));
  const sig = crypto.createHmac('sha256', SECRET).update(`${h}.${p}`).digest('base64url');
  return `${h}.${p}.${sig}`;
}

function verifyToken(token) {
  const [h, p, sig] = String(token).split('.');
  if (!h || !p || !sig) return null;
  const expect = crypto.createHmac('sha256', SECRET).update(`${h}.${p}`).digest();
  const got = Buffer.from(sig, 'base64url');
  if (got.length !== expect.length || !crypto.timingSafeEqual(got, expect)) return null;
  try {
    const data = JSON.parse(Buffer.from(p, 'base64url').toString());
    return data.exp > Date.now() / 1000 ? data : null;
  } catch {
    return null;
  }
}

// Rate limiter sederhana in-memory (per IP+key)
const hits = new Map();
function rateLimit(max, windowMs) {
  return (req, res, next) => {
    const k = `${req.ip}:${req.baseUrl}${req.path}`;
    const now = Date.now();
    const arr = (hits.get(k) || []).filter((t) => now - t < windowMs);
    arr.push(now);
    hits.set(k, arr);
    if (arr.length > max) {
      return res.status(429).json({ success: false, message: 'Terlalu banyak percobaan, coba lagi nanti.' });
    }
    next();
  };
}

module.exports = { hashPassword, verifyPassword, signToken, verifyToken, rateLimit };
