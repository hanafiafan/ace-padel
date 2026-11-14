import { api, setToken } from '../api.js';
import { route, state, homeFor, go } from '../router.js';
import { $, html, mount, icon, busy, toast } from '../ui.js';

const isLocal = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
const DEMOS = [['Admin', 'admin@acepadel.id', 'admin12345'], ['Pemilik', 'owner@acepadel.id', 'owner12345'], ['Pemain', 'player@acepadel.id', 'player12345']];

const hero = html`<section class="auth-hero"><a class="brand" href="/"><img src="/favicon.png" alt=""><span>ACE PADEL<small>Panel</small></span></a>
  <div><h2>Kelola lapangan. <em>Main lebih sering.</em></h2><p>Satu tempat untuk pemilik lapangan, admin, dan pemain: jadwal, booking, check-in, dan pembayaran.</p></div>
  <ul><li>${icon('check')}Jadwal real-time &amp; blokir slot</li><li>${icon('check')}Check-in tiket dengan QR</li><li>${icon('check')}Laporan pendapatan harian</li></ul></section>`;

// Login Google lewat Firebase Auth (popup). ID token Firebase diverifikasi server di /auth/firebase.
const FB = 'https://www.gstatic.com/firebasejs/10.12.2/';
let fbReady;
const loadScript = (src) => new Promise((ok, no) => { const s = document.createElement('script'); s.src = src; s.onload = ok; s.onerror = no; document.head.append(s); });
const loadFirebase = (cfg) => fbReady ||= (async () => { await loadScript(FB + 'firebase-app-compat.js'); await loadScript(FB + 'firebase-auth-compat.js'); firebase.initializeApp(cfg); })().catch((e) => { fbReady = null; throw e; });
const GLOGO = '<svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>';
async function googleButton(host, role, errEl) {
  host.innerHTML = `<button class="btn lg block gbtn-b" type="button">${GLOGO}<span>Lanjutkan dengan Google</span></button>`;
  host.insertAdjacentHTML('afterend', '<div class="or"><span>atau dengan email</span></div>');
  const btn = host.firstElementChild;
  btn.addEventListener('click', () => busy(btn, async () => {
    errEl.hidden = true;
    try {
      const cfg = (await fetch('/api/auth/config').then((r) => r.json())).firebase;
      if (!cfg) throw new Error('Login Google belum dikonfigurasi di server. Gunakan email dan kata sandi.');
      await loadFirebase(cfg);
      const cred = await firebase.auth().signInWithPopup(new firebase.auth.GoogleAuthProvider());
      const idToken = await cred.user.getIdToken();
      await firebase.auth().signOut();
      await finish(await api('/auth/firebase', { method: 'POST', body: { idToken, role: role() } }));
    } catch (e) {
      if (['auth/popup-closed-by-user', 'auth/cancelled-popup-request'].includes(e.code)) return;
      errEl.textContent = e.code === 'auth/popup-blocked' ? 'Popup diblokir browser. Izinkan popup untuk situs ini lalu coba lagi.' : e.code?.startsWith('auth/') ? 'Login Google gagal (' + e.code.slice(5) + '). Coba lagi atau pakai email.' : e.message;
      errEl.hidden = false;
    }
  }));
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

