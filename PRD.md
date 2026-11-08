# PRD — Ace Padel

**Produk:** Aplikasi mobile reservasi lapangan padel
**Platform:** Flutter (Android & iOS)
**Versi dokumen:** 1.0 — 2026-10-05

---

## 1. Ringkasan

Ace Padel adalah aplikasi untuk mencari, memesan, dan mengelola reservasi lapangan
padel. Pengguna memilih venue/lapangan, memilih tanggal dan slot jam, lalu
mengonfirmasi booking. Fokus MVP: alur pesan lapangan yang cepat dan mulus dengan
tampilan modern (tema royal blue + aksen lime, mengikuti referensi desain).

## 2. Masalah & Tujuan

| Masalah | Tujuan |
|---|---|
| Booking padel masih via chat/telepon, lambat | Booking mandiri < 30 detik |
| Sulit tahu slot mana yang kosong | Jadwal slot real-time per lapangan |
| Tidak ada riwayat booking terpusat | Daftar booking aktif & lampau di satu tempat |

**Metrik sukses (MVP):** booking berhasil / sesi, waktu rata-rata sampai konfirmasi,
jumlah slot double-booking = 0.

## 3. Target Pengguna

- **Pemain padel kasual** — cari lapangan dekat, harga jelas, jam fleksibel.
- **Member reguler** — booking rutin, lihat riwayat.

## 4. Lingkup MVP

### In-scope
1. **Beranda** — hero/banner, lapangan unggulan, kategori cepat, lapangan terdekat.
2. **Pencarian & daftar lapangan** — list dengan rating, lokasi, harga/jam, indoor/outdoor.
3. **Detail lapangan & booking** — pilih tanggal (7 hari ke depan), pilih slot jam,
   konfirmasi. Slot yang sudah dipesan ditandai nonaktif.
4. **Booking saya** — daftar reservasi aktif + batalkan.
5. **Profil** — info akun, ringkasan statistik, menu pengaturan (statis di MVP).

### Out-of-scope (MVP)
- Pembayaran online (pakai status "bayar di tempat" dulu).
- Login/registrasi backend nyata (auth asli menyusul).
- Notifikasi push, chat, rating oleh user, multi-bahasa.
- Data real-time dari server (MVP pakai data lokal in-memory).

> ponytail: MVP tanpa backend. State booking disimpan in-memory; ganti ke API saat perlu.

## 5. User Stories

- Sebagai pemain, saya ingin **melihat lapangan unggulan** di beranda agar cepat memutuskan.
- Sebagai pemain, saya ingin **memfilter indoor/outdoor** agar sesuai kebutuhan.
- Sebagai pemain, saya ingin **memilih tanggal & jam** dan melihat slot yang masih kosong.
- Sebagai pemain, saya ingin **konfirmasi booking** dan mendapat notifikasi sukses.
- Sebagai pemain, saya ingin **melihat & membatalkan** booking saya.

## 6. Alur Utama (Happy Path)

```
Beranda → pilih lapangan → Detail
  → pilih tanggal → pilih slot jam → "Book Now"
  → konfirmasi (snackbar sukses) → muncul di "Booking Saya"
```

**Aturan bisnis:**
- Satu slot = 1 jam. Slot operasional 08:00–22:00.
- Tidak boleh double-booking slot yang sama (lapangan + tanggal + jam).
- Booking bisa dibatalkan kapan saja (MVP).

## 7. Navigasi

Bottom navigation 4 tab: **Home · Courts · Bookings · Profile**.

## 8. Persyaratan Non-Fungsional

- Responsif di layar ponsel umum (≥ 360px lebar), tanpa horizontal scroll.
- Interaksi terasa instan (state lokal).
- Kode rapi, komponen UI dapat dipakai ulang.

## 9. Rilis Berikutnya (Roadmap singkat)

1. Auth + profil asli.
2. Integrasi pembayaran (test mode dulu).
3. Backend jadwal real-time + notifikasi.
4. Rating & review, ajak teman / split tagihan.
