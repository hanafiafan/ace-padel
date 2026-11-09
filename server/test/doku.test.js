process.env.DB_PATH = ':memory:';
process.env.NODE_ENV = 'test';
process.env.DOKU_CLIENT_ID = 'BRN-TEST';
process.env.DOKU_SECRET_KEY = 'SK-test-secret';
const { test, before, after } = require('node:test');
const assert = require('node:assert');
const doku = require('../src/lib/doku');
const app = require('../src/index');

let base, server;
const realFetch = global.fetch;
before(() => new Promise((r) => { server = app.listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

const call = async (method, path, body, token, headers = {}) => {
  const res = await realFetch(base + path, { method, headers: { 'content-type': 'application/json', ...(token && { authorization: `Bearer ${token}` }), ...headers }, body: typeof body === 'string' ? body : body && JSON.stringify(body) });
  return { status: res.status, ...(await res.json()) };
};
const tomorrow = new Date(Date.now() + 7 * 3600e3 + 86400e3).toISOString().slice(0, 10);

test('signature DOKU cocok dengan contoh dokumentasi (format komponen)', () => {
  const digest = doku.digestOf('{"a":1}');
  const s = doku.sign({ clientId: 'c', requestId: 'r', timestamp: 't', target: '/x', digest }, 'k');
  assert.match(s, /^HMACSHA256=[A-Za-z0-9+/]+=*$/);
  assert.notEqual(s, doku.sign({ clientId: 'c', requestId: 'r', timestamp: 't', target: '/y', digest }, 'k'));
});

test('checkout DOKU → URL tersimpan; notifikasi bertanda tangan → Lunas; palsu ditolak', async () => {
  const login = await call('POST', '/api/auth/login', { email: 'player@acepadel.id', password: 'player12345' });
  const T = login.token;
  assert.equal((await call('GET', '/api/payments/config')).data.provider, 'doku');
  const bk = (await call('POST', '/api/bookings', { courtId: 'c3', date: tomorrow, slot: '14:00', paymentMethod: 'QRIS Instant' }, T)).data;
  assert.equal(bk.paymentStatus, 'Menunggu');
  assert.equal(bk.paymentRef, null);

  let sent;
  global.fetch = async (url, init) => {
    if (String(url).startsWith('https://api.doku.com')) {
      sent = { url: String(url), init, body: JSON.parse(init.body) };
      return { ok: true, status: 200, json: async () => ({ response: { payment: { url: 'https://checkout.doku.com/x' } } }) };
    }
    return realFetch(url, init);
  };
  const c = await call('POST', `/api/bookings/${bk.id}/checkout`, null, T);
  global.fetch = realFetch;
  assert.equal(c.paymentUrl, 'https://checkout.doku.com/x');
  assert.equal(sent.url, 'https://api.doku.com/checkout/v1/payment');
  assert.equal(sent.body.order.amount, bk.finalPrice * 1000);
  assert.deepEqual(sent.body.payment.payment_method_types, ['QRIS']);
  assert.equal(sent.init.headers['Client-Id'], 'BRN-TEST');
  // simulasi bayar harus mati saat DOKU aktif
  assert.equal((await call('POST', `/api/bookings/${bk.id}/pay`, null, T)).status, 403);

  const body = JSON.stringify({ order: { invoice_number: bk.id, amount: bk.finalPrice * 1000 }, transaction: { status: 'SUCCESS' } });
  const h = { 'client-id': 'BRN-TEST', 'request-id': 'rid-1', 'request-timestamp': '2026-11-09T00:00:00Z' };
  const target = '/api/payments/doku/notify';
  const good = doku.sign({ clientId: h['client-id'], requestId: h['request-id'], timestamp: h['request-timestamp'], target, digest: doku.digestOf(body) }, 'SK-test-secret');
  assert.equal((await call('POST', target, body, null, { ...h, signature: 'HMACSHA256=palsu' })).status, 401);
  assert.equal((await call('POST', target, body, null, { ...h, signature: good })).status, 200);
  const after = await call('GET', `/api/bookings/${bk.id}`, null, T);
  assert.equal(after.data.paymentStatus, 'Lunas');
});
