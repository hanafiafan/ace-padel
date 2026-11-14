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

### 2. Pembayaran
Pembayaran online (QRIS / Virtual Account) diproses oleh DOKU Checkout; status dicek otomatis. Mode simulasi di bawah hanya aktif bila server berjalan dengan provider `simulated`.
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

## 🧪 Pengujian Otomatis & UAT (UTS Mobile Testing TI23B)

**Identitas** (isi sebelum dikumpulkan)

| Nama | NIM | Kelas | Peran |
|:--|:--|:--|:--|
| Muhammad Hanafi Afan Firdaus | 2301032321 | 23TIB1 (TI23B) | Full Stack |

**Tujuan aplikasi**: reservasi lapangan padel, mabar (main bareng), dan komunitas pemain. **Target pengguna**: pemain padel di Jabodetabek dan Bali, serta pemilik lapangan (portal mitra). **Alur utama yang diuji**: tamu, navigasi, daftar akun, pesan lapangan, e-ticket, recap story, validasi form. **Batasan pengujian**: emulator Android 15 saja, Google Sign-In dan pembayaran DOKU tidak diuji (lihat bagian 7 `LAPORAN_UAT.md`).

1. **User Acceptance Testing (UAT)**: [`LAPORAN_UAT.md`](LAPORAN_UAT.md) memuat 6 skenario (tujuan, persona/peran, kriteria penerimaan, prasyarat, langkah, hasil aktual, status, bukti), ringkasan hasil, dan 12 temuan beserta statusnya (10 diperbaiki). Hasil aktual berasal dari eksekusi nyata, termasuk satu skenario yang awalnya gagal lalu lulus setelah perbaikan.

2. **Automated E2E dengan Maestro**: [`.maestro/`](.maestro/) berisi 4 flow YAML dengan assertion:
   - `01_launch_and_onboarding.yaml`: peluncuran dari state bersih dan mode tamu.
   - `02_navigation_and_explore.yaml`: navigasi 5 tab dan peta venue.
   - `03_booking_and_gear_rental.yaml`: daftar akun uji, reservasi, e-ticket, recap story.
   - `04_validation_and_error_handling.yaml`: validasi form dan kondisi gagal.

   Hasil: **4/4 flow lulus pada tiga eksekusi**; log, JUnit XML, dan screenshot ada di `.maestro/results/`. Instalasi dan perintah eksekusi: [`.maestro/README.md`](.maestro/README.md). Flow 03 memerlukan password uji lewat `-e UAT_PASSWORD=...` (tidak disimpan di repository).

3. **APK / cara menjalankan**: `flutter build apk --debug` lalu `adb install -r build/app/outputs/flutter-apk/app-debug.apk`, dengan backend lokal aktif (lihat panduan di bawah).

4. **Tautan**: video penjelasan **[ISI: tempel link video]**, repository <https://github.com/hanafiafan/ace-padel>.

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

### 2. Menjalankan Aplikasi (terhubung ke backend nyata)
Aplikasi memakai API server (`server/API.md`): login email/password atau Google, booking, mabar, teman, notifikasi, dan portal pemilik lapangan semuanya lewat server. Katalog lapangan/pelatih jatuh kembali ke data bawaan bila server tidak terjangkau (muncul snackbar "offline").

Alamat API: `--dart-define=API_URL=...`; default debug `http://localhost:3001` (web/desktop) atau `http://10.0.2.2:3001` (Android emulator); release `https://acepadel.hellens.dev`.
```bash
# terminal 1: backend
cd server && npm install && npm start            # http://localhost:3001

# terminal 2: aplikasi
flutter pub get
flutter run                                       # Android emulator
flutter run -d chrome --dart-define=API_URL=http://localhost:3001   # web
```
Akun dev (hanya non-production): `player@acepadel.id / player12345`, `owner@acepadel.id / owner12345` (membuka Portal Mitra), `admin@acepadel.id / admin12345`. Untuk Google Sign-In di server dev tanpa kredensial: jalankan server dengan `ALLOW_UNVERIFIED_GOOGLE=1`.

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
- **Flutter Automated Tests**: `flutter test` -> unit test ApiService/store (mock HTTP: login, role, booking-pay-cancel, 409, 401, fallback offline) + widget test navigasi.
- **Backend Node.js Tests**: `cd server && npm test` -> **9/9 test suites passed** (100% clean).
- **Mode offline**: katalog lapangan & pelatih memakai data bawaan bila server tidak terjangkau; booking, mabar, teman, dan portal pemilik memerlukan server (pesan error ditampilkan).
