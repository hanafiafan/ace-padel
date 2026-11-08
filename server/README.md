# Ace Padel — Backend REST API 🎾

Server REST API untuk aplikasi mobile Ace Padel. Dibangun menggunakan **Node.js + Express** dengan penyimpanan file JSON yang persisten (`data/db.json`).

---

## 🚀 Cara Menjalankan

### 1. Install Dependensi (jika belum)
```bash
cd server
npm install
```

### 2. Jalankan Server
```bash
npm start
# atau dengan auto-reload saat pengembangan:
npm run dev
```
Server akan aktif di: **`http://localhost:3000`**

### 3. Menjalankan Pengujian API (Automated Tests)
```bash
npm test
```

---

## 📡 Daftar Endpoint API

| Method | Endpoint | Deskripsi |
|---|---|---|
| `GET` | `/api/health` | Status kesehatan server |
| `GET` | `/api/courts` | Daftar lapangan (Filter: `q`, `indoor`, `city`, `facility`, `sortBy`) |
| `GET` | `/api/courts/:id` | Detail lapangan & ulasan pengguna |
| `GET` | `/api/courts/:id/slots?date=YYYY-MM-DD` | Ketersediaan slot operasional (08:00–22:00) |
| `GET` | `/api/courts/meta/cities` | Daftar kota yang tersedia |
| `GET` | `/api/bookings` | Daftar reservasi aktif & riwayat |
| `POST` | `/api/bookings` | Buat reservasi baru (Proteksi anti double-booking & validasi voucher) |
| `DELETE` | `/api/bookings/:id` | Batalkan reservasi (slot jam otomatis dibuka kembali) |
| `GET` | `/api/matches` | Daftar sesi mabar komunitas terbuka |
| `POST` | `/api/matches` | Buat sesi mabar komunitas baru |
| `POST` | `/api/matches/:id/join` | Gabung atau batalkan partisipasi slot mabar |
| `GET` | `/api/vouchers` | Daftar voucher promo aktif |
| `POST` | `/api/vouchers/validate` | Validasi kode promo & hitung potongan diskon |
| `GET` | `/api/reviews/:courtId` | Daftar rating & review per lapangan |
| `POST` | `/api/reviews` | Kirim rating & ulasan baru |
| `POST` | `/api/auth/login` | Login / inisialisasi akun |
| `GET` | `/api/auth/profile` | Profil pemain & ringkasan statistik |
| `PUT` | `/api/auth/profile` | Ubah nama, nomor telepon, dan skill level |

---

## 🔒 Aturan Bisnis yang Diuji
1. **Anti Double-Booking**: Mencegah pemesanan slot jam yang sama pada lapangan dan tanggal yang sama (mengembalikan HTTP 409 Conflict).
2. **Kalkulasi Voucher**: Menghitung potongan nominal dan persentase sesuai batas minimum transaksi.
3. **Pelepasan Slot Real-time**: Pembatalan reservasi otomatis membebaskan slot jam agar pemain lain dapat memesannya kembali.

