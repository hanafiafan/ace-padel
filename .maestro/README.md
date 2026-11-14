# PANDUAN AUTOMATED TESTING MAESTRO - ACE PADEL 🎾

Folder ini memuat test suite otomasi end-to-end (E2E) mobile menggunakan [Maestro](https://maestro.mobile.dev) untuk aplikasi **Ace Padel** (`dev.hellens.ace_padel`).

---

## 📋 Daftar Flow Maestro (YAML)

1. **`01_launch_and_onboarding.yaml`**
   - **Cakupan**: Pembukaan aplikasi dari state bersih, inspeksi branding `ACE PADEL`, onboarding masuk sebagai tamu, dan verifikasi tampilan beranda `Padel Action Now`.
   - **Assertion**: Pengecekan teks branding, CTA masuk tamu, dan widget beranda.

2. **`02_navigation_and_explore.yaml`**
   - **Cakupan**: Navigasi multi-tab 5 menu utama (`Home`, `Courts`, `Ranking`, `Bookings`, `Profile`) dan pengujian modal interaktif Peta Cluster Venue.
   - **Assertion**: Verifikasi header halaman, badge cluster Jakarta, dan komponen profil.

3. **`03_booking_and_gear_rental.yaml`** (Alur Transaksi & CRUD Utama)
   - **Cakupan**: Daftar akun uji baru (email unik per eksekusi) -> alur lengkap pemilihan lapangan -> cek spesifikasi FIP -> pemilihan tanggal & slot waktu -> sewa alat resmi turnamen (bola/raket) -> konfirmasi reservasi -> penerbitan E-Tiket digital QR -> pembukaan generator *Match Recap Story (Strava-Style)*.
   - **Assertion**: Verifikasi slot waktu, add-on gear, status booking berhasil, E-Tiket QR, dan kanvas story.

4. **`04_validation_and_error_handling.yaml`** (Validasi Kesalahan)
   - **Cakupan**: Form validasi autentikasi (nama minimal 2 karakter, format email valid, password minimal 8 karakter).
   - **Assertion**: Pengecekan pesan peringatan validasi input form.

---

## 🚀 Instalasi & Menjalankan

### Prasyarat (versi yang dipakai pada pengujian)
* Maestro **2.12.1** dan Java (JDK 17+).
* Android SDK Platform Tools (`adb`) di PATH; emulator Android 15 (API 35) aktif, atau HP fisik via USB debugging.
* Server backend lokal berjalan di port 3001 (`cd server && npm install && PORT=3001 npm start`). Emulator mengaksesnya lewat `10.0.2.2:3001`.
* Aplikasi debug terpasang: `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

### Instalasi Maestro
Unduh rilis resmi dari <https://github.com/mobile-dev-inc/maestro/releases> (`maestro.zip`), ekstrak, lalu tambahkan `maestro/bin` ke PATH. Alternatif resmi: <https://maestro.mobile.dev/getting-started/installing-maestro>.

### Perintah eksekusi
Flow 03 mendaftarkan akun uji baru. **Password tidak disimpan di repository**; berikan lewat variabel lingkungan:

```bash
cd .maestro
maestro test -e UAT_PASSWORD='<password-uji-min-8-karakter>' \
  --format junit --output results/hasil_maestro.xml \
  --debug-output results/debug .
```
Satu flow saja: `maestro test -e UAT_PASSWORD=... 03_booking_and_gear_rental.yaml`. Flow 01, 02, dan 04 tidak memerlukan password.

### Hasil eksekusi (14 Nov 2026, emulator Android 15 API 35)
| Eksekusi | Hasil | Durasi | Berkas |
|---|---|---|---|
| Run 1 | 4/4 flow lulus | 2m 36s | `results/run1/` (`run.log`, `hasil_maestro.xml`) |
| Run 2 | 4/4 flow lulus | 2m 49s | `results/run2/` |

Screenshot langkah penting (dari Run 2): `results/screenshots/`.

### Catatan teknis yang ditemukan saat menyusun flow
* Flutter menggabungkan teks sekelompok widget menjadi satu node aksesibilitas (contoh: `"Courts\nTab 2 of 5"`), sehingga pencocokan memakai regex parsial (`.*teks.*`).
* `hideKeyboard` pada Android mengirim tombol Back dan menutup aplikasi di layar login; flow memakai `pressKey: Enter`.
* Slot jam dipilih acak lalu diulang (`retry`) bila bentrok dengan slot yang sudah terpesan oleh eksekusi sebelumnya (server menolak double-booking).
* Flow dimulai dengan `clearState: true` agar tidak bergantung pada sesi sebelumnya.
