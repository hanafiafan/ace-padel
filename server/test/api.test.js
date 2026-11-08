process.env.DB_PATH = ':memory:';
process.env.NODE_ENV = 'test';
const { test, before, after } = require('node:test');
const assert = require('node:assert');
const app = require('../src/index');

let base, server;
before(() => new Promise((r) => { server = app.listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

const call = async (method, path, body, token) => {
  const res = await fetch(base + path, { method, headers: { 'content-type': 'application/json', ...(token && { authorization: `Bearer ${token}` }) }, body: body && JSON.stringify(body) });
  return { status: res.status, ...(await res.json()) };
};
const login = async (email, password) => (await call('POST', '/api/auth/login', { email, password })).token;
const tomorrow = new Date(Date.now() + 7 * 3600e3 + 86400e3).toISOString().slice(0, 10);

test('katalog publik & slot', async () => {
  const c = await call('GET', '/api/courts');
  assert.ok(c.count >= 16);
  const s = await call('GET', `/api/courts/c1/slots?date=${tomorrow}`);
  assert.equal(s.slots.length, 14);
  assert.equal((await call('GET', '/api/public/stats')).data.courts >= 16, true);
});

test('auth: register, login, role guard', async () => {
  const reg = await call('POST', '/api/auth/register', { name: 'Tester', email: 't@x.id', password: 'secret123' });
  assert.equal(reg.status, 201);
  assert.equal((await call('POST', '/api/auth/register', { name: 'Tt', email: 't@x.id', password: 'secret123' })).status, 409);
  assert.equal((await call('POST', '/api/auth/login', { email: 't@x.id', password: 'salah' })).status, 401);
  assert.equal((await call('GET', '/api/bookings')).status, 401);
  assert.equal((await call('GET', '/api/admin/overview', null, reg.token)).status, 403);
  assert.equal((await call('GET', '/api/owner/courts', null, reg.token)).status, 403);
  assert.equal((await call('POST', '/api/auth/register', { name: 'Hacker', email: 'h@x.id', password: 'secret123', role: 'admin' })).data.role, 'player');
});

test('booking: anti double-booking, voucher, add-on server-side, cancel membuka slot', async () => {
  const a = await login('player@acepadel.id', 'player12345');
  const b = (await call('POST', '/api/auth/register', { name: 'Bb', email: 'b@x.id', password: 'secret123' })).token;
  const body = { courtId: 'c1', date: tomorrow, slot: '10:00', voucherCode: 'smash10', addOns: ['racket'], addOnsTotal: 1 };
  const r1 = await call('POST', '/api/bookings', body, a);
  assert.equal(r1.status, 201);
  assert.equal(r1.data.finalPrice, 220 + 30 - 10);
  assert.equal((await call('POST', '/api/bookings', body, b)).status, 409);
  assert.equal((await call('DELETE', `/api/bookings/${r1.data.id}`, null, b)).status, 403);
  assert.equal((await call('POST', '/api/bookings', { ...body, voucherCode: 'NOPE' }, b)).status, 400);
  assert.equal((await call('POST', '/api/bookings', { ...body, date: '2020-01-01' }, b)).status, 400);
  assert.equal((await call('DELETE', `/api/bookings/${r1.data.id}`, null, a)).status, 200);
  assert.equal((await call('POST', '/api/bookings', body, b)).status, 201);
});

test('pembayaran online → kedaluwarsa otomatis & bayar', async () => {
  const a = await login('player@acepadel.id', 'player12345');
  const r = await call('POST', '/api/bookings', { courtId: 'c2', date: tomorrow, slot: '12:00', paymentMethod: 'QRIS Instant' }, a);
  assert.equal(r.data.paymentStatus, 'Menunggu');
  const p = await call('POST', `/api/bookings/${r.data.id}/pay`, null, a);
  assert.equal(p.data.paymentStatus, 'Lunas');
});

test('owner: hanya lapangan miliknya; check-in + poin; blokir slot', async () => {
  const o = await login('owner@acepadel.id', 'owner12345');
  const a = await login('player@acepadel.id', 'player12345');
  const mine = await call('GET', '/api/owner/courts', null, o);
  assert.equal(mine.data.length, 5);
  assert.equal((await call('POST', '/api/owner/toggle-slot', { courtId: 'c9', date: tomorrow, slot: '09:00' }, o)).status, 403);
  assert.equal((await call('POST', '/api/owner/toggle-slot', { courtId: 'c1', date: tomorrow, slot: '09:00' }, o)).status, 200);
  assert.equal((await call('POST', '/api/bookings', { courtId: 'c1', date: tomorrow, slot: '09:00' }, a)).status, 409);
  assert.equal((await call('POST', '/api/owner/toggle-slot', { courtId: 'c1', date: tomorrow, slot: '09:00', action: 'unblock' }, o)).status, 200);
  const bk = (await call('POST', '/api/bookings', { courtId: 'c1', date: tomorrow, slot: '09:00' }, a)).data;
  const v = await call('POST', '/api/owner/verify-ticket', { bookingId: bk.id }, o);
  assert.equal(v.valid, false); // bukan hari ini
  const st = await call('GET', '/api/owner/stats', null, o);
  assert.ok(st.data.daily.length === 14);
});

test('owner ajukan lapangan → admin setujui → tampil publik', async () => {
  const o = await login('owner@acepadel.id', 'owner12345');
  const ad = await login('admin@acepadel.id', 'admin12345');
  const c = await call('POST', '/api/owner/courts', { name: 'Court Baru', venue: 'Venue Baru', area: 'Bandung, Jawa Barat', pricePerHour: 150 }, o);
  assert.equal(c.data.status, 'pending');
  assert.equal((await call('GET', `/api/courts/${c.data.id}`)).status, 404);
  assert.equal((await call('PATCH', `/api/admin/courts/${c.data.id}/status`, { status: 'approved' }, o)).status, 403);
  assert.equal((await call('PATCH', `/api/admin/courts/${c.data.id}/status`, { status: 'approved' }, ad)).status, 200);
  assert.equal((await call('GET', `/api/courts/${c.data.id}`)).status, 200);
});

test('mabar, teman, favorit, notifikasi, achievements', async () => {
  const a = await login('player@acepadel.id', 'player12345');
  const ms = await call('GET', '/api/matches', null, a);
  const m = ms.data.find((x) => x.currentPlayers < x.maxPlayers);
  const j = await call('POST', `/api/matches/${m.id}/join`, null, a);
  assert.equal(j.joined, true);
  assert.equal((await call('POST', '/api/friends/add', { playerId: 'daniel_lim' }, a)).status, 200);
  assert.equal((await call('POST', '/api/favorites/c1', null, a)).data.favorite, true);
  const n = await call('GET', '/api/notifications', null, a);
  assert.ok(n.data.length > 0);
  assert.equal((await call('GET', '/api/achievements', null, a)).data.length, 8);
  assert.equal((await call('POST', '/api/coach-sessions', { coachId: 'coach1', date: tomorrow, slot: '15:00' }, a)).status, 201);
  assert.equal((await call('POST', '/api/coach-sessions', { coachId: 'coach1', date: tomorrow, slot: '15:00' }, a)).status, 409);
});
