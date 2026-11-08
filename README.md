# Ace Padel 🎾

Aplikasi Reservasi & Ekosistem Padel Modern Full-Stack (Flutter Mobile App + Node.js Backend REST API).
Didesain dengan palet warna premium: Royal Blue (`#2334DB`), Dark Blue (`#151C4E`), Lime Accent (`#C7F23C`), Slate (`#6B7291`), dan Cloud Canvas (`#F2F4FB`).

---

## 🚀 Fitur Unggulan

### 1. Reservasi Lapangan & Anti Double-Booking
- **Eksplorasi Venue & Lapangan**: Filter kota (Jakarta, Tangerang, Badung/Bali), jenis lapangan (*Indoor / Outdoor*), dan sorting berdasarkan rating tertinggi atau harga termurah.
- **Pengecekan Ketersediaan Real-Time**: Kalender 7 hari ke depan dengan slot jam (08:00 – 22:00 WIB), terintegrasi dengan backend API pencegah konflik pemesanan (*Anti Double-Booking*).
- **Sewa Alat & Perlengkapan Tambahan (Add-Ons)**:
  - Sewa Raket Bullpadel Pro (+Rp30k/raket)
  - 1 Can Bola Baru Standar Turnamen 3 Pcs (+Rp75k/kaleng)
  - Paket Handuk Bersih & 2 Air Mineral Dingin (+Rp15k/paket)
  - Kontrol stepper `[-]` & `[+]` dengan kalkulasi total dinamis.
- **Voucher Promo**: Validasi kode voucher otomatis (misal: `ACEWEEKEND` diskon Rp25.000).

### 2. Simulasi Pembayaran Interaktif
- **QRIS Instant Pay**: Modal QRIS standar nasional dengan grafis QR berlogo padel, countdown batas waktu 15:00, dan tombol *Simulasikan Pembayaran Berhasil*.
- **Virtual Account (BCA & Mandiri)**: Nomor VA instan dengan tombol *Salin Nomor VA* 1-tap dan simulasi transfer bank.
- **Bayar di Venue (On-Site)**: Opsi pembayaran tunai / EDC langsung di meja resepsionis.

### 3. E-Ticket Digital & Check-In QR
- Tiket digital dilengkapi QR Code unik (`ACE-C1-1900`).
- Rincian jadwal, venue, metode bayar, dan perlengkapan tambahan yang disewa.
- Tombol integrasi kalender dan penunjuk arah (Google Maps).

### 4. Komunitas & Social Leaderboard
- **Filter Segmented `[ Global | Teman ]`**: Papan peringkat dinamis dengan podium 3 besar dan kartu posisi kamu (`# Kamu`).
- **Tambah Teman Interaktif**:
  - Modal pencarian pemain berdasarkan nama atau `@username`.
  - Tombol toggle cepat `+ Teman` / `✓ Teman` langsung pada kartu pemain.

### 5. Direktori & Penjadwalan Pelatih Padel (Coaching & Clinic)
- Roster pelatih berlisensi internasional (FIP Certified Level 2, mantan atlet nasional).
- Filter spesialisasi: *Bandeja & Vibora*, *Pemula & Wanita*, *Wall Defense*, *Taktik Double*.
- Modal reservasi sesi private coaching 1-on-1 dengan pemilihan venue, jam, dan fokus materi.

### 6. Mabar Komunitas (Open Matches)
- Gabung slot mabar terbuka (*Casual*, *Beginner*, *Intermediate*, *Advanced*).
- Fitur *Buat Slot Mabar Sendiri* untuk mengundang pemain komunitas padel lainnya.

### 7. Portal Mitra Lapangan (Venue Owner Dashboard)
- **Pemindai & Validasi QR Tiket Masuk**: Check-in pemain otomatis via backend API.
- **Manajemen Jadwal Slot**: Blokir slot untuk perawatan/maintenance lapangan dan buka kembali.
- **Laporan & Statistik Pendapatan**: Monitoring okupansi dan revenue harian/bulanan.

---

## 📁 Struktur Proyek

