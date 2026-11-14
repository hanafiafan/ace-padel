# LAPORAN USER ACCEPTANCE TESTING (UAT)
## APLIKASI RESERVASI & KOMUNITAS PADEL: ACE PADEL 🎾

**Mata Kuliah:** Mobile Testing (TI23B)  
**Dosen Pengampu:** Triyono M.Kom  
**Proyek:** Pengujian Aplikasi Mobile dengan User Acceptance Testing dan Maestro  
**Target Aplikasi:** Ace Padel (`dev.hellens.ace_padel`)  
**Versi:** 1.0 (MVP)  
**Lingkungan Pengujian:** Android 15 (API 35 Emulator) & Google Pixel 8 Pro  

---

## 1. TUJUAN PENGUJIAN
Memastikan aplikasi Ace Padel memenuhi kriteria penerimaan pengguna akhir (pemain padel, host mabar, dan penyewa gear) dalam alur penelusuran lapangan, pemesanan slot waktu real-time, sewa perlengkapan asli, penerbitan e-tiket, hingga fitur sosial/pencapaian (*Strava-style match story*).

---

## 2. PERSONA PENGGUNA (ROLE)
1. **Afan Pratama (Casual Player)**: Pengguna yang ingin mencari lapangan terdekat, melihat ketersediaan slot, dan memesan lapangan tanpa ribet.
2. **Dewi Anggraini (Competitive / Mabar Host)**: Pemain aktif yang ingin bergabung ke slot match doubles dan memantau peringkat DUPR.
3. **Kevin Sanjaya (Equipment Enthusiast)**: Pemain yang membutuhkan sewa raket turnamen berlisensi (Bullpadel / Babolat) dan bola resmi FIP sebelum bertanding.

---

## 3. SKENARIO USER ACCEPTANCE TESTING (UAT)

### UAT-01: Onboarding Tamu & Eksplorasi Beranda Turnamen
* **Tujuan**: Memastikan pengguna baru dapat langsung melihat ringkasan turnamen dan venue tanpa harus mendaftar terlebih dahulu.
* **Persona**: Afan Pratama (Casual Player)
* **Prasyarat**: Aplikasi baru dipasang / mode tamu aktif.
* **Langkah Pengujian**:
  1. Buka aplikasi Ace Padel.
  2. Pada halaman pembuka/login, pilih opsi *"Lihat-lihat dulu sebagai Tamu"*.
  3. Amati tampilan beranda utama (*Tennis Action Now*).
* **Kriteria Penerimaan**: Beranda memuat header turnamen, pemilih tanggal 7 hari, kartu quick start, dan kategori aksi utama.
* **Hasil Aktual**: Header biru royal memuat widget turnamen, filter hari aktif, dan kartu quick start tampil presisi tanpa error.
* **Status**: **PASS (LULUS)**

---

### UAT-02: Penelusuran Lapangan & Peta Cluster Venue
* **Tujuan**: Memastikan pemain dapat menavigasi katalog arena, memfilter berdasarkan kota/jenis lapangan, serta membuka peta cluster venue.
* **Persona**: Afan Pratama
* **Prasyarat**: Berada pada tab *Courts*.
* **Langkah Pengujian**:
  1. Ketuk tab menu *Courts* pada bilah navigasi bawah.
  2. Ketuk tombol *PETA* di baris judul atas.
  3. Periksa daftar cluster regional venue (Jakarta Selatan, Bali Coastal, Tangerang & BSD).
  4. Pilih salah satu cluster, misalnya *Jakarta Selatan*.
* **Kriteria Penerimaan**: Modal peta cluster muncul rapi, menampilkan rincian nama arena dan memperbarui filter kota.
* **Hasil Aktual**: Modal *PETA CLUSTER VENUE* terbuka dengan aksen warna regional, tombol *Pilih* berfungsi responsif.
* **Status**: **PASS (LULUS)**

---

### UAT-03: Reservasi Lapangan, Pemilihan Slot Waktu & Sewa Gear Resmi
* **Tujuan**: Memvalidasi alur transaksi utama pemesanan lapangan dan penambahan sewa alat resmi (raket/bola turnamen).
* **Persona**: Kevin Sanjaya (Equipment Enthusiast)
* **Prasyarat**: Memilih salah satu venue (misal: *Center Glass Court*).
* **Langkah Pengujian**:
  1. Ketuk kartu *Center Glass Court*.
  2. Buka bagian spesifikasi lapangan dan verifikasi visualizer lapangan FIP.
  3. Pilih tanggal bermain (misal: Sabtu 14) dan slot waktu yang tersedia (09:00).
  4. Ketuk *LANJUT KONFIRMASI*.
  5. Pada bagian *PRO RENTAL GEAR*, pilih kategori *BOLA RESMI (3)* dan tambahkan 1 kaleng bola Head Pro+.
  6. Pilih metode bayar di tempat dan ketuk *KONFIRMASI BOOKING SEKARANG*.
