import { $, fmt, watch } from '/js/site.js';

const num = (id) => Math.max(0, +$(id).value || 0);
function calc() {
  const n = num('#c-n'), h = Math.min(24, num('#c-h')), p = num('#c-p'), o = num('#c-o') / 100;
  const hours = Math.round(n * h * 30 * o);
  $('#c-oo').textContent = Math.round(o * 100) + '%';
  $('#c-r').textContent = 'Rp' + fmt(Math.round(n * h * 30 * p * o));
  $('#c-d').textContent = `${fmt(hours)} jam terisi dari ${fmt(n * h * 30)} jam tersedia per bulan`;
}
$('#calc').addEventListener('input', calc);
calc();
watch();