```
ace-padel/
├── lib/
│   ├── main.dart               # Entrypoint aplikasi + Root Bottom Navigation (5 tab)
│   ├── theme.dart              # Sistem tema, tipografi, dan token warna (AP)
│   ├── data.dart               # Data model Court, Booking, Player, Coach, Add-On, Match
│   ├── store.dart              # State management: BookingStore, FriendStore, MatchStore, UserStore
│   ├── widgets.dart            # Komponen UI umum (AceLogo, FeaturedCard, CourtRow, SectionHeader)
│   ├── services/
│   │   └── api_service.dart    # HTTP REST client dengan auto-fallback offline
│   └── screens/
│       ├── home_screen.dart           # Beranda, kategori, promo banner, sorotan mabar & pelatih
│       ├── courts_screen.dart         # Katalog lapangan dengan pencarian & multi-filter
│       ├── booking_screen.dart        # Pemilihan tanggal & slot jam real-time
│       ├── confirm_screen.dart        # Konfirmasi, sewa add-on, voucher, simulator QRIS & VA
│       ├── ticket_screen.dart         # E-Ticket digital dengan QR check-in & daftar alat sewa
│       ├── bookings_screen.dart       # Daftar booking aktif & riwayat pembatalan
│       ├── leaderboard_screen.dart    # Leaderboard Global vs Teman + modal Tambah Teman
│       ├── coaches_screen.dart        # Direktori & booking sesi private coach padel
│       ├── matches_screen.dart        # Mabar komunitas & buat slot match terbuka
│       └── profile_screen.dart        # Profil, badge pencapaian, dan Portal Mitra Lapangan
├── server/                     # Backend REST API Server (Node.js + Express)
│   ├── src/
│   │   ├── index.js            # Express server entrypoint (Port 3001)
│   │   ├── db.js               # Persistensi database file JSON
│   │   └── routes/             # courts, bookings, friends, matches, vouchers, venue, auth
│   ├── data/
│   │   └── db.json             # File penyimpanan database lokal
│   └── test/
│       └── api.test.js         # Automated test suite untuk seluruh REST endpoints
└── test/
    ├── store_test.dart         # Unit tests logika reservasi, add-ons, voucher, dan teman
    └── widget_test.dart        # Automated UI widget & navigation integration tests
```

---

## 🛠️ Panduan Menjalankan Sistem

### 1. Menjalankan Backend Server (Port 3001)
```bash
cd server
npm install
node src/index.js
# Backend aktif di http://localhost:3001 (Host) / http://10.0.2.2:3001 (Android Emulator)
```

Untuk menjalankan automated test suite backend (8 test suites):
```bash
cd server
npm test
```

### 2. Menjalankan Aplikasi di Android Emulator
Pastikan emulator Android (`AcePadel_Pixel` atau device terhubung lainnya) aktif:
```bash
flutter pub get
flutter run
```

Atau pasang APK langsung via ADB:
```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n dev.hellens.ace_padel/.MainActivity
```

---

## 📦 Build Release untuk Google Play Store

Untuk menghasilkan **Android App Bundle (.aab)** resmi yang siap diunggah ke Google Play Console:

```bash
flutter build appbundle --release
```

* File hasil build: `build/app/outputs/bundle/release/app-release.aab`
* Signing Keystore: `android/app/release-keystore.jks` (alias: `acepadel`)
* Konfigurasi Signing: `android/key.properties`

### 🔑 Fingerprint Release Keystore (Untuk Firebase Console):
* **Release SHA-1**: `9E:83:CE:5E:8D:38:20:BD:88:B8:2D:FC:45:D8:61:09:E8:40:9C:0B`
* **Release SHA-256**: `6A:35:E2:73:16:66:E3:38:BE:37:DE:D4:17:69:FB:B6:3D:2D:58:DB:56:A5:F6:45:5B:23:4F:96:6A:2E:94:36`

---

## 📄 Dokumen Publikasi & Legal

* **Kebijakan Privasi (Markdown)**: [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)
* **Kebijakan Privasi (HTML Siap Host)**: [`PRIVACY_POLICY.html`](PRIVACY_POLICY.html) *(siap dipasang di https://hellens.dev/privacy-policy)*
* **Metadata Google Play Store**: [`PLAY_STORE_METADATA.md`](PLAY_STORE_METADATA.md) *(Judul, deskripsi singkat/panjang, tag ASO, dan jawaban kuesioner Data Safety)*
* **Backend Docker Container**: [`server/Dockerfile`](server/Dockerfile) *(siap deploy ke Google Cloud Run, Railway, atau VPS)*

---

## 🏢 Pengembang & Hak Cipta

Aplikasi **Ace Padel** dikembangkan oleh **[hellens.dev](https://hellens.dev)**.
- **Package Name / Application ID**: `dev.hellens.ace_padel`
- **Official Website**: [https://hellens.dev](https://hellens.dev)
- **Support Email**: support@hellens.dev

---

## 🧪 Hasil Pengujian & Kualitas Kode

- **Flutter Analyze**: `flutter analyze` -> **0 issues found** (100% clean).
- **Flutter Automated Tests**: `flutter test` -> **16/16 tests passed** (unit test store, booking kalkulasi add-ons, coaching flow, widget test 5 tab, Google auth).
- **Backend Node.js Tests**: `cd server && npm test` -> **9/9 test suites passed** (100% clean).
- **Offline-First Resilience**: Jika server tidak aktif atau koneksi terputus, aplikasi mobile secara transparan beralih ke state memory lokal tanpa mengalami crash.
