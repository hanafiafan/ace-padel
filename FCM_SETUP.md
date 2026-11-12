# Push Notification (FCM) — Setup

Status sekarang:

| Bagian | Status |
|---|---|
| Klien Flutter (register token, tampilkan push, pengingat booking lokal) | ✅ selesai (`lib/services/notification_service.dart`) |
| Firebase Android (`android/app/google-services.json`) | ✅ sudah ada (dipakai Google login) → FCM Android langsung jalan saat di-build |
| Izin `POST_NOTIFICATIONS` (Android 13+) | ✅ ada di `AndroidManifest.xml` |
| Backend simpan token (`POST/DELETE /api/devices`) | ✅ selesai (`server/src/routes/devices.js`, tabel `device_tokens`) |
| Backend **kirim** push (firebase-admin) | ⚙️ ter-wire tapi **no-op** sampai service account di-set (lihat di bawah) |
| iOS (APNs) | ⛔ belum (iOS belum di-scaffold) |
| Web push | ⛔ opsional (belum) |

Alur: klien dapat token FCM → `POST /api/devices` → tersimpan per user. Setiap kali
server memanggil `notify()` (mis. booking dikonfirmasi), token user dikirimi push
lewat `server/src/lib/push.js`. Push foreground ditampilkan ulang oleh notifikasi lokal;
pengingat "match 1 jam lagi" dijadwalkan lokal saat booking dibuat.

---

## 1. Aktifkan pengiriman push dari server

Butuh **service account Firebase** (Project Settings → Service accounts → Generate new private key).

```bash
cd server
npm i firebase-admin          # tambah dependency pengirim
```

Set salah satu env (lihat `server/.env.example`):

```bash
# Opsi A: isi JSON service account langsung (praktis untuk container)
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"...", ...}'

# Opsi B: path ke file kredensial
GOOGLE_APPLICATION_CREDENTIALS=/secrets/firebase-sa.json
```

Tanpa env di atas, server tetap jalan normal — push cuma dilewati (in-app notif tetap ada).
Restart server, lalu login di app → token terdaftar → trigger notif (mis. booking) → push masuk.

> Catatan: `project_id` service account harus sama dengan project di `google-services.json`.

## 2. Verifikasi cepat

```bash
# Token tersimpan?
sqlite3 server/data/acepadel.sqlite "SELECT user_id,platform FROM device_tokens;"
```
Buat 1 booking dari app (status terkonfirmasi memanggil `notify`) → HP menerima push.

## 3. iOS (saat platform iOS sudah ditambahkan)

1. Firebase Console → tambah app iOS (bundle id sama: `dev.hellens.ace_padel`).
2. Unduh `GoogleService-Info.plist` → `ios/Runner/`.
3. Apple Developer → buat **APNs Auth Key (.p8)** → upload di Firebase (Cloud Messaging).
4. Xcode: aktifkan capability **Push Notifications** + **Background Modes → Remote notifications**.
5. `firebase_messaging` iOS perlu `UNUserNotificationCenter` (sudah ditangani plugin).

## 4. Web push (opsional)

1. Firebase → tambah app Web, salin config.
2. Buat `web/firebase-messaging-sw.js` (service worker) + daftarkan VAPID key.
3. `FirebaseMessaging.instance.getToken(vapidKey: '...')`.

## File terkait
- Klien: `lib/services/notification_service.dart`, dipanggil di `lib/main.dart`, dijadwalkan di `lib/store.dart`.
- Server: `server/src/routes/devices.js`, `server/src/lib/push.js`, hook di `server/src/lib/util.js` (`notify`).
