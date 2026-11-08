const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

const ALL_PLAYERS = [
  { id: 'p1', name: 'Rizky Pratama', username: 'rizky_p', points: 2480, wins: 42, matches: 51 },
  { id: 'p2', name: 'Dewi Anggraini', username: 'dewi_ang', points: 2310, wins: 38, matches: 49 },
  { id: 'p3', name: 'Kevin Sanjaya', username: 'kevin_s', points: 2155, wins: 35, matches: 47 },
  { id: 'p4', name: 'Afan', username: 'afan_ace', points: 1980, wins: 31, matches: 44, isMe: true },
  { id: 'p5', name: 'Putri Maharani', username: 'putri_m', points: 1870, wins: 29, matches: 43 },
  { id: 'p6', name: 'Bagas Wicaksono', username: 'bagas_w', points: 1720, wins: 26, matches: 40 },
  { id: 'p7', name: 'Siti Nurhaliza', username: 'siti_n', points: 1610, wins: 24, matches: 39 },
  { id: 'p8', name: 'Doni Saputra', username: 'doni_s', points: 1495, wins: 21, matches: 37 },
  { id: 'p9', name: 'Maya Lestari', username: 'maya_l', points: 1380, wins: 19, matches: 35 },
  { id: 'p10', name: 'Fajar Nugroho', username: 'fajar_n', points: 1240, wins: 16, matches: 33 },
  { id: 'p11', name: 'Sarah Wijaya', username: 'sarah_w', points: 1150, wins: 14, matches: 28 },
  { id: 'p12', name: 'Daniel Lim', username: 'daniel_lim', points: 980, wins: 11, matches: 22 }
];

// GET /api/friends
router.get('/', (req, res) => {
  const db = getDb();
  const friendIds = db.friends || [];
  const friendList = ALL_PLAYERS.filter((p) => friendIds.includes(p.id));

  res.json({
    success: true,
    data: friendIds,
    friends: friendList
  });
});

// POST /api/friends/add
router.post('/add', (req, res) => {
  const db = getDb();
  const { playerId } = req.body;

  if (!playerId) {
    return res.status(400).json({ success: false, message: 'playerId wajib diisi' });
  }

  if (!db.friends) db.friends = [];

  if (!db.friends.includes(playerId)) {
    db.friends.push(playerId);
    saveDb();
  }

  res.json({
    success: true,
    message: 'Berhasil menambahkan teman.',
    data: db.friends
  });
});

// POST /api/friends/remove
router.post('/remove', (req, res) => {
  const db = getDb();
  const { playerId } = req.body;

  if (!playerId) {
    return res.status(400).json({ success: false, message: 'playerId wajib diisi' });
  }

  if (db.friends) {
    db.friends = db.friends.filter((id) => id !== playerId);
    saveDb();
  }

  res.json({
    success: true,
    message: 'Berhasil menghapus teman.',
    data: db.friends || []
  });
});

// GET /api/friends/leaderboard?type=friends|global
router.get('/leaderboard', (req, res) => {
  const db = getDb();
  const type = req.query.type || 'global';
  const friendIds = db.friends || [];

  let list = [...ALL_PLAYERS];
  if (type === 'friends') {
    list = list.filter((p) => p.isMe || friendIds.includes(p.id));
  }

  list.sort((a, b) => b.points - a.points);

  res.json({
    success: true,
    type,
    count: list.length,
    data: list
  });
});

module.exports = router;

