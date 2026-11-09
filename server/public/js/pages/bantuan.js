import { $, $$ } from '/js/site.js';

const items = $$('#faqlist details');
const cats = [...new Set(items.map((d) => d.dataset.cat))];
$('#cats').insertAdjacentHTML('beforeend', cats.map((c) => `<button class="chip" type="button" data-c="${c.replace(/"/g, '&quot;')}" aria-pressed="false"><span>${c.replace(/&/g, '&amp;')}</span></button>`).join(''));
let cat = '';
const norm = (s) => s.toLowerCase();
function apply() {
  const q = norm($('#fq').value.trim());
  let n = 0;
  items.forEach((d) => {
    const hit = (!cat || d.dataset.cat === cat) && (!q || norm(d.textContent).includes(q));
    d.hidden = !hit; if (hit) n++;
  });
  $$('#cats .chip').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.c === cat)));
  $('#fempty').hidden = n > 0;
  $('#fcount').textContent = `${n} jawaban${q || cat ? ' cocok' : ''}`;
}
$('#fq').addEventListener('input', apply);
$('#cats').addEventListener('click', (e) => { const b = e.target.closest('.chip'); if (b) { cat = b.dataset.c; apply(); } });
apply();
if (location.hash) { const t = document.getElementById(location.hash.slice(1)); if (t?.tagName === 'DETAILS') t.open = true; }

/* Form kontak: hanya membangun tautan mailto, tidak mengirim apa pun */
const mail = () => {
  const n = $('#c-name').value.trim(), t = $('#c-topic').value, m = $('#c-msg').value.trim();
  const body = `Halo Ace Padel,\n\n${m}\n\nNama: ${n}\nTopik: ${t}`;
  $('#mailto').href = `mailto:hanafiafan20@gmail.com?subject=${encodeURIComponent('[Bantuan] ' + t)}&body=${encodeURIComponent(body)}`;
};
$('#cform').addEventListener('input', mail);
mail();
