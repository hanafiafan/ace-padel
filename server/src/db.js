const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '../data/db.json');

const INITIAL_COURTS = [
  {
    id: 'c1',
    name: 'Center Court',
    venue: 'Ace Arena Senayan',
    area: 'Senayan, Jakarta',
    rating: 4.9,
    pricePerHour: 180,
    indoor: true,
    facilities: [
      'Sewa Raket & Bola',
      'Shower Air Panas',
      'Locker Room',
      'WiFi Cepat',
      'Parkir Luas',
      'Padel Cafe'
    ],
    description:
      'Lapangan padel standar internasional dengan karpet Mondo Supercourt generasi terbaru dan kaca tempered panoramic view untuk kenyamanan bermain maksimal.'
  },
  {
    id: 'c2',
    name: 'Glass Court 2',
    venue: 'Padel Point BSD',
    area: 'BSD, Tangerang',
    rating: 4.7,
    pricePerHour: 150,
    indoor: true,
    facilities: [
      'Sewa Raket & Bola',
      'Shower Air Panas',
      'Locker Room',
      'Parkir Luas'
    ],
    description:
      'Lapangan indoor ber-AC dengan pencahayaan LED profesional yang anti-silau.'
  },
  {
    id: 'c3',
    name: 'Sky Court',
    venue: 'Rooftop Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.8,
    pricePerHour: 165,
    indoor: false,
    facilities: [
      'Sewa Raket & Bola',
      'Padel Cafe',
      'Locker Room',
      'WiFi Cepat'
    ],
    description:
      'Lapangan outdoor di atas rooftop dengan pemandangan kota dan suasana sunset spektakuler.'
  },
  {
    id: 'c4',
    name: 'Sunset Court',
    venue: 'Bali Padel Canggu',
    area: 'Canggu, Badung',
    rating: 4.9,
    pricePerHour: 200,
    indoor: false,
    facilities: [
      'Sewa Raket & Bola',
      'Shower Air Panas',
      'Padel Cafe',
      'Locker Room',
      'Parkir Luas'
    ],
    description:
      'Venue tropis favorit pemain ekspatriat dan lokal dengan vibe santai di Canggu.'
  },
  {
    id: 'c5',
    name: 'Match Point Padel Court',
    venue: 'Nusantara Padel Pekanbaru',
    area: 'Sudirman, Pekanbaru',
    rating: 4.3,
    pricePerHour: 240,
    indoor: true,
    facilities: ['Sewa Raket & Bola', 'Locker Room', 'Parkir Luas'],
    description: 'Lapangan padel modern pertama dan terlengkap di Pekanbaru.'
  },
  {
    id: 'c6',
    name: 'Fusion Padel',
    venue: 'Victory Padel Samarinda',
    area: 'Air Hitam, Samarinda',
    rating: 4.5,
    pricePerHour: 120,
    indoor: false,
    facilities: ['Sewa Raket & Bola', 'Parkir Luas'],
    description: 'Venue outdoor ramah pemula dengan harga sewa terjangkau.'
  },
  {
    id: 'c7',
    name: 'Rally Padel Center',
    venue: 'Ace Padel Denpasar',
    area: 'Sanur, Denpasar',
    rating: 4.7,
    pricePerHour: 115,
    indoor: true,
    facilities: ['Sewa Raket & Bola', 'Shower Air Panas', 'WiFi Cepat'],
    description: 'Lapangan indoor sejuk di kawasan Sanur dengan komunitas aktif.'
  },
  {
    id: 'c8',
    name: 'Fusion Padel',
    venue: 'Victory Padel Semarang',
    area: 'Simpang Lima, Semarang',
    rating: 4.7,
    pricePerHour: 115,
    indoor: true,
    facilities: ['Sewa Raket & Bola', 'Locker Room', 'Parkir Luas'],
    description: 'Lokasi strategis di pusat kota Semarang dekat Simpang Lima.'
  }
];

