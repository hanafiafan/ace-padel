import { $$ } from '/js/site.js';

/* Scroll-spy ringan untuk sub-navigasi fitur */
const links = $$('.subnav a');
const map = new Map(links.map((a) => [a.getAttribute('href').slice(1), a]));
const io = new IntersectionObserver((es) => es.forEach((e) => {
  if (!e.isIntersecting) return;
  links.forEach((a) => a.classList.remove('on'));
  map.get(e.target.id)?.classList.add('on');
}), { rootMargin: '-45% 0px -50% 0px' });
map.forEach((_, id) => { const s = document.getElementById(id); if (s) io.observe(s); });
