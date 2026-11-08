// Seed data awal. Hanya jalan sekali, saat tabel masih kosong.
const crypto = require('crypto');
const { hashPassword } = require('./lib/security');
const courts = require('./seed/courts.json');

const now = () => new Date().toISOString();
const J = JSON.stringify;

module.exports = function seed(db) {
  if (db.prepare('SELECT COUNT(*) n FROM users').get().n > 0) return;
  const prod = process.env.NODE_ENV === 'production';
  const demo = !prod || process.env.SEED_DEMO === '1'; // akun demo (password publik) hanya jika diminta
  const ins = (t, o) =>
    db.prepare(`INSERT INTO ${t} (${Object.keys(o)}) VALUES (${Object.keys(o).map(() => '?')})`).run(...Object.values(o));

  const user = (o) => ins('users', { role: 'player', auth_provider: 'email', created_at: now(), ...o });

  // Admin: di production wajib via env, kalau tidak dibuat random dan dicetak sekali.
  let adminPw = process.env.ADMIN_PASSWORD;
  if (!adminPw) {
    adminPw = prod ? crypto.randomBytes(9).toString('base64url') : 'admin12345';
    if (prod) console.log(`[seed] ADMIN_PASSWORD tidak di-set. Password admin sementara: ${adminPw}`);
  }
  user({ id: 'u_admin', name: 'Super Admin', username: 'admin', email: process.env.ADMIN_EMAIL || 'admin@acepadel.id', password_hash: hashPassword(adminPw), role: 'admin' });

  if (demo) {
    user({ id: 'u_owner', name: 'Budi Pemilik', username: 'budi_owner', email: 'owner@acepadel.id', password_hash: hashPassword('owner12345'), role: 'owner', phone: '+62 811-1111-2222' });
    user({ id: 'u_me', name: 'Afan', username: 'afan_ace', email: 'player@acepadel.id', password_hash: hashPassword('player12345'), points: 1980, wins: 31, matches: 44 });
  }

  // Pemain demo untuk leaderboard & mabar (tanpa password → tidak bisa login)
  [
    ['Rizky Pratama', 'rizky_p', 2480, 42, 51], ['Dewi Anggraini', 'dewi_ang', 2310, 38, 49],
    ['Kevin Sanjaya', 'kevin_s', 2155, 35, 47], ['Putri Maharani', 'putri_m', 1870, 29, 43],
    ['Bagas Wicaksono', 'bagas_w', 1720, 26, 40], ['Siti Nurhaliza', 'siti_n', 1610, 24, 39],
    ['Doni Saputra', 'doni_s', 1495, 21, 37], ['Maya Lestari', 'maya_l', 1380, 19, 35],
    ['Fajar Nugroho', 'fajar_n', 1240, 16, 33], ['Sarah Wijaya', 'sarah_w', 1150, 14, 28],
    ['Daniel Lim', 'daniel_lim', 980, 11, 22],
  ].forEach(([name, username, points, wins, matches], i) =>
    user({ id: `p_${username}`, name, username, email: `${username}@demo.acepadel.id`, points, wins, matches }));

  courts.forEach((c, i) =>
    ins('courts', {
      id: c.id, owner_id: demo && i < 5 ? 'u_owner' : null, name: c.name, venue: c.venue, area: c.area,
      price_per_hour: c.pricePerHour, indoor: c.indoor ? 1 : 0, rating: c.rating, image: c.image,
      facilities: J(c.facilities), description: c.description, status: 'approved', created_at: now(),
    }));

  [
    ['ACEWEEKEND', 'Diskon Akhir Pekan', 'Potongan Rp25.000 untuk sewa lapangan akhir pekan', 25, null, null, 100],
    ['PADELNEW', 'Member Baru 20%', 'Diskon 20% (maks Rp35.000) untuk member baru', 35, 0.2, 35, 120],
    ['SMASH10', 'Smash Hemat Rp10k', 'Potongan langsung Rp10.000 tanpa syarat minimal', 10, null, null, 0],
  ].forEach(([code, title, description, discount_amount, percentage, max_discount, min_spend]) =>
    ins('vouchers', { code, title, description, discount_amount, percentage, max_discount, min_spend }));

  [
    ['coach1', 'Edu Altimires Ros', 'Head Coach • FIP Certified Level 2', 4.98, 184, 290, '8 Tahun Head Coach Barcelona & Jakarta', 'assets/images/coach_edu_altimires.jpg', ['Bandeja & Vibora Master', 'Taktik Turnamen Double', 'Footwork Cepat'], ['Padel Pro Kemang', 'Social Padel House Menteng', 'Verde Sports Hub PIK 2'], 'Pelatih kepala asal Spanyol bersertifikat FIP Level 2. Berpengalaman membina atlet turnamen internasional dan program masterclass taktik padel ganda.'],
    ['coach2', 'Adrià Mercadal', 'FIP Pro Master & Senior Coach', 4.95, 142, 280, 'Mantan Pemain World Padel Tour', 'assets/images/coach_adria_mercadal.png', ['Power Smash Por Tres', 'Wall Rebound Defense', 'Match Intelligence'], ['Social Padel House Setiabudi', 'Rekket Space Padel Hall', 'SPACE PADEL PIK 2'], 'Pemain sirkuit profesional Spanyol dengan teknik wall rebound kelas dunia. Spesialis transisi bertahan ke counter-attack eksplosif.'],
    ['coach3', 'Adi Sila Pratama', 'Senior Sparring Partner & National Coach', 4.9, 126, 220, 'Mantan Atlet Tenis & Padel Nasional', 'assets/images/coach_adi_sila.jpg', ['Transisi Tenis ke Padel', 'Drill Ketahanan Rally', 'Volley Control'], ['Padel Pro Kemang', 'Maison de Padel', 'Artepola Padel Kemang'], 'Spesialis mengarahkan pemain tenis beralih ke padel secara natural tanpa cedera siku, menguasai kontrol sudut spin kaca yang akurat.'],
    ['coach4', 'Imron Jasuli', 'Bali Academy Coach & Clinic Lead', 4.92, 95, 200, '6 Tahun Melatih di Canggu & Sanur', 'assets/images/coach_imron_jasuli.jpg', ['Fundamental Grip & Stance', 'Konsistensi Rally Panjang', 'Fun Coaching'], ['HPC Atlas Beach Club', 'Bali Social Club Canggu', 'Jungle Padel Canggu'], 'Pelatih ramah, komunikatif, dan sabar yang fokus membangun fondasi teknik yang benar serta keseruan bermain.'],
  ].forEach(([id, name, title, rating, reviews_count, rate_per_hour, experience, image, sp, ve, bio]) =>
    ins('coaches', { id, name, title, rating, reviews_count, rate_per_hour, experience, image, specialties: J(sp), venues: J(ve), bio }));

  [
    ['m1', 'c1', 'p_rizky_p', 'Malam Ini', '19:00 – 21:00 (2 jam)', 'Mabar Santai Sabtu Malam (Ganda)', 'Menengah (Intermediate)', 4, 65, ['p_rizky_p', 'p_kevin_s', 'p_dewi_ang']],
    ['m2', 'c4', 'p_dewi_ang', 'Besok Sore', '16:30 – 18:30 (2 jam)', 'Padel Sunset Beach Rally & Chill', 'Semua Level (Casual)', 4, 95, ['p_dewi_ang', 'p_putri_m']],
    ['m3', 'c5', 'p_kevin_s', 'Senin Malam', '20:00 – 21:00 (1 jam)', 'Drill & Sparring Double Competitive', 'Mahir (Advanced)', 4, 50, ['p_kevin_s']],
    ['m4', 'c2', 'p_bagas_w', 'Rabu Malam', '19:00 – 20:30 (1.5 jam)', 'Executive After-Office Social Hit', 'Menengah (Intermediate)', 4, 75, ['p_bagas_w', 'p_siti_n']],
  ].forEach(([id, court_id, host_id, date_label, time, title, skill_level, max_players, price_per_player, ps]) => {
    ins('matches', { id, court_id, host_id, date_label, time, title, skill_level, max_players, price_per_player, created_at: now() });
    ps.forEach((u) => ins('match_players', { match_id: id, user_id: u }));
  });

  [
    ['c1', 'p_rizky_p', 5, 'Kaca sangat jernih dan karpet empuk di lutut. Pencahayaan malam hari sangat terang!'],
    ['c1', 'p_putri_m', 4.8, 'Fasilitas shower dan locker room bersih banget. Ada cafe enak buat ngopi setelah game.'],
    ['c2', 'p_kevin_s', 4.7, 'Lokasi strategis, parkir luas dan sewa raket tersedia.'],
    ['c4', 'p_dewi_ang', 4.9, 'View saat sunset luar biasa indah! Wajib coba slot jam 17:00.'],
  ].forEach(([court_id, user_id, rating, comment]) =>
    ins('reviews', { id: crypto.randomUUID(), court_id, user_id, rating, comment, created_at: now() }));

  ['p_rizky_p', 'p_putri_m'].forEach((f) => ['u_me'].forEach((u) => demo && ins('friends', { user_id: u, friend_id: f })));
};
