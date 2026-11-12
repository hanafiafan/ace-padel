const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '../data/acepadel.sqlite');
if (DB_PATH !== ':memory:') fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });

const db = new DatabaseSync(DB_PATH);
db.exec('PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000;');

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  username TEXT UNIQUE,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT,
  role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player','owner','admin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended')),
  phone TEXT, skill_level TEXT DEFAULT 'Menengah (Intermediate)',
  preferred_hand TEXT DEFAULT 'Tangan Kanan (Right-handed)',
  photo_url TEXT, auth_provider TEXT DEFAULT 'email', google_id TEXT,
  points INTEGER NOT NULL DEFAULT 0, wins INTEGER NOT NULL DEFAULT 0, matches INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS courts (
  id TEXT PRIMARY KEY,
  owner_id TEXT REFERENCES users(id),
  name TEXT NOT NULL, venue TEXT NOT NULL, area TEXT NOT NULL,
  price_per_hour INTEGER NOT NULL CHECK (price_per_hour > 0), -- ribuan Rupiah
  indoor INTEGER NOT NULL DEFAULT 1,
  rating REAL NOT NULL DEFAULT 0,
  image TEXT, facilities TEXT NOT NULL DEFAULT '[]', description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','suspended')),
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  court_id TEXT NOT NULL REFERENCES courts(id),
  user_id TEXT REFERENCES users(id),
  date TEXT NOT NULL, slot TEXT NOT NULL,
  price INTEGER NOT NULL DEFAULT 0, discount INTEGER NOT NULL DEFAULT 0,
  add_ons TEXT NOT NULL DEFAULT '[]', add_ons_total INTEGER NOT NULL DEFAULT 0,
  final_price INTEGER NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'Bayar di tempat',
  payment_status TEXT NOT NULL DEFAULT 'Belum Bayar', -- Belum Bayar | Menunggu | Lunas | Dikembalikan
  payment_ref TEXT, payment_expires_at TEXT,
  voucher_code TEXT, note TEXT,
  status TEXT NOT NULL DEFAULT 'Terkonfirmasi', -- Terkonfirmasi | Check-in Selesai | Dibatalkan | Maintenance
  created_at TEXT NOT NULL, checked_in_at TEXT, cancelled_at TEXT
);
-- Anti double-booking dijamin DB, bukan hanya kode aplikasi
CREATE UNIQUE INDEX IF NOT EXISTS uq_slot ON bookings(court_id, date, slot)
  WHERE status IN ('Terkonfirmasi','Check-in Selesai','Maintenance');
CREATE INDEX IF NOT EXISTS ix_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS ix_bookings_court_date ON bookings(court_id, date);
CREATE TABLE IF NOT EXISTS vouchers (
  code TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT DEFAULT '',
  discount_amount INTEGER NOT NULL DEFAULT 0, percentage REAL, max_discount INTEGER,
  min_spend INTEGER NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1,
  usage_limit INTEGER, used_count INTEGER NOT NULL DEFAULT 0, expires_at TEXT
);
CREATE TABLE IF NOT EXISTS matches (
  id TEXT PRIMARY KEY, court_id TEXT NOT NULL REFERENCES courts(id),
  host_id TEXT NOT NULL REFERENCES users(id),
  date_label TEXT NOT NULL, time TEXT NOT NULL, title TEXT NOT NULL,
  skill_level TEXT NOT NULL, max_players INTEGER NOT NULL DEFAULT 4,
  price_per_player INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS match_players (
  match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id), PRIMARY KEY (match_id, user_id)
);
CREATE TABLE IF NOT EXISTS reviews (
  id TEXT PRIMARY KEY, court_id TEXT NOT NULL REFERENCES courts(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  rating REAL NOT NULL CHECK (rating BETWEEN 1 AND 5), comment TEXT DEFAULT '', created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS friends (
  user_id TEXT NOT NULL REFERENCES users(id), friend_id TEXT NOT NULL REFERENCES users(id),
  PRIMARY KEY (user_id, friend_id)
);
CREATE TABLE IF NOT EXISTS favorites (
  user_id TEXT NOT NULL REFERENCES users(id), court_id TEXT NOT NULL REFERENCES courts(id),
  PRIMARY KEY (user_id, court_id)
);
CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL, body TEXT NOT NULL DEFAULT '', type TEXT NOT NULL DEFAULT 'info',
  read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS coaches (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, title TEXT, rating REAL DEFAULT 0, reviews_count INTEGER DEFAULT 0,
  rate_per_hour INTEGER NOT NULL, experience TEXT, image TEXT, specialties TEXT DEFAULT '[]',
  venues TEXT DEFAULT '[]', bio TEXT DEFAULT '', active INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS coach_sessions (
  id TEXT PRIMARY KEY, coach_id TEXT NOT NULL REFERENCES coaches(id), user_id TEXT NOT NULL REFERENCES users(id),
  venue TEXT, date TEXT NOT NULL, slot TEXT NOT NULL, focus TEXT, price INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'Terkonfirmasi', created_at TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_coach_slot ON coach_sessions(coach_id, date, slot) WHERE status = 'Terkonfirmasi';
CREATE TABLE IF NOT EXISTS payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL REFERENCES users(id),
  method TEXT NOT NULL, is_default INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS device_tokens (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  platform TEXT NOT NULL DEFAULT 'android',
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_device_user ON device_tokens(user_id);
`);

const tx = (fn) => {
  db.exec('BEGIN IMMEDIATE');
  try {
    const r = fn();
    db.exec('COMMIT');
    return r;
  } catch (e) {
    db.exec('ROLLBACK');
    throw e;
  }
};

require('./seed')(db);

module.exports = { db, tx };
