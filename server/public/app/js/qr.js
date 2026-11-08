// Pembuat QR sederhana (mode byte, ECC M, versi 1-10). Algoritma mengikuti spesifikasi ISO 18004.
const EC = [10, 16, 26, 18, 24, 16, 18, 22, 22, 26], NB = [1, 1, 1, 2, 2, 4, 4, 4, 5, 5];
const gmul = (a, b) => { let r = 0; for (let i = 7; i >= 0; i--) { r = (r << 1) ^ ((r >>> 7) * 0x11d); r ^= ((b >>> i) & 1) * a; } return r; };
const raw = (v) => { let r = (16 * v + 128) * v + 64; if (v >= 2) { const n = Math.floor(v / 7) + 2; r -= (25 * n - 10) * n - 55; if (v >= 7) r -= 36; } return r; };
function rs(data, deg) {
  let div = new Array(deg).fill(0); div[deg - 1] = 1; let root = 1;
  for (let i = 0; i < deg; i++) { for (let j = 0; j < deg; j++) { div[j] = gmul(div[j], root); if (j + 1 < deg) div[j] ^= div[j + 1]; } root = gmul(root, 2); }
  const r = new Array(deg).fill(0);
  for (const b of data) { const f = b ^ r.shift(); r.push(0); div.forEach((c, i) => { r[i] ^= gmul(c, f); }); }
  return r;
}
export function qrMatrix(text) {
  const bytes = [...new TextEncoder().encode(text)];
  let ver = 1;
  for (;; ver++) {
    if (ver > 10) throw new Error('Teks terlalu panjang untuk QR');
    const cap = Math.floor(raw(ver) / 8) - EC[ver - 1] * NB[ver - 1];
    if (4 + (ver < 10 ? 8 : 16) + 8 * bytes.length <= cap * 8) break;
  }
  const cap = Math.floor(raw(ver) / 8) - EC[ver - 1] * NB[ver - 1];
  let bits = [];
  const put = (v, n) => { for (let i = n - 1; i >= 0; i--) bits.push((v >>> i) & 1); };
  put(4, 4); put(bytes.length, ver < 10 ? 8 : 16); bytes.forEach((b) => put(b, 8));
  put(0, Math.min(4, cap * 8 - bits.length)); while (bits.length % 8) bits.push(0);
  for (let p = 0xec; bits.length < cap * 8; p ^= 0xec ^ 0x11) put(p, 8);
  const data = []; for (let i = 0; i < bits.length; i += 8) data.push(parseInt(bits.slice(i, i + 8).join(''), 2));
  // blok + ECC + interleave
  const nb = NB[ver - 1], el = EC[ver - 1], rc = Math.floor(raw(ver) / 8), ns = nb - (rc % nb), sl = Math.floor(rc / nb);
  const blocks = []; let k = 0;
  for (let i = 0; i < nb; i++) { const d = data.slice(k, k + sl - el + (i < ns ? 0 : 1)); k += d.length; const e = rs(d, el); if (i < ns) d.push(0); blocks.push(d.concat(e)); }
  const all = [];
  for (let i = 0; i < blocks[0].length; i++) blocks.forEach((b, j) => { if (i !== sl - el || j >= ns) all.push(b[i]); });
  const size = ver * 4 + 17;
  const m = Array.from({ length: size }, () => new Array(size).fill(false)), fn = Array.from({ length: size }, () => new Array(size).fill(false));
  const sf = (x, y, v) => { m[y][x] = v; fn[y][x] = true; };
  for (let i = 0; i < size; i++) { sf(6, i, i % 2 === 0); sf(i, 6, i % 2 === 0); }
  const finder = (x, y) => { for (let dy = -4; dy <= 4; dy++) for (let dx = -4; dx <= 4; dx++) { const d = Math.max(Math.abs(dx), Math.abs(dy)), xx = x + dx, yy = y + dy; if (xx >= 0 && xx < size && yy >= 0 && yy < size) sf(xx, yy, d !== 2 && d !== 4); } };
  finder(3, 3); finder(size - 4, 3); finder(3, size - 4);
  if (ver > 1) {
    const n = Math.floor(ver / 7) + 2, step = Math.ceil((ver * 4 + 4) / (n * 2 - 2)) * 2, pos = [6];
    for (let p = size - 7; pos.length < n; p -= step) pos.splice(1, 0, p);
    pos.forEach((a, i) => pos.forEach((b, j) => { if ((i === 0 && j === 0) || (i === 0 && j === n - 1) || (i === n - 1 && j === 0)) return; for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) sf(a + dx, b + dy, Math.max(Math.abs(dx), Math.abs(dy)) !== 1); }));
  }
  const fmt = (mask) => {
    const d = mask; let r = d; for (let i = 0; i < 10; i++) r = (r << 1) ^ ((r >>> 9) * 0x537);
    const b = ((d << 10) | r) ^ 0x5412, g = (i) => ((b >>> i) & 1) === 1;
    for (let i = 0; i <= 5; i++) sf(8, i, g(i)); sf(8, 7, g(6)); sf(8, 8, g(7)); sf(7, 8, g(8));
    for (let i = 9; i < 15; i++) sf(14 - i, 8, g(i));
    for (let i = 0; i < 8; i++) sf(size - 1 - i, 8, g(i));
    for (let i = 8; i < 15; i++) sf(8, size - 15 + i, g(i));
    sf(8, size - 8, true);
  };
  fmt(0);
  if (ver >= 7) { let r = ver; for (let i = 0; i < 12; i++) r = (r << 1) ^ ((r >>> 11) * 0x1f25); const b = (ver << 12) | r; for (let i = 0; i < 18; i++) { const c = ((b >>> i) & 1) === 1, a = size - 11 + (i % 3), q = Math.floor(i / 3); sf(a, q, c); sf(q, a, c); } }
  let i = 0;
  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right = 5;
    for (let vert = 0; vert < size; vert++) for (let j = 0; j < 2; j++) {
      const x = right - j, y = ((right + 1) & 2) === 0 ? size - 1 - vert : vert;
      if (!fn[y][x] && i < all.length * 8) { m[y][x] = ((all[i >>> 3] >>> (7 - (i & 7))) & 1) === 1; i++; }
    }
  }
  const mask = (mk) => { for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const inv = [(x + y) % 2 === 0, y % 2 === 0, x % 3 === 0, (x + y) % 3 === 0, (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0, ((x * y) % 2) + ((x * y) % 3) === 0, (((x * y) % 2) + ((x * y) % 3)) % 2 === 0, (((x + y) % 2) + ((x * y) % 3)) % 2 === 0][mk];
    if (!fn[y][x] && inv) m[y][x] = !m[y][x]; } };
  const penalty = () => { let p = 0; for (let a = 0; a < size; a++) for (const row of [true, false]) { let run = 1; for (let b = 1; b < size; b++) { const c = row ? m[a][b] === m[a][b - 1] : m[b][a] === m[b - 1][a]; run = c ? run + 1 : 1; if (run === 5) p += 3; else if (run > 5) p++; } } return p; };
  let best = 0, bp = Infinity;
  for (let mk = 0; mk < 8; mk++) { mask(mk); fmt(mk); const p = penalty(); if (p < bp) { bp = p; best = mk; } mask(mk); }
  mask(best); fmt(best);
  return m;
}
export function qrSvg(text, px = 180) {
  const m = qrMatrix(text), n = m.length + 8; let d = '';
  m.forEach((row, y) => row.forEach((v, x) => { if (v) d += `M${x + 4} ${y + 4}h1v1h-1z`; }));
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n} ${n}" width="${px}" height="${px}" role="img" aria-label="Kode QR tiket" shape-rendering="crispEdges"><rect width="${n}" height="${n}" fill="#fff"/><path d="${d}" fill="#12152b"/></svg>`;
}
