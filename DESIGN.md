# Design Spec — Ace Padel

Mengikuti referensi: **royal blue** sebagai warna utama, **lime** sebagai aksen,
kartu putih membulat, latar abu sangat terang, bottom nav biru.

---

## 1. Color Tokens

| Token | Hex | Pakai untuk |
|---|---|---|
| `blue` | `#2334DB` | Warna utama, tombol, highlight |
| `blueDark` | `#151C4E` | Header gelap, bottom nav, snackbar |
| `lime` | `#C7F23C` | Aksen, CTA bulat, ikon aktif |
| `ink` | `#12152B` | Teks utama |
| `slate` | `#6B7291` | Teks sekunder |
| `cloud` | `#F2F4FB` | Background scaffold |
| `line` | `#E7EAF3` | Border/hairline kartu |

## 2. Tipografi

- Font: default sistem (MVP; `google_fonts` menyusul bila perlu).
- Skala: Judul besar `22–28 / w800`, judul section `18 / w800`,
  body `14–15 / w400`, caption `12–13` warna `slate`.

## 3. Bentuk & Spacing

- Radius kartu: **20–24**. Chip/pill: **20 (penuh)**.
- Padding layar: **20** horizontal. Jarak antar kartu: **12–14**.
- Tombol CTA: tinggi **54**, radius **16**, warna `lime` teks `ink` (atau `blue` teks putih).

## 4. Komponen

| Komponen | Deskripsi |
|---|---|
| **FeaturedCard** | Kartu gradient 260px (beranda), menampilkan nama, venue, harga, rating, tombol panah lime. |
| **CourtRow** | Baris kompak: thumbnail gradient + ikon raket, nama, lokasi, rating, harga. |
| **DateChip** | Chip tanggal (7 hari), aktif = `blue`, nonaktif = putih border `line`. |
| **SlotTile** | Grid jam; tersedia = outline, terpilih = `blue`, penuh = abu + coret. |
| **SectionHeader** | Judul + aksi "See all". |
| **BottomNav** | 4 ikon, latar `blueDark`, item aktif `lime`. |

## 5. Layar

### 5.1 Home
- Header: sapaan + avatar.
- Search bar membulat.
- Hero banner gradient (promo).
- Chip kategori cepat (Indoor / Outdoor / Terdekat).
- `SectionHeader("Featured")` → list horizontal `FeaturedCard`.
- `SectionHeader("Nearby courts")` → list `CourtRow`.

### 5.2 Courts
- Search + filter indoor/outdoor.
- List vertikal `CourtRow` → tap ke Detail/Booking.

### 5.3 Court Detail & Booking
- Hero gradient lapangan + nama, lokasi, rating, harga/jam.
- Pilih tanggal: baris `DateChip`.
- Pilih jam: grid `SlotTile` (08:00–22:00).
- Ringkasan + tombol **Book Now** (lime).
- Sukses → snackbar + pindah ke Bookings.

### 5.4 Bookings
- Daftar reservasi: kartu lapangan + tanggal + jam + harga.
- Aksi batalkan (geser/tombol).
- Empty state ramah bila kosong.

### 5.5 Profile
- Kartu profil (avatar, nama, email).
- Statistik ringkas (total booking, jam main, venue favorit).
- Menu pengaturan statis.

## 6. Status Visual

- **Tersedia**: outline + teks `ink`.
- **Terpilih**: fill `blue` + teks putih.
- **Penuh/terpesan**: fill abu terang, teks `slate`, nonaktif.
- **Sukses**: snackbar `blueDark`.

## 7. Aksesibilitas

- Kontras teks ≥ WCAG AA pada latar masing-masing.
- Target sentuh ≥ 44×44.
- Semua ikon aksi punya label/tooltip.
