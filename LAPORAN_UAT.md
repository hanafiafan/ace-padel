# LAPORAN USER ACCEPTANCE TESTING (UAT): ACE PADEL

| | |
|:--|:--|
| **Mata kuliah** | Mobile Testing, TI23B (UTS Ganjil 2026/2027) |
| **Dosen pengampu** | Triyono M.Kom |
| **Penyusun** | **[ISI: nama lengkap, NIM, peran]** |
| **Aplikasi** | Ace Padel (`dev.hellens.ace_padel`), reservasi lapangan dan komunitas padel (Flutter + backend Node.js) |
| **Versi diuji** | 1.0.0+1 (debug build) |
| **Tanggal pengujian** | 14 November 2026 |
| **Lingkungan** | Emulator Android 15 (API 35, AVD `ace_padel`), Flutter 3.47.6, Maestro 2.12.1, OpenJDK 17, backend lokal `localhost:3001` |

> Semua hasil di bawah berasal dari eksekusi nyata pada tanggal di atas. Hasil otomatis tersimpan di `.maestro/results/` (log, JUnit XML, screenshot). Pengujian hanya dilakukan di **emulator**; tidak ada perangkat fisik.

---

## 1. Tujuan Pengujian
Memastikan alur utama pemain berjalan sesuai harapan pengguna: masuk sebagai tamu, menelusuri lapangan, memesan lapangan beserta sewa gear, menerima e-ticket, membagikan recap pertandingan, dan ditolaknya input yang tidak valid.

## 2. Persona / Peran Pengguna
| Peran | Deskripsi | Dipakai pada |
|:--|:--|:--|
| Tamu | Pengguna baru yang belum punya akun, hanya melihat-lihat | UAT-01, UAT-02 |
| Pemain terdaftar | Pemain yang sudah masuk dan memesan lapangan | UAT-03, UAT-04, UAT-06 |
| Calon pengguna | Pengguna yang mendaftar akun baru | UAT-05 |

## 3. Prasyarat Umum
Emulator aktif, backend lokal berjalan di port 3001, APK debug terpasang, data awal (seed) server termuat. Cara menjalankan lengkap ada di `.maestro/README.md`.

## 4. Skenario UAT

### UAT-01: Masuk sebagai tamu dan melihat beranda
* **Persona**: Tamu. **Prasyarat**: aplikasi dari state bersih.
* **Langkah**: buka aplikasi, pilih "Lihat-lihat dulu sebagai Tamu", amati beranda.
* **Kriteria penerimaan**: layar login memuat branding Ace Padel dan opsi tamu; beranda memuat header "Padel Action Now", strip tanggal, Quick Start, dan tombol Pesan Lapangan.
* **Hasil aktual**: sesuai kriteria. Beranda menyapa "Halo, Tamu".
* **Bukti**: flow `01_launch_and_onboarding.yaml` (Run 1 dan Run 2 lulus).
* **Status**: **LULUS**

### UAT-02: Navigasi tab dan peta venue
* **Persona**: Tamu.
* **Langkah**: buka tab Courts, buka Peta venue, kembali, buka Ranking, Bookings, Profile, lalu Home.
* **Kriteria penerimaan**: tiap tab menampilkan judul yang benar; peta memuat klaster venue (Jakarta Selatan, 6 arena).
* **Hasil aktual**: sesuai kriteria.
* **Bukti**: flow `02_navigation_and_explore.yaml` (Run 1 dan Run 2 lulus).
* **Status**: **LULUS**

