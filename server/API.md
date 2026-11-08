# Ace Padel API v2

Base: `/api`. JSON. Auth: `Authorization: Bearer <token>`. Semua sukses: `{success:true, data, ...extra}`; gagal: `{success:false, message}` (400 validasi, 401 belum login, 403 peran salah, 404, 409 konflik slot, 429).
**Harga dalam ribuan Rupiah** (`220` = Rp220.000). Tanggal `YYYY-MM-DD` (WIB). Slot `"08:00"`…`"21:00"`.
Peran: `player`, `owner` (pemilik lapangan), `admin` (superadmin). Admin boleh memakai semua endpoint `/owner/*`.

Akun dev (hanya non-production): admin `admin@acepadel.id / admin12345`, owner `owner@acepadel.id / owner12345` (memiliki c1–c5), player `player@acepadel.id / player12345`.

## Auth
- `POST /auth/register {name,email,password(>=8),role?:'player'|'owner',phone?}` → `{token,data:user}` 201
- `POST /auth/login {email,password}` → `{token,data:user}`
- `POST /auth/google {idToken}` → `{token,data:user}` (dev: `ALLOW_UNVERIFIED_GOOGLE=1` menerima `{email,name,photoUrl,googleId}` tanpa idToken)
- `GET /auth/me`, `PUT /auth/me {name,phone,skillLevel,preferredHand,photoUrl}`, `PUT /auth/password {currentPassword,newPassword}`
- user: `{id,name,username,email,phone,role,status,skillLevel,preferredHand,photoUrl,authProvider,points,wins,matches,createdAt}`

## Publik
- `GET /courts?q&indoor=true|false&city&facility&sortBy=rating|price_asc|price_desc` → `[court]`
- `GET /courts/:id` → court + `reviews[]`; `GET /courts/meta/cities`
- `GET /courts/:id/slots?date=` → `slots:[{slot,available,taken,blocked,past}]` (juga di `data`)
- `GET /reviews/:courtId`; `POST /reviews {courtId,rating,comment}` (auth, harus pernah booking)
- `GET /coaches`; `GET /vouchers`; `POST /vouchers/validate {code,price}` → `{valid,data:{...,discount}}`
- `GET /leaderboard?scope=friends` (auth opsional) → `[{rank,id,name,username,photoUrl,points,wins,matches,isMe}]`
- `GET /public/stats` → `{venues,courts,players,bookings,cities}` (untuk landing)
- `GET /addons` → `[{id,name,price}]`
- court: `{id,ownerId,name,venue,area,city,pricePerHour,indoor,rating,image,imageUrl,facilities[],description,status}`. `imageUrl` = `/img/<file>` atau `/uploads/<file>`; `image` = path asset Flutter bila seed.

## Pemain (auth)
- `GET /bookings` → `{active[],history[],totalActive,totalHistory}`; `GET /bookings/:id`
- `POST /bookings {courtId,date,slot,paymentMethod?,voucherCode?,addOns?:[id|nama]}` → 201 booking. Harga add-on dihitung server. `paymentMethod`: `Bayar di tempat|QRIS Instant|BCA Virtual Account|Mandiri Virtual Account`. Metode online → `paymentStatus:'Menunggu'`, `paymentRef` (nomor VA / payload QRIS), kedaluwarsa 15 menit (otomatis batal).
- `DELETE /bookings/:id` batal; `POST /bookings/:id/pay` (simulasi gateway; nonaktif bila `PAYMENT_MODE=live`, gunakan `POST /payments/webhook` + header `x-webhook-secret`)
- booking: `{id,courtId,userId,userName,date,slot,pricePerHour,discount,addOns[],addOnsTotal,finalPrice,paymentMethod,paymentStatus('Belum Bayar'|'Menunggu'|'Lunas'|'Dikembalikan'|'Kedaluwarsa'),paymentRef,paymentExpiresAt,voucherCode,status('Terkonfirmasi'|'Check-in Selesai'|'Dibatalkan'|'Maintenance'),note,createdAt,checkedInAt,cancelledAt,court}`
- `GET /matches` (auth opsional) → `[{id,courtId,court,dateString,time,title,hostId,hostName,skillLevel,currentPlayers,maxPlayers,pricePerPlayer,players[],isJoined}]`; `POST /matches {courtId,dateString,time,title,skillLevel,maxPlayers,pricePerPlayer}`; `POST /matches/:id/join` (toggle; `joined` di body)
- `GET /friends`, `POST /friends/add {playerId|username}`, `POST /friends/remove`, `GET /players/search?q=`
- `GET /favorites` → `[courtId]`; `POST /favorites/:courtId` toggle
- `GET /notifications` (+`unread`), `POST /notifications/read-all`, `POST /notifications/:id/read`
- `GET|PUT /payment-method {method}`
- `GET /coach-sessions`, `POST /coach-sessions {coachId,venue,date,slot,focus}`, `DELETE /coach-sessions/:id`
- `GET /me/stats`, `GET /achievements` → `[{key,title,desc,progress,target,unlocked}]`

## Owner `/owner/*` (owner|admin)
- `GET /courts` (milik sendiri; admin: semua), `POST /courts {name,venue,area:'Kemang, Jakarta',pricePerHour,indoor,facilities[],description,image}` (owner → `pending` menunggu admin), `PUT /courts/:id`
- `POST /uploads {dataUrl:'data:image/png;base64,…'}` → `{url}` (maks 3MB)
- `GET /bookings?courtId&date&from&to&status&q`, `GET /schedule?courtId&date` → `[{slot,booking|null}]`
- `POST /verify-ticket {bookingId}`, `POST /check-in {bookingId}` (+50 poin pemain), `POST /bookings/:id/cancel`, `POST /bookings/:id/mark-paid`, `POST /manual-booking {courtId,date,slot,customerName}` (walk-in)
- `POST /toggle-slot {courtId,date,slot,action:'block'|'unblock',reason}`
- `GET /stats?days=14` → `{courts,today{bookings,revenue,checkedIn,occupancy},period{bookings,revenue,cancelled,pendingPayment},daily[{date,bookings,revenue}],perCourt[],upcoming[]}`
- `GET /reviews`

## Admin `/admin/*` (admin)
- `GET /overview` → `{users,courts,bookings,revenue,daily[],topVenues[],recent[]}`
- `GET /users?q&role&status`, `PATCH /users/:id {role,status}`
- `GET /courts?status`, `PATCH /courts/:id/status {status:'approved'|'rejected'|'suspended'|'pending',reason}`, `DELETE /courts/:id`
- `GET|POST /vouchers {code,title,description,discountAmount|percentage(0-1),maxDiscount,minSpend,usageLimit,expiresAt}`, `PATCH|DELETE /vouchers/:code`
- `GET|POST /coaches`, `PATCH /coaches/:id`
- `GET /bookings?status&q`, `DELETE /reviews/:id`, `DELETE /matches/:id`

## Menjalankan
`cd server && npm install && npm start` (port 3001; `PORT`, `DB_PATH`, `JWT_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `CORS_ORIGIN`, `GOOGLE_CLIENT_ID`, `PAYMENT_MODE`, `PAYMENT_WEBHOOK_SECRET`). Web: `/` landing, `/app` panel. DB: SQLite `data/acepadel.sqlite` (otomatis dibuat + seed).