const INITIAL_VOUCHERS = [
  {
    code: 'ACEWEEKEND',
    title: 'Diskon Akhir Pekan',
    description: 'Potongan Rp25.000 untuk sewa lapangan akhir pekan',
    discountAmount: 25,
    minSpend: 100
  },
  {
    code: 'PADELNEW',
    title: 'Member Baru 20%',
    description: 'Diskon 20% (maks Rp35.000) untuk member baru',
    discountAmount: 35,
    percentage: 0.2,
    maxDiscount: 35,
    minSpend: 120
  },
  {
    code: 'SMASH10',
    title: 'Smash Hemat Rp10k',
    description: 'Potongan langsung Rp10.000 tanpa syarat minimal',
    discountAmount: 10,
    minSpend: 0
  }
];

const INITIAL_MATCHES = [
  {
    id: 'm1',
    courtId: 'c1',
    dateString: 'Sabtu, 18 Okt',
    time: '19:00 – 21:00 (2 jam)',
    title: 'Mabar Santai Sabtu Malam (Ganda)',
    hostName: 'Rizky Pratama',
    skillLevel: 'Menengah (Intermediate)',
    currentPlayers: 3,
    maxPlayers: 4,
    pricePerPlayer: 65,
    players: ['Rizky Pratama', 'Kevin Sanjaya', 'Dewi Anggraini']
  },
  {
    id: 'm2',
    courtId: 'c3',
    dateString: 'Minggu, 19 Okt',
    time: '16:00 – 18:00 (2 jam)',
    title: 'Padel Sunset Friendly Match',
    hostName: 'Dewi Anggraini',
    skillLevel: 'Semua Level (Casual)',
    currentPlayers: 2,
    maxPlayers: 4,
    pricePerPlayer: 55,
    players: ['Dewi Anggraini', 'Bagas Wicaksono']
  }
];

const INITIAL_REVIEWS = [
  {
    id: 'r1',
    courtId: 'c1',
    userName: 'Budi Santoso',
    rating: 5.0,
    comment:
      'Kaca sangat jernih dan karpet Mondo Supercourt sangat empuk di lutut. Pencahayaan malam hari sangat terang!',
    date: '3 hari lalu',
    skillLevel: 'Menengah'
  },
  {
    id: 'r2',
    courtId: 'c1',
    userName: 'Nadya Putri',
    rating: 4.8,
    comment:
      'Fasilitas shower dan locker room bersih banget. Ada cafe enak buat ngopi setelah game.',
    date: '1 minggu lalu',
    skillLevel: 'Pemula'
  }
];

const INITIAL_USERS = [
  {
    id: 'u1',
    name: 'Afan',
    email: 'hanafiafan20@gmail.com',
    phone: '+62 812-3456-7890',
    skillLevel: 'Menengah (Intermediate)',
    role: 'player'
  }
];

let dbMemory = null;

function initDb() {
  const dir = path.dirname(DB_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  if (!fs.existsSync(DB_PATH)) {
    const defaultData = {
      courts: INITIAL_COURTS,
      bookings: [],
      history: [],
      matches: INITIAL_MATCHES,
      vouchers: INITIAL_VOUCHERS,
      reviews: INITIAL_REVIEWS,
      users: INITIAL_USERS
    };
    fs.writeFileSync(DB_PATH, JSON.stringify(defaultData, null, 2), 'utf-8');
    dbMemory = defaultData;
  } else {
    try {
      const raw = fs.readFileSync(DB_PATH, 'utf-8');
      dbMemory = JSON.parse(raw);
    } catch (err) {
      console.error('Error reading DB, re-initializing', err);
      dbMemory = {
        courts: INITIAL_COURTS,
        bookings: [],
        history: [],
        matches: INITIAL_MATCHES,
        vouchers: INITIAL_VOUCHERS,
        reviews: INITIAL_REVIEWS,
        users: INITIAL_USERS,
        friends: ['p1', 'p5']
      };
      fs.writeFileSync(DB_PATH, JSON.stringify(dbMemory, null, 2), 'utf-8');
    }
  }
  if (!dbMemory.friends) {
    dbMemory.friends = ['p1', 'p5'];
  }
  return dbMemory;
}

function getDb() {
  if (!dbMemory) {
    initDb();
  }
  return dbMemory;
}

function saveDb() {
  try {
    fs.writeFileSync(DB_PATH, JSON.stringify(dbMemory, null, 2), 'utf-8');
  } catch (err) {
    console.error('Failed to persist DB to file:', err);
  }
}

module.exports = {
  getDb,
  saveDb
};