* **Kriteria Penerimaan**: Total harga terakumulasi otomatis dengan biaya sewa gear; sistem menyimpan reservasi dan menampilkan halaman sukses booking.
* **Hasil Aktual**: Harga terhitung tepat, stepper kuantitas responsif, booking tersimpan dengan ID unik dan tombol *Lihat E-Tiket* aktif.
* **Status**: **PASS (LULUS)**

---

### UAT-04: Digital E-Ticket & Generator Match Recap Story (Strava-Style)
* **Tujuan**: Memastikan e-tiket menampilkan QR Code check-in yang sah serta menyediakan template story visual yang membanggakan untuk dibagikan ke media sosial.
* **Persona**: Dewi Anggraini (Competitive Player)
* **Prasyarat**: Memiliki reservasi aktif yang berhasil dibuat pada UAT-03.
* **Langkah Pengujian**:
  1. Pada layar sukses booking (atau tab *Bookings*), ketuk *Lihat E-Tiket*.
  2. Periksa QR Code check-in, rincian venue, jam, dan item sewa.
  3. Ketuk tombol *BUAT MATCH RECAP STORY (STRAVA-STYLE)*.
  4. Sesuaikan toggle kustomisasi (Foto latar lapangan, rating DUPR, kalori KCAL).
  5. Ketuk *BAGIKAN KE INSTAGRAM STORY & WA*.
* **Kriteria Penerimaan**: Canvas visual 9:16 tersaji dengan grafis lapangan, metrik DUPR (+0.18), kalori (742 KCAL), dan tautan tersalin ke clipboard.
* **Hasil Aktual**: Kartu story tampil bergaya athletic-cyberpunk dengan kontras tinggi, toggle kustomisasi bekerja real-time, dan dialog konfirmasi salin berhasil.
* **Status**: **PASS (LULUS)**

---

### UAT-05: Validasi Input Formulir & Penanganan Error
* **Tujuan**: Mencegah kesalahan data akun pengguna dengan validasi formulir berlapis (kondisi gagal).
* **Persona**: Afan Pratama
* **Prasyarat**: Berada pada formulir pendaftaran akun baru.
* **Langkah Pengujian**:
  1. Buka tab *Profile* -> ketuk *Masuk / Daftar* -> pilih *Daftar*.
  2. Langsung ketuk tombol *Daftar* tanpa mengisi nama.
  3. Verifikasi munculnya pesan error *"Nama minimal 2 karakter."*.
  4. Masukkan nama "Afan", biarkan email kosong/salah, ketuk *Daftar*.
  5. Verifikasi munculnya pesan error *"Format email tidak valid."*.
* **Kriteria Penerimaan**: Sistem memblokir pengiriman formulir invalid dan menampilkan pesan kesalahan yang jelas dan spesifik.
* **Hasil Aktual**: Validasi formulir menahan submit dan pesan error merah tampil informatif di atas tombol.
* **Status**: **PASS (LULUS)**

---

## 4. RINGKASAN HASIL & STATUS KELAYAKAN

| No | Skenario UAT | Kategori | Hasil Pengujian | Status |
|:---|:---|:---|:---|:---|
| 1 | UAT-01: Onboarding Tamu & Beranda | Eksplorasi & Navigasi | Tampil presisi tanpa hambatan | **PASS** |
| 2 | UAT-02: Penelusuran Lapangan & Peta | Filter & Discovery | Modal peta & filter responsif | **PASS** |
| 3 | UAT-03: Reservasi Lapangan & Sewa Gear | Transaksi Inti (CRUD) | Anti double-booking & total kalkulasi akurat | **PASS** |
| 4 | UAT-04: E-Tiket QR & Strava Story | Fitur Sosial & Tiket | QR code aktif & canvas story premium | **PASS** |
| 5 | UAT-05: Validasi Input & Error | Validasi & Keamanan | Error dicegah di boundary formulir | **PASS** |

**Tingkat Kelulusan (Pass Rate):** 100% (5 dari 5 Skenario LULUS)  
**Kesimpulan:** Aplikasi **Ace Padel v1.0** memenuhi seluruh kriteria penerimaan fungsional, performa visual, dan ketentuan teknis UTS Mobile Testing. Aplikasi dinyatakan **SIAP RILIS (PRODUCTION / DEMO READY)**.
