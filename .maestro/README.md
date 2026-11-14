# PANDUAN AUTOMATED TESTING MAESTRO - ACE PADEL 🎾

Folder ini memuat test suite otomasi end-to-end (E2E) mobile menggunakan [Maestro](https://maestro.mobile.dev) untuk aplikasi **Ace Padel** (`dev.hellens.ace_padel`).

---

## 📋 Daftar Flow Maestro (YAML)

1. **`01_launch_and_onboarding.yaml`**
   - **Cakupan**: Pembukaan aplikasi (splash), inspeksi branding `ACE PADEL`, onboarding masuk sebagai tamu, dan verifikasi tampilan beranda `Tennis Action Now`.
   - **Assertion**: Pengecekan teks branding, CTA masuk tamu, dan widget beranda.

2. **`02_navigation_and_explore.yaml`**
   - **Cakupan**: Navigasi multi-tab 5 menu utama (`Home`, `Courts`, `Ranking`, `Bookings`, `Profile`) dan pengujian modal interaktif Peta Cluster Venue.
   - **Assertion**: Verifikasi header halaman, badge cluster Jakarta, dan komponen profil.

3. **`03_booking_and_gear_rental.yaml`** (Alur Transaksi & CRUD Utama)
   - **Cakupan**: Alur lengkap pemilihan lapangan -> cek spesifikasi FIP -> pemilihan tanggal & slot waktu -> sewa alat resmi turnamen (bola/raket) -> konfirmasi reservasi -> penerbitan E-Tiket digital QR -> pembukaan generator *Match Recap Story (Strava-Style)*.
   - **Assertion**: Verifikasi slot waktu, add-on gear, status booking berhasil, E-Tiket QR, dan kanvas story.

4. **`04_validation_and_error_handling.yaml`** (Validasi Kesalahan)
   - **Cakupan**: Form validasi autentikasi (nama minimal 2 karakter, format email valid, password minimal 8 karakter).
   - **Assertion**: Pengecekan pesan peringatan validasi input form.

---

## 🚀 Cara Instalasi Maestro & Prasyarat

### 1. Prasyarat Sistem
* macOS, Linux, atau Windows (WSL2).
* Android SDK & Platform Tools (`adb`) aktif di PATH.
* Emulator Android aktif atau HP fisik terhubung via USB Debugging.

### 2. Instalasi Maestro CLI
Jalankan perintah resmi instalasi Maestro:
```bash
curl -FsSL "https://get.maestro.mobile.dev" | bash
```
Pastikan biner `maestro` terdeteksi di terminal:
```bash
maestro --version
```

---

## 🏃‍♂️ Perintah Eksekusi Pengujian

Pastikan emulator aktif dan aplikasi Ace Padel telah terpasang:
```bash
adb devices
```

### Menjalankan Seluruh Suite Pengujian Sekaligus
```bash
maestro test .maestro/
```

### Menjalankan Pengujian per Skenario Flow
```bash
# 1. Flow Launch & Onboarding
maestro test .maestro/01_launch_and_onboarding.yaml

# 2. Flow Navigasi & Eksplorasi
maestro test .maestro/02_navigation_and_explore.yaml

# 3. Flow Transaksi Pemesanan & Sewa Alat (Core Flow)
maestro test .maestro/03_booking_and_gear_rental.yaml

# 4. Flow Validasi Input & Penanganan Error
maestro test .maestro/04_validation_and_error_handling.yaml
```

### Menghasilkan Rekaman / Video Hasil Eksekusi
```bash
maestro record --output-path=maestro_test_run.mp4 .maestro/
```
