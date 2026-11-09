const express = require('express');
const cors = require('cors');
const path = require('path');
const { db } = require('./db');
const { HttpError } = require('./lib/util');

const app = express();
app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(cors({ origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : true }));
app.use(express.json({ limit: '5mb', verify: (req, res, buf) => { req.rawBody = buf; } })); // rawBody dipakai verifikasi signature DOKU
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  next();
});

if (process.env.NODE_ENV !== 'test') {
  app.use((req, res, next) => {
    const t = Date.now();
    res.on('finish', () => req.originalUrl.startsWith('/api') && console.log(`${req.method} ${req.originalUrl} ${res.statusCode} ${Date.now() - t}ms`));
    next();
  });
}

// Booking online yang tidak dibayar dalam 15 menit dibatalkan otomatis → slot terbuka lagi
app.use('/api', (req, res, next) => {
  db.prepare("UPDATE bookings SET status = 'Dibatalkan', cancelled_at = ?, payment_status = 'Kedaluwarsa' WHERE status = 'Terkonfirmasi' AND payment_status = 'Menunggu' AND payment_expires_at < ?")
    .run(new Date().toISOString(), new Date().toISOString());
  next();
});

app.get('/api/health', (req, res) => res.json({ status: 'healthy', service: 'ace-padel-backend', version: '2.0.0', timestamp: new Date().toISOString() }));

app.use('/api/auth', require('./routes/auth'));
app.use('/api/owner', require('./routes/owner'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api', require('./routes/catalog'));
app.use('/api', require('./routes/player'));

app.use('/api', (req, res) => res.status(404).json({ success: false, message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan` }));

// Web: landing + panel (statis, tanpa build step)
const PUB = path.join(__dirname, '../public');
app.use('/uploads', express.static(path.join(__dirname, '../data/uploads')));
// js/css/html revalidate via ETag (no stale 4h browser/CDN cache after deploys); images & fonts keep a long cache.
app.use(express.static(PUB, { extensions: ['html'], setHeaders: (res, f) => { if (/\.(js|css|html)$/.test(f)) res.setHeader('Cache-Control', 'no-cache'); else res.setHeader('Cache-Control', 'public, max-age=86400'); } }));
app.get(['/app', '/app/*'], (req, res) => res.sendFile(path.join(PUB, 'app/index.html')));

// Halaman tidak ditemukan (web)
app.use((req, res) => res.status(404).sendFile(path.join(PUB, '404.html')));

app.use((err, req, res, next) => {
  if (err instanceof HttpError) return res.status(err.status).json({ success: false, message: err.message });
  if (err.type === 'entity.parse.failed') return res.status(400).json({ success: false, message: 'JSON tidak valid' });
  console.error(err);
  res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
});

if (require.main === module) {
  const PORT = process.env.PORT || 3001;
  app.listen(PORT, '0.0.0.0', () => console.log(`Ace Padel server → http://localhost:${PORT}  (web: / , panel: /app , API: /api)`));
}
module.exports = app;
