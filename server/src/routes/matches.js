const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/matches
router.get('/', (req, res) => {
  const db = getDb();

  const list = db.matches.map((m) => {
    const court = db.courts.find((c) => c.id === m.courtId);
    return {
      ...m,
      court: court || null
    };
  });

  res.json({ success: true, count: list.length, data: list });
});

// POST /api/matches
router.post('/', (req, res) => {
  const db = getDb();
  const {
    courtId,
    dateString = 'Besok',
    time = '19:00 – 21:00 (2 jam)',
    title = 'Mabar Padel',
    hostName = 'Afan',
    skillLevel = 'Menengah (Intermediate)',
    pricePerPlayer
  } = req.body;

  if (!courtId) {
    return res.status(400).json({ success: false, message: 'courtId is required' });
  }

  const court = db.courts.find((c) => c.id === courtId);
  if (!court) {
    return res.status(404).json({ success: false, message: 'Court not found' });
  }

  const newMatch = {
    id: `m_${Date.now()}`,
    courtId,
    dateString,
    time,
    title,
    hostName,
    skillLevel,
    currentPlayers: 1,
    maxPlayers: 4,
    pricePerPlayer: pricePerPlayer || Math.round(court.pricePerHour / 2),
    players: [hostName],
    createdAt: new Date().toISOString()
  };

  db.matches.unshift(newMatch);
  saveDb();

  res.status(201).json({
    success: true,
    message: 'Match mabar berhasil dibuat',
    data: {
      ...newMatch,
      court
    }
  });
});

// POST /api/matches/:id/join
router.post('/:id/join', (req, res) => {
  const db = getDb();
  const { id } = req.params;
  const { userName = 'Afan' } = req.body;

  const match = db.matches.find((m) => m.id === id);
  if (!match) {
    return res.status(404).json({ success: false, message: 'Match tidak ditemukan' });
  }

  const playerIndex = match.players ? match.players.indexOf(userName) : -1;

  if (playerIndex >= 0) {
    // Leave match
    match.players.splice(playerIndex, 1);
    match.currentPlayers = Math.max(0, match.currentPlayers - 1);
    saveDb();
    return res.json({
      success: true,
      action: 'left',
      message: 'Anda keluar dari slot match ini',
      data: match
    });
  } else {
    // Join match
    if (match.currentPlayers >= match.maxPlayers) {
      return res.status(400).json({
        success: false,
        message: 'Slot pemain untuk match ini sudah penuh'
      });
    }

    if (!match.players) match.players = [];
    match.players.push(userName);
    match.currentPlayers += 1;
    saveDb();

    return res.json({
      success: true,
      action: 'joined',
      message: 'Berhasil bergabung dengan match!',
      data: match
    });
  }
});

module.exports = router;

