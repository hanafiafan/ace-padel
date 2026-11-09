import { api, setToken } from '../api.js';
import { route, state, homeFor, go } from '../router.js';
import { $, html, mount, icon, busy, toast } from '../ui.js';

const isLocal = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
const DEMOS = [['Admin', 'admin@acepadel.id', 'admin12345'], ['Pemilik', 'owner@acepadel.id', 'owner12345'], ['Pemain', 'player@acepadel.id', 'player12345']];

const hero = html`<section class="auth-hero"><a class="brand" href="/"><img src="/favicon.png" alt=""><span>ACE PADEL<small>Panel</small></span></a>
  <div><h2>Kelola lapangan. <em>Main lebih sering.</em></h2><p>Satu tempat untuk pemilik lapangan, admin, dan pemain: jadwal, booking, check-in, dan pembayaran.</p></div>
  <ul><li>${icon('check')}Jadwal real-time &amp; blokir slot</li><li>${icon('check')}Check-in tiket dengan QR</li><li>${icon('check')}Laporan pendapatan harian</li></ul></section>`;

// Google Identity Services: tombol resmi Google, ID token diverifikasi server.
let gsi;
const loadGsi = () => gsi ||= new Promise((ok, no) => { const s = document.createElement('script'); s.src = 'https://accounts.google.com/gsi/client'; s.async = true; s.onload = ok; s.onerror = () => { gsi = null; no(new Error('gsi')); }; document.head.append(s); });
async function googleButton(host, role, errEl) {
  try {
    const cfg = await fetch('/api/auth/config').then((r) => r.json());
    if (!cfg.googleClientId) return;
    await loadGsi();
    const dark = document.documentElement.dataset.theme === 'dark';
    google.accounts.id.initialize({ client_id: cfg.googleClientId, callback: async ({ credential }) => {
      errEl.hidden = true;
      try { await finish(await api('/auth/google', { method: 'POST', body: { idToken: credential, role: role() } })); } catch (e) { errEl.textContent = e.message; errEl.hidden = false; }
    } });
    host.innerHTML = '';
    google.accounts.id.renderButton(host, { theme: dark ? 'filled_black' : 'outline', size: 'large', text: 'continue_with', shape: 'rectangular', width: Math.min(400, host.clientWidth || 360), locale: 'id' });
    host.insertAdjacentHTML('afterend', '<div class="or"><span>atau dengan email</span></div>');
  } catch { /* tanpa Google, form email tetap berfungsi */ }
}

async function finish(res) {
  setToken(res.token); state.user = res.data; go(homeFor(res.data));
}

route('login', null, ({ el }) => {
  mount(el, html`<div class="auth">${hero}<section class="auth-form"><div class="auth-card">
    <div><h1>Masuk</h1><p class="muted">Selamat datang kembali di Ace Padel.</p></div>
    <div class="gbtn" id="gb"></div>
    <form id="lf" novalidate>
      <div class="field"><label for="em">Email</label><input class="input" id="em" name="email" type="email" required autocomplete="username" placeholder="nama@email.com"></div>
      <div class="field"><label for="pw">Kata sandi</label><input class="input" id="pw" name="password" type="password" required autocomplete="current-password" minlength="8"></div>
      <p class="form-err" role="alert" hidden></p>
      <button class="btn primary lg block" type="submit">Masuk</button>
    </form>
    ${isLocal ? html`<div class="demo"><span>Akun demo:</span>${DEMOS.map(([l, e, p]) => html`<button class="btn sm" type="button" data-e="${e}" data-p="${p}">${l}</button>`)}</div>` : ''}
    <p class="muted">Belum punya akun? <a href="#/register">Daftar</a> · <a href="#/register?role=owner">Daftar sebagai pemilik lapangan</a></p>
  </div></section></div>`);
  const f = $('#lf', el), err = $('.form-err', el);
  googleButton($('#gb', el), () => 'player', err);
  const submit = (btn) => busy(btn, async () => {
    err.hidden = true;
    try { await finish(await api('/auth/login', { method: 'POST', body: { email: f.email.value.trim(), password: f.password.value } })); } catch (e) { err.textContent = e.message; err.hidden = false; }
  });
  f.addEventListener('submit', (e) => { e.preventDefault(); if (!f.checkValidity()) return f.reportValidity(); submit($('button[type=submit]', f)); });
  el.querySelectorAll('[data-e]').forEach((b) => b.addEventListener('click', () => { f.email.value = b.dataset.e; f.password.value = b.dataset.p; submit(b); }));
}, { bare: true, title: 'Masuk' });

route('register', null, ({ el, query }) => {
  const owner = query.role === 'owner';
  mount(el, html`<div class="auth">${hero}<section class="auth-form"><div class="auth-card">
    <div><h1>Daftar</h1><p class="muted">Buat akun Ace Padel dalam semenit.</p></div>
    <div class="gbtn" id="gb"></div>
    <form id="rf" novalidate>
      <div class="seg" role="radiogroup" aria-label="Peran"><label><input type="radio" name="role" value="player" ${owner ? '' : 'checked'}>Pemain</label><label><input type="radio" name="role" value="owner" ${owner ? 'checked' : ''}>Pemilik Lapangan</label></div>
      <div class="field"><label for="nm">Nama lengkap</label><input class="input" id="nm" name="name" required autocomplete="name"></div>
      <div class="field"><label for="em">Email</label><input class="input" id="em" name="email" type="email" required autocomplete="email"></div>
      <div class="field"><label for="ph">No. HP (opsional)</label><input class="input" id="ph" name="phone" type="tel" autocomplete="tel"></div>
      <div class="field"><label for="pw">Kata sandi</label><input class="input" id="pw" name="password" type="password" required minlength="8" autocomplete="new-password"><small>Minimal 8 karakter.</small></div>
      <p class="form-err" role="alert" hidden></p>
      <button class="btn primary lg block" type="submit">Buat akun</button>
    </form>
    <p class="muted">Sudah punya akun? <a href="#/login">Masuk</a></p>
  </div></section></div>`);
  const f = $('#rf', el), err = $('.form-err', el);
  googleButton($('#gb', el), () => f.role.value, err);
  f.addEventListener('submit', (e) => {
    e.preventDefault(); if (!f.checkValidity()) return f.reportValidity();
    busy($('button[type=submit]', f), async () => {
      err.hidden = true;
      try {
        const body = { name: f.name.value.trim(), email: f.email.value.trim(), password: f.password.value, role: f.role.value };
        if (f.phone.value.trim()) body.phone = f.phone.value.trim();
        await finish(await api('/auth/register', { method: 'POST', body }));
        toast('Akun berhasil dibuat. Selamat datang!');
      } catch (x) { err.textContent = x.message; err.hidden = false; }
    });
  });
}, { bare: true, title: 'Daftar' });