### UAT-03: Reservasi lapangan dan e-ticket (alur transaksi utama)
* **Persona**: Pemain terdaftar. **Prasyarat**: akun uji baru dibuat di dalam flow.
* **Langkah**: daftar akun, buka Courts, pilih Center Glass Court, pilih tanggal besok, pilih slot, Lanjut Konfirmasi, buka kategori Pro Rental Gear, Konfirmasi Booking, buka E-Ticket, buka Match Recap Story.
* **Kriteria penerimaan**: slot terpilih mengaktifkan tombol lanjut; halaman sukses menampilkan kode reservasi; e-ticket berstatus Terkonfirmasi dengan QR.
* **Hasil aktual**: sesuai kriteria. Contoh: kode `ACE-C3-2000-6818`, Minggu 15 Nov 2026 pukul 20:00, total Rp260k.
* **Bukti**: flow `03_booking_and_gear_rental.yaml` (Run 1 dan Run 2 lulus); screenshot `03_01` sampai `03_06` di `.maestro/results/screenshots/`.
* **Keterbatasan yang jujur**:
  * Flow otomatis hanya membuka kategori gear, belum menambahkan item sewa. Penambahan raket diuji **manual**: Bullpadel Pro (+Rp30k) membuat total menjadi Rp250k dan tercatat di e-ticket.
  * Guest yang menekan Lanjut Konfirmasi diarahkan ke layar login. Ini perilaku yang benar, dan sebab flow ini mendaftarkan akun dulu.
* **Status**: **LULUS (dengan keterbatasan di atas)**

### UAT-04: E-ticket dan recap story
* **Persona**: Pemain terdaftar.
* **Langkah**: dari e-ticket, ketuk "Buat Match Recap Story".
* **Kriteria penerimaan**: layar "MATCH RECAP // STORY" tampil dengan kartu 9:16 dan opsi kustomisasi.
* **Hasil aktual**: layar tampil tanpa error layout setelah perbaikan temuan T-03 (lihat bagian 6).
* **Bukti**: screenshot `03_05_eticket.png`, `03_06_story.png`.
* **Catatan**: isi kartu story (lawan, skor, DUPR 3.60, 742 kcal, 164 BPM) masih **data contoh tetap**, belum dari pertandingan nyata (lihat T-10).
* **Status**: **LULUS (tampilan); data masih contoh**

### UAT-05: Validasi input form daftar
* **Persona**: Calon pengguna.
* **Langkah**: kirim form kosong; isi nama saja; isi nama dan email valid dengan password "123".
* **Kriteria penerimaan**: masing-masing menampilkan pesan "Nama minimal 2 karakter.", "Format email tidak valid.", "Password minimal 8 karakter."
* **Hasil aktual**: ketiga pesan muncul sesuai urutan.
* **Bukti**: flow `04_validation_and_error_handling.yaml` (Run 1 dan Run 2 lulus); screenshot `04_01` sampai `04_03`.
* **Status**: **LULUS**

### UAT-06: Konsistensi data Profil dan Pengaturan (uji manual)
* **Persona**: Pemain terdaftar.
* **Langkah**: buka Profil dan Pengaturan; bandingkan angka dengan data akun; ubah dan periksa fungsi tiap pengaturan.
* **Hasil aktual awal (GAGAL)**: lihat temuan T-02, T-05, T-06 di bawah. Angka streak, heatmap, dan kalori palsu; status API, ukuran cache, dan tombol ekspor hanya pura-pura.
* **Hasil setelah perbaikan**: setelah satu booking dibuat, hari main berubah menjadi 1 dan heatmap menyala pada hari yang benar; status API menampilkan ping nyata; cache dihitung dari cache gambar dan benar-benar dibersihkan; ekspor menyalin JSON ke clipboard.
* **Status awal**: **GAGAL**. **Status ulang uji**: **LULUS**

---

## 5. Ringkasan Hasil

| No | Skenario | Jenis | Cara uji | Status |
|:--|:--|:--|:--|:--|
| 1 | UAT-01 Tamu dan beranda | Alur utama | Maestro (2 eksekusi) | LULUS |
| 2 | UAT-02 Navigasi dan peta | Alur utama | Maestro (2 eksekusi) | LULUS |
| 3 | UAT-03 Reservasi dan e-ticket | Transaksi | Maestro (2 eksekusi) + manual | LULUS, dengan keterbatasan |
| 4 | UAT-04 E-ticket dan story | Fitur sosial | Maestro + manual | LULUS, data story contoh |
| 5 | UAT-05 Validasi form | Input tidak valid | Maestro (2 eksekusi) | LULUS |
| 6 | UAT-06 Profil dan Pengaturan | Konsistensi data | Manual | GAGAL lalu LULUS setelah perbaikan |

