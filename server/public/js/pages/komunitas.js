import { $, api, esc, rp, ic, fmt, watch } from '/js/site.js';

const seats = (m) => Array.from({ length: m.maxPlayers }, (_, i) => i < m.currentPlayers ? `<i title="${esc(m.players?.[i] || 'Pemain')}">${esc((m.players?.[i] || 'P')[0].toUpperCase())}</i>` : '<i class="open" aria-label="Slot kosong">+</i>').join('');

api('/matches').then((ms) => {
  const open = ms.filter((m) => m.currentPlayers < m.maxPlayers);
  const box = $('#matches'); box.setAttribute('aria-busy', 'false');
  $('#m-count').textContent = ms.length ? `${open.length} dari ${ms.length} match masih punya slot` : '';
  if (!ms.length) { box.innerHTML = `<div class="empty">${ic('users')}<h3>Belum ada mabar terbuka</h3><p class="muted">Jadilah yang pertama membuka match dan ajak pemain lain bergabung.</p><a class="btn btn--blue" href="/app/#/me">Buka match di aplikasi</a></div>`; return; }
  box.innerHTML = ms.map((m, i) => { const left = m.maxPlayers - m.currentPlayers; return `<article class="match rv" style="--d:${i * 60}ms">
    <div class="match__top"><span>${esc(m.dateString)}</span><span>${left > 0 ? `${left} slot tersisa` : 'Penuh'}</span></div>
    <div class="match__b"><h3>${esc(m.title)}</h3>
      <div class="match__meta"><span>${esc(m.time)}</span><span>${esc(m.court?.venue || '')}${m.court?.city ? ', ' + esc(m.court.city) : ''}</span><span>Level: ${esc(m.skillLevel)}</span><span>Host: ${esc(m.hostName)}</span></div>
      <div class="seats" aria-label="${m.currentPlayers} dari ${m.maxPlayers} pemain">${seats(m)}</div></div>
    <div class="match__f"><b>${rp(m.pricePerPlayer)}<small style="font:600 .8rem var(--font);color:#B4BBDD"> /pemain</small></b><a class="btn btn--sm${left ? '' : ' btn--ghost'}" style="${left ? '' : '--c:#fff'}" href="/app/#/me">${left ? 'Gabung' : 'Lihat'}</a></div></article>`; }).join('');
  watch(box);
}).catch(() => { $('#matches').setAttribute('aria-busy', 'false'); $('#matches').innerHTML = `<div class="empty"><h3>Mabar belum bisa dimuat</h3><p class="muted">Koneksi ke server bermasalah. Coba lagi.</p><button class="btn btn--blue" type="button" onclick="location.reload()">Muat ulang</button></div>`; });

const pod = (p, n) => `<div class="pod pod--${n}"><span class="pod__r" aria-hidden="true">${n}</span><span class="pod__av" aria-hidden="true">${esc((p.name || '?')[0])}</span><b>${esc(p.name)}</b><small>@${esc(p.username)}</small><span class="pod__pt">${fmt(p.points)}</span><small>${p.wins} menang dari ${p.matches} match</small></div>`;

api('/leaderboard').then((l) => {
  const box = $('#lb'); box.setAttribute('aria-busy', 'false');
  if (!l.length) { box.innerHTML = '<div class="empty" style="color:var(--ink)"><h3>Leaderboard masih kosong</h3><p class="muted">Peringkat muncul setelah pemain mengumpulkan poin.</p></div>'; return; }
  const [a, b, c] = l;
  box.innerHTML = `<div class="podium rv">${b ? pod(b, 2) : '<div></div>'}${pod(a, 1)}${c ? pod(c, 3) : '<div></div>'}</div>
    <ol class="lb rv" start="4">${l.slice(3, 10).map((p) => `<li><b>${p.rank}</b><div><strong>${esc(p.name)}</strong><small>@${esc(p.username)} &middot; ${p.wins} menang / ${p.matches} match</small></div><span class="pt">${fmt(p.points)}</span></li>`).join('')}</ol>`;
  watch(box);
}).catch(() => { $('#lb').setAttribute('aria-busy', 'false'); $('#lb').innerHTML = `<div class="empty" style="color:var(--ink)"><h3>Leaderboard belum bisa dimuat</h3><p class="muted">Coba muat ulang halaman ini.</p></div>`; });
