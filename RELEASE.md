# Panduan Rilis & Deploy — Ace Padel

Checklist go-live untuk **backend (Node/SQLite)** + **app Android** (iOS & Web opsional).
Yang sudah siap ditandai ✅; yang perlu kredensial/akunmu ditandai ⚙️.

---

## 0. Ringkasan kesiapan
| Komponen | Status |
|---|---|
| Backend REST API + anti-double-booking (SQLite) | ✅ |
| Dockerfile produksi (`server/Dockerfile`, non-root, healthcheck, volume `/data`) | ✅ |
| Signing Android (`android/key.properties` + `signingConfigs.release`) | ✅ sudah ter-set |
| Firebase Android (Google login + FCM) | ✅ `google-services.json` ada |
| Metadata Play Store (`PLAY_STORE_METADATA.md`) + Privacy Policy (`PRIVACY_POLICY.*`) | ✅ |
| Pembayaran DOKU | ⚙️ default simulasi → butuh kredensial live |
| Pengiriman push FCM | ⚙️ butuh service account (lihat `FCM_SETUP.md`) |
| Platform iOS | ⛔ belum di-scaffold |

---

## 1. Backend ke produksi

### 1a. Environment (`server/.env`)
Salin dari `.env.example`, isi nilai asli:
```
NODE_ENV=production
PORT=3001
JWT_SECRET=<string acak panjang, mis. `openssl rand -hex 32`>
ADMIN_EMAIL=...      ADMIN_PASSWORD=<kuat>
CORS_ORIGIN=https://app.domainmu.com,https://domainmu.com   # domain app saja
GOOGLE_CLIENT_ID=<dari Firebase/Google Cloud>
DB_PATH=/data/acepadel.sqlite
# DOKU live:
PAYMENT_MODE=live
PAYMENT_WEBHOOK_SECRET=<dari DOKU>
DOKU_CLIENT_ID=...  DOKU_SECRET_KEY=...   # sesuai lib/doku
# Push (opsional): FIREBASE_SERVICE_ACCOUNT='{...}'  (lihat FCM_SETUP.md)
```

### 1b. Build & jalankan (Docker)
```bash
cd server
docker build -t ace-padel-api .
docker run -d --name ace-padel-api -p 3001:3001 \
  --env-file .env -v ace_padel_data:/data ace-padel-api
# cek: curl http://localhost:3001/api/health
```
Taruh di belakang reverse proxy (Nginx/Caddy/Traefik) untuk **HTTPS wajib**.
Data persist di volume `/data` (backup berkala file `acepadel.sqlite`).

### 1c. DOKU live
- Set `PAYMENT_MODE=live` → simulasi `POST /bookings/:id/pay` nonaktif.
- Daftarkan **webhook** DOKU ke `POST https://<api>/api/payments/webhook` (header `x-webhook-secret`).
- Uji 1 transaksi QRIS + 1 VA sampai status `Lunas`.

### 1d. Push FCM (opsional)
Ikuti `FCM_SETUP.md` (install `firebase-admin` + set `FIREBASE_SERVICE_ACCOUNT`).

---

## 2. Rilis Android (Google Play)

Signing sudah ter-set (`android/key.properties`). Pastikan keystore-nya di-backup & **jangan** commit `key.properties`/`.jks`.

```bash
# arahkan app ke API produksi lewat --dart-define
flutter build appbundle --release \
  --dart-define=API_URL=https://api.domainmu.com

# output: build/app/outputs/bundle/release/app-release.aab
```
- Play Console → buat app → upload `.aab` (track Internal testing dulu).
- Isi listing dari `PLAY_STORE_METADATA.md`; set **Privacy Policy URL** (host `PRIVACY_POLICY.html`).
- Lengkapi **Data safety** (login, lokasi, pembayaran), content rating, target audience.
- `applicationId` saat ini: `dev.hellens.ace_padel` (tak bisa diubah setelah rilis).
- Promosikan ke Production setelah lolos review.

> Checklist pra-rilis: naikkan `version:` di `pubspec.yaml` tiap rilis; tes di perangkat fisik; cek izin (INTERNET, POST_NOTIFICATIONS); matikan `usesCleartextTraffic` bila API sudah full HTTPS.

---

## 3. iOS (jika mau rilis App Store) ⛔ belum

```bash
flutter create --platforms=ios .      # scaffold folder ios/
```
Lalu: set bundle id `dev.hellens.ace_padel`, tambah `GoogleService-Info.plist`,
konfigurasi signing (Apple Developer Program), APNs untuk push (lihat `FCM_SETUP.md` §3),
`flutter build ipa --release --dart-define=API_URL=...`, upload via Transporter/Xcode.
Butuh macOS + Xcode penuh + akun Apple Developer.

---

## 4. Web (opsional)
```bash
flutter build web --release --dart-define=API_URL=https://api.domainmu.com
```
Server sudah menyajikan situs marketing (`server/public`) + panel di `/app`.
Deploy hasil `build/web` ke hosting statis atau lewat server yang sama.

---

## 5. Setelah rilis (disarankan)
- **Error reporting / analytics**: Firebase Crashlytics + Analytics (atau Sentry).
- **Backup DB** terjadwal + uji restore.
- **Monitoring** uptime `/api/health` + log.
- **Seed data asli**: onboard venue lewat Portal Mitra (owner dashboard) agar data bukan dummy.
- Uji alur lengkap lewat flow Maestro di `.maestro/` dan skenario di `LAPORAN_UAT.md`.
```
