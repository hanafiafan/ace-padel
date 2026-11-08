const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/index');

let server;
const PORT = 3001;
const BASE_URL = `http://localhost:${PORT}`;

test.before(async () => {
  await new Promise((resolve) => {
    server = app.listen(PORT, 'localhost', resolve);
  });
});

test.after(async () => {
  await new Promise((resolve) => {
    server.close(resolve);
  });
});

test('GET /api/health returns healthy status', async () => {
  const res = await fetch(`${BASE_URL}/api/health`);
  assert.strictEqual(res.status, 200);
  const data = await res.json();
  assert.strictEqual(data.status, 'healthy');
  assert.strictEqual(data.service, 'ace-padel-backend');
});

test('GET /api/courts returns courts list', async () => {
  const res = await fetch(`${BASE_URL}/api/courts`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.success, true);
  assert.ok(json.count > 0);
  assert.ok(Array.isArray(json.data));
  assert.strictEqual(json.data[0].id, 'c1');
});

test('GET /api/courts/:id/slots returns availability', async () => {
  const res = await fetch(`${BASE_URL}/api/courts/c1/slots?date=2026-10-25`);
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.success, true);
  assert.strictEqual(json.slots.length, 14);
  assert.strictEqual(json.slots[0].slot, '08:00');
  assert.strictEqual(json.slots[0].available, true);
});

test('POST /api/bookings creates booking and prevents double-booking', async () => {
  // 1. Create booking
  const createRes = await fetch(`${BASE_URL}/api/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      courtId: 'c1',
      date: '2026-10-25',
      slot: '18:00',
      voucherCode: 'ACEWEEKEND',
      paymentMethod: 'QRIS Instant'
    })
  });

  assert.strictEqual(createRes.status, 201);
  const createJson = await createRes.json();
  assert.strictEqual(createJson.success, true);
  assert.strictEqual(createJson.data.discount, 25);
  assert.strictEqual(createJson.data.finalPrice, 155);
  const bookingId = createJson.data.id;

  // 2. Anti double-booking check for same court, date, slot
  const duplicateRes = await fetch(`${BASE_URL}/api/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      courtId: 'c1',
      date: '2026-10-25',
      slot: '18:00'
    })
  });

  assert.strictEqual(duplicateRes.status, 409); // Conflict

  // 3. Verify slot availability endpoint reports taken: true
  const slotsRes = await fetch(`${BASE_URL}/api/courts/c1/slots?date=2026-10-25`);
  const slotsJson = await slotsRes.json();
  const slot18 = slotsJson.slots.find((s) => s.slot === '18:00');
  assert.strictEqual(slot18.taken, true);

  // 4. Cancel booking
  const cancelRes = await fetch(`${BASE_URL}/api/bookings/${bookingId}`, {
    method: 'DELETE'
  });
  assert.strictEqual(cancelRes.status, 200);

  // 5. Verify slot is freed up
  const slotsAfterCancel = await fetch(`${BASE_URL}/api/courts/c1/slots?date=2026-10-25`);
  const slotsAfterJson = await slotsAfterCancel.json();
  const slot18After = slotsAfterJson.slots.find((s) => s.slot === '18:00');
  assert.strictEqual(slot18After.taken, false);
});

test('POST /api/bookings supports equipment add-ons and updates finalPrice', async () => {
  const res = await fetch(`${BASE_URL}/api/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      courtId: 'c2',
      date: '2026-10-26',
      slot: '16:00',
      addOns: ['2x Sewa Raket Bullpadel Pro', '1x 1 Can Bola Baru (3 Pcs)'],
      addOnsTotal: 135,
      paymentMethod: 'Bayar di tempat'
    })
  });

  assert.strictEqual(res.status, 201);
  const json = await res.json();
  assert.strictEqual(json.success, true);
  assert.strictEqual(json.data.addOns.length, 2);
  assert.strictEqual(json.data.addOnsTotal, 135);
  // c2 price is 150 + 135 = 285
  assert.strictEqual(json.data.finalPrice, 285);

  // Clean up
  await fetch(`${BASE_URL}/api/bookings/${json.data.id}`, { method: 'DELETE' });
});

test('POST /api/vouchers/validate checks promo voucher', async () => {
  const res = await fetch(`${BASE_URL}/api/vouchers/validate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      code: 'ACEWEEKEND',
      amount: 180
    })
  });

  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.valid, true);
  assert.strictEqual(json.data.discountAmount, 25);
  assert.strictEqual(json.data.finalAmount, 155);
});

