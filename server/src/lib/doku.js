// DOKU Checkout (Jokul) — https://developers.doku.com/accept-payments/doku-checkout
const crypto = require('crypto');

const env = () => ({
  clientId: process.env.DOKU_CLIENT_ID,
  secret: process.env.DOKU_SECRET_KEY,
  base: process.env.DOKU_ENV === 'sandbox' ? 'https://api-sandbox.doku.com' : 'https://api.doku.com',
  publicUrl: (process.env.PUBLIC_URL || '').replace(/\/$/, ''),
});
const enabled = () => !!(env().clientId && env().secret);

const digestOf = (body) => crypto.createHash('sha256').update(body, 'utf-8').digest('base64');
function sign({ clientId, requestId, timestamp, target, digest }, secret) {
  const parts = [`Client-Id:${clientId}`, `Request-Id:${requestId}`, `Request-Timestamp:${timestamp}`, `Request-Target:${target}`];
  if (digest) parts.push(`Digest:${digest}`);
  return `HMACSHA256=${crypto.createHmac('sha256', secret).update(parts.join('\n')).digest('base64')}`;
}

async function call(method, target, bodyObj) {
  const { clientId, secret, base } = env();
  const body = bodyObj ? JSON.stringify(bodyObj) : '';
  const requestId = crypto.randomUUID();
  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
  const signature = sign({ clientId, requestId, timestamp, target, digest: body ? digestOf(body) : '' }, secret);
  const res = await fetch(base + target, {
    method, body: body || undefined, signal: AbortSignal.timeout(15000),
    headers: { 'Content-Type': 'application/json', 'Client-Id': clientId, 'Request-Id': requestId, 'Request-Timestamp': timestamp, Signature: signature },
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw Object.assign(new Error(json?.error_messages?.join?.(', ') || json?.message || `DOKU HTTP ${res.status}`), { doku: json });
  return json;
}

const METHOD_TYPES = {
  'QRIS Instant': ['QRIS'],
  'BCA Virtual Account': ['VIRTUAL_ACCOUNT_BCA'],
  'Mandiri Virtual Account': ['VIRTUAL_ACCOUNT_BANK_MANDIRI'],
};

// amount dalam Rupiah penuh. Mengembalikan URL halaman bayar DOKU.
async function createCheckout({ invoice, amountRp, method, dueMinutes = 15, customer, itemName, callbackUrl }) {
  const body = {
    order: {
      amount: amountRp, invoice_number: invoice, currency: 'IDR', language: 'ID', auto_redirect: true,
      callback_url: callbackUrl, callback_url_cancel: callbackUrl,
      line_items: [{ name: itemName.slice(0, 100), quantity: 1, price: amountRp }],
    },
    payment: { payment_due_date: dueMinutes, // Default: tampilkan semua channel yang aktif di akun DOKU. Set DOKU_RESTRICT_METHODS=1 setelah QRIS/VA diaktifkan.
      ...(process.env.DOKU_RESTRICT_METHODS === '1' && METHOD_TYPES[method] && { payment_method_types: METHOD_TYPES[method] }) },
    customer: { name: customer.name.slice(0, 255), email: customer.email },
  };
  const r = await call('POST', '/checkout/v1/payment', body);
  const url = r?.response?.payment?.url;
  if (!url) throw new Error('DOKU tidak mengembalikan URL pembayaran');
  return url;
}

// Status transaksi: SUCCESS | PENDING | FAILED | EXPIRED ...
const checkStatus = (invoice) => call('GET', `/orders/v1/status/${encodeURIComponent(invoice)}`).then((r) => r?.transaction?.status || r?.order?.status || 'UNKNOWN');

// Verifikasi notifikasi HTTP dari DOKU (target = path URL notifikasi kita)
function verifyNotification(req) {
  const { secret } = env();
  const h = req.headers;
  if (!secret || !h['signature'] || !req.rawBody) return false;
  const expect = sign({ clientId: h['client-id'], requestId: h['request-id'], timestamp: h['request-timestamp'], target: req.originalUrl.split('?')[0], digest: digestOf(req.rawBody.toString('utf-8')) }, secret);
  const a = Buffer.from(expect), b = Buffer.from(String(h['signature']));
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

module.exports = { enabled, env, createCheckout, checkStatus, verifyNotification, sign, digestOf };
