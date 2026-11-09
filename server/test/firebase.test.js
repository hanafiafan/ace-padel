const { test } = require('node:test');
const assert = require('node:assert');
const crypto = require('crypto');
const { execFileSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const { verifyFirebaseToken, _setCerts } = require('../src/lib/firebase');

// Kunci + sertifikat uji (self-signed) menggantikan sertifikat Google.
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fb-'));
execFileSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', path.join(dir, 'k.pem'), '-out', path.join(dir, 'c.pem'), '-subj', '/CN=test', '-days', '1'], { stdio: 'ignore' });
const priv = fs.readFileSync(path.join(dir, 'k.pem')), cert = fs.readFileSync(path.join(dir, 'c.pem'), 'utf8');
_setCerts({ kid1: cert });
const b = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const mint = (over = {}, kid = 'kid1') => {
  const now = Math.floor(Date.now() / 1000);
  const body = { aud: 'ace-padel-3f910', iss: 'https://securetoken.google.com/ace-padel-3f910', sub: 'u1', iat: now, exp: now + 600, email: 'a@b.com', email_verified: true, firebase: { sign_in_provider: 'google.com' }, ...over };
  const un = `${b({ alg: 'RS256', kid })}.${b(body)}`;
  return `${un}.${crypto.sign('RSA-SHA256', Buffer.from(un), priv).toString('base64url')}`;
};

test('token Firebase Google yang sah diterima', async () => {
  assert.equal((await verifyFirebaseToken(mint())).email, 'a@b.com');
});
test('token ditolak: aud salah, kedaluwarsa, bukan google.com, kid asing, dirusak', async () => {
  for (const t of [mint({ aud: 'lain' }), mint({ exp: 1 }), mint({ firebase: { sign_in_provider: 'password' } }), mint({}, 'nope'), mint().slice(0, -4) + 'AAAA'])
    await assert.rejects(verifyFirebaseToken(t));
});