test('Venue Owner endpoints: verify ticket, check-in, and toggle maintenance', async () => {
  // 1. Create a test booking
  const createRes = await fetch(`${BASE_URL}/api/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      courtId: 'c1',
      date: '2026-10-30',
      slot: '14:00',
      paymentMethod: 'Bayar di tempat'
    })
  });
  const createJson = await createRes.json();
  const bookingId = createJson.data.id;

  // 2. Verify ticket
  const verifyRes = await fetch(`${BASE_URL}/api/venue/verify-ticket`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ bookingId })
  });
  assert.strictEqual(verifyRes.status, 200);
  const verifyJson = await verifyRes.json();
  assert.strictEqual(verifyJson.valid, true);
  assert.strictEqual(verifyJson.data.slot, '14:00');

  // 3. Check-in
  const checkInRes = await fetch(`${BASE_URL}/api/venue/check-in`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ bookingId })
  });
  assert.strictEqual(checkInRes.status, 200);
  const checkInJson = await checkInRes.json();
  assert.strictEqual(checkInJson.data.status, 'Check-in Selesai');

  // 4. Toggle maintenance on another slot
  const blockRes = await fetch(`${BASE_URL}/api/venue/toggle-slot`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      courtId: 'c1',
      date: '2026-10-30',
      slot: '10:00',
      action: 'block',
      reason: 'Pembersihan Kaca Rutin'
    })
  });
  assert.strictEqual(blockRes.status, 200);

  // 5. Unblock maintenance slot
  const unblockRes = await fetch(`${BASE_URL}/api/venue/toggle-slot`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      courtId: 'c1',
      date: '2026-10-30',
      slot: '10:00',
      action: 'unblock'
    })
  });
  assert.strictEqual(unblockRes.status, 200);

  // Cleanup test booking
  await fetch(`${BASE_URL}/api/bookings/${bookingId}`, { method: 'DELETE' });
});

test('Friends & Leaderboard endpoints: list, add, remove and leaderboard filtering', async () => {
  // 1. Get friends
  const listRes = await fetch(`${BASE_URL}/api/friends`);
  assert.strictEqual(listRes.status, 200);
  const listJson = await listRes.json();
  assert.strictEqual(listJson.success, true);
  assert.ok(Array.isArray(listJson.data));

  // 2. Add friend 'p2' (Dewi Anggraini)
  const addRes = await fetch(`${BASE_URL}/api/friends/add`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ playerId: 'p2' })
  });
  assert.strictEqual(addRes.status, 200);
  const addJson = await addRes.json();
  assert.ok(addJson.data.includes('p2'));

  // 3. Get friends leaderboard
  const lbRes = await fetch(`${BASE_URL}/api/friends/leaderboard?type=friends`);
  assert.strictEqual(lbRes.status, 200);
  const lbJson = await lbRes.json();
  assert.strictEqual(lbJson.success, true);
  assert.ok(lbJson.data.some((p) => p.id === 'p2'));
  assert.ok(lbJson.data.some((p) => p.isMe));

  // 4. Remove friend 'p2'
  const remRes = await fetch(`${BASE_URL}/api/friends/remove`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ playerId: 'p2' })
  });
  assert.strictEqual(remRes.status, 200);
  const remJson = await remRes.json();
  assert.strictEqual(remJson.data.includes('p2'), false);
});

test('POST /api/auth/google handles Google OAuth login and updates profile', async () => {
  const res = await fetch(`${BASE_URL}/api/auth/google`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'test.google@padel.id',
      name: 'Google Padel User',
      photoUrl: 'https://lh3.googleusercontent.com/test',
      googleId: 'g_123456789'
    })
  });
  assert.strictEqual(res.status, 200);
  const json = await res.json();
  assert.strictEqual(json.success, true);
  assert.strictEqual(json.data.email, 'test.google@padel.id');
  assert.strictEqual(json.data.name, 'Google Padel User');
  assert.strictEqual(json.data.authProvider, 'google');
  assert.ok(json.token);
});

test('Super Admin endpoints: overview, courts, vouchers, and web portal HTML', async () => {
  // 1. Overview metrics
  const ovRes = await fetch(`${BASE_URL}/api/admin/overview`);
  assert.strictEqual(ovRes.status, 200);
  const ovJson = await ovRes.json();
  assert.strictEqual(ovJson.success, true);
  assert.ok(ovJson.data.metrics.totalCourts > 0);
  assert.ok(ovJson.data.metrics.totalRevenueFormatted);

  // 2. Add court
  const addCourtRes = await fetch(`${BASE_URL}/api/admin/courts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Super Court Test',
      venue: 'Hellens Arena',
      area: 'Jakarta Pusat',
      pricePerHour: 220,
      indoor: true
    })
  });
  assert.strictEqual(addCourtRes.status, 201);
  const addCourtJson = await addCourtRes.json();
  assert.strictEqual(addCourtJson.success, true);
  assert.strictEqual(addCourtJson.data.name, 'Super Court Test');

  // 3. Add & delete voucher
  const addVoucherRes = await fetch(`${BASE_URL}/api/admin/vouchers`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      code: 'TESTSUPER50',
      discount: 50,
      description: 'Diskon 50k uji coba'
    })
  });
  assert.strictEqual(addVoucherRes.status, 201);

  const delVoucherRes = await fetch(`${BASE_URL}/api/admin/vouchers/TESTSUPER50`, {
    method: 'DELETE'
  });
  assert.strictEqual(delVoucherRes.status, 200);

  // 4. Web portal serves HTML
  const webRes = await fetch(`${BASE_URL}/admin`);
  assert.strictEqual(webRes.status, 200);
  const html = await webRes.text();
  assert.ok(html.includes('Ace Padel'));
  assert.ok(html.includes('Super Admin'));
});


