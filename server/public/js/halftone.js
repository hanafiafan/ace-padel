/* Footer wordmark halftone: kata raksasa dicetak sebagai titik, titik menjauh dari kursor (pegas) dan menghangat jadi lime; klik = gelombang kejut. */
export function halftoneFooter(root, { word = 'ACE PADEL', ink = '#E4E8FF', warm = '#C7F23C', gap = 6, radius = 80, crop = 0.2 } = {}) {
  const canvas = root.querySelector('canvas'), ctx = canvas.getContext('2d');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const rgb = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  const I = rgb(ink), W = rgb(warm);
  let w = 0, h = 0, dpr = 1, dots = new Float32Array(0), n = 0, px = -1e5, py = -1e5, raf = 0, visible = true, ring = { x: 0, y: 0, t: -1 };

  function layout() {
    const r = root.getBoundingClientRect();
    w = Math.max(1, Math.round(r.width)); h = Math.max(1, Math.round(r.height));
    dpr = Math.min(devicePixelRatio || 1, 2);
    canvas.width = w * dpr; canvas.height = h * dpr;
    const m = Object.assign(document.createElement('canvas'), { width: w, height: h }).getContext('2d', { willReadFrequently: true });
    const face = (s) => `800 ${s}px Display, "Barlow Condensed", Impact, sans-serif`;
    m.font = face(100);
    const size = (w * .98) / m.measureText(word).width * 100;
    m.font = face(size);
    const box = m.measureText(word), cap = box.actualBoundingBoxAscent || size * .72;
    m.fillText(word, (w - box.width) / 2, h + cap * crop);
    const a = m.getImageData(0, 0, w, h).data, cols = Math.ceil(w / gap), rows = Math.ceil(h / gap), t = [];
    for (let gy = 0; gy < rows; gy++) for (let gx = 0; gx < cols; gx++) {
      let s = 0;
      for (let sy = 0; sy < 3; sy++) for (let sx = 0; sx < 3; sx++) {
        const x = Math.min(w - 1, (gx * gap + (sx + .5) * gap / 3) | 0), y = Math.min(h - 1, (gy * gap + (sy + .5) * gap / 3) | 0);
        s += a[(y * w + x) * 4 + 3];
      }
      const c = s / 2295;
      if (c < .06) continue;
      const hx = gx * gap + gap / 2, hy = gy * gap + gap / 2;
      t.push(hx, hy, 0, 0, hx, hy, Math.sqrt(Math.min(1, c)) * gap * .56);
    }
    dots = new Float32Array(t); n = t.length / 7;
    wake();
  }

  function draw(now) {
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);
    const age = ring.t < 0 ? 1e9 : now - ring.t, rr = age * .9;
    let moving = false;
    for (let i = 0; i < n; i++) {
      const j = i * 7; let x = dots[j], y = dots[j + 1], vx = dots[j + 2], vy = dots[j + 3];
      const hx = dots[j + 4], hy = dots[j + 5];
      if (!reduced) {
        if (age < 900) {
          const dx = hx - ring.x, dy = hy - ring.y, d = Math.hypot(dx, dy) + .001, b = 1 - Math.min(1, Math.abs(d - rr) / 26);
          if (b > 0) { const f = b * 3.2 * (1 - age / 900); vx += dx / d * f; vy += dy / d * f; }
        }
        const dx = x - px, dy = y - py, d2 = dx * dx + dy * dy;
        if (d2 < radius * radius) { const d = Math.sqrt(d2) + .001, f = (1 - d / radius) * 2.6; vx += dx / d * f; vy += dy / d * f; }
        vx = (vx + (hx - x) * .05) * .84; vy = (vy + (hy - y) * .05) * .84; x += vx; y += vy;
        if (Math.abs(vx) + Math.abs(vy) > .02 || Math.abs(x - hx) + Math.abs(y - hy) > .05) moving = true;
        else { x = hx; y = hy; vx = vy = 0; }
        dots[j] = x; dots[j + 1] = y; dots[j + 2] = vx; dots[j + 3] = vy;
      }
      const k = Math.min(1, Math.hypot(x - hx, y - hy) / 28);
      ctx.fillStyle = k > .02 ? `rgb(${I.map((v, c) => Math.round(v + (W[c] - v) * k))})` : ink;
      ctx.beginPath(); ctx.arc(x, y, dots[j + 6], 0, 6.2832); ctx.fill();
    }
    return moving || age < 900 || px > -1e4;
  }
  const loop = (now) => { raf = 0; if (visible && draw(now)) raf = requestAnimationFrame(loop); };
  function wake() { if (!raf && visible) raf = requestAnimationFrame(loop); }
  const local = (e) => { const b = canvas.getBoundingClientRect(); return [e.clientX - b.left, e.clientY - b.top]; };
  root.addEventListener('pointermove', (e) => { [px, py] = local(e); wake(); });
  root.addEventListener('pointerleave', () => { px = py = -1e5; wake(); });
  root.addEventListener('pointerdown', (e) => { if (reduced) return; const [x, y] = local(e); ring = { x, y, t: performance.now() }; wake(); });
  new ResizeObserver(layout).observe(root);
  new IntersectionObserver((e) => { visible = e[0].isIntersecting; if (visible) wake(); }).observe(root);
  (document.fonts?.load('800 100px Display') ?? Promise.resolve()).then(layout);
  layout();
}