**Otomasi Maestro**: 4 flow, 3 eksekusi penuh, **4/4 lulus pada ketiganya** (2m36s, 2m49s, 2m44s). Eksekusi ke-3 memakai build terbaru setelah perbaikan T-08/T-09. Log dan XML ada di `.maestro/results/run1/`, `run2/`, `run3/`.

---

## 6. Temuan dan Tindak Lanjut

| ID | Temuan | Dampak | Status |
|:--|:--|:--|:--|
| T-01 | Beranda memuat konten tenis (Davis Cup, Laver Cup, Hopman Cup) di aplikasi padel | Konten salah | **Diperbaiki** |
| T-02 | Profil: "24 day streak", heatmap acak, 842 kcal hardcode, bertentangan dengan "Match Time 0:00" | Data menyesatkan | **Diperbaiki** (dari data booking) |
| T-03 | Kartu statistik di layar story overflow 2,4 px (banner debug merah), badge "+0.18" terpotong | Cacat tampilan | **Diperbaiki** |
| T-04 | Layar story menyatakan "VERIFIED MATCH // WPT OFFICIAL SENSOR" tanpa sensor | Klaim palsu jika dibagikan | **Diperbaiki** |
| T-05 | Pengaturan: status API selalu "ONLINE 18ms", ukuran cache selalu 28.4 MB, Bersihkan Cache tidak membersihkan | Fitur pura-pura | **Diperbaiki** |
| T-06 | Ekspor data hanya menampilkan pesan sukses tanpa ekspor | Fitur pura-pura | **Diperbaiki** (salin JSON ke clipboard) |
| T-07 | Garis dekoratif pojok atas bertumpuk dengan status bar | Kosmetik | **Diperbaiki** |
| T-08 | Tombol kembali gelap di atas foto gelap pada layar story dan detail venue, nyaris tak terlihat | Aksesibilitas | **Diperbaiki** (story: ikon putih; detail venue: panah putih dengan latar lingkaran gelap, dicek di emulator) |
| T-09 | Layar login menampilkan tautan internal "Panduan & Credentials Google Console" | Teks pengembang terlihat pengguna | **Diperbaiki** (hanya tampil di build debug); belum diverifikasi pada build release |
| T-10 | Isi kartu story masih data contoh tetap, bukan dari pertandingan | Fitur belum nyata | **Terbuka** |
| T-11 | Toggle "Sinkronisasi Apple Health / Health Connect" hanya menyimpan preferensi, belum ada integrasi | Fitur belum nyata | **Terbuka** |
| T-12 | Flutter menggabungkan teks widget menjadi satu node aksesibilitas | Menyulitkan uji otomatis dan pembaca layar | **Terbuka** (disiasati dengan regex di Maestro) |

## 7. Batasan Pengujian
* Hanya emulator Android 15 (API 35); tidak ada perangkat fisik dan tidak ada iOS.
* Masuk dengan Google dan pembayaran DOKU tidak diuji (mode simulasi/lingkungan dev).
* Pengujian beban dan keamanan mendalam tidak dilakukan.
* Flow 03 belum menambah item sewa gear secara otomatis (lihat UAT-03).
* Data seed bersifat contoh; angka ranking dan leaderboard berasal dari data seed server.

## 8. Kesimpulan
Alur utama (tamu, navigasi, pendaftaran, reservasi, e-ticket, validasi) berjalan dan dapat diulang otomatis (4/4 flow, dua kali). Pengujian manual menemukan sembilan cacat nyata yang sudah diperbaiki, serta tiga temuan yang masih terbuka (T-10, T-11, T-12). Eksekusi Maestro ketiga dijalankan setelah perbaikan T-08 dan T-09 dan tetap 4/4 lulus. Aplikasi layak untuk demo end-to-end dengan catatan keterbatasan di atas, belum layak disebut siap produksi.
