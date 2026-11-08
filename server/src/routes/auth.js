const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// POST /api/auth/login
router.post('/login', (req, res) => {
  const db = getDb();
  const { email } = req.body;

  let user = db.users.find((u) => u.email.toLowerCase() === (email || '').toLowerCase());

  if (!user) {
    // Auto-create or guest profile for seamless mobile UX
    user = {
      id: `u_${Date.now()}`,
      name: email ? email.split('@')[0] : 'Player Padel',
      email: email || 'player@padel.id',
      phone: '+62 812-3456-7890',
      skillLevel: 'Menengah (Intermediate)',
      role: 'player'
    };
    db.users.push(user);
    saveDb();
  }

  res.json({
    success: true,
    message: 'Login berhasil',
    token: `token_${user.id}_${Date.now()}`,
    data: user
  });
});

// POST /api/auth/google
router.post('/google', (req, res) => {
  const db = getDb();
  const { email, name, photoUrl, googleId } = req.body;

  if (!email) {
    return res.status(400).json({
      success: false,
      message: 'Email Google diperlukan untuk autentikasi'
    });
  }

  let user = db.users.find((u) => u.email.toLowerCase() === email.toLowerCase());

  if (!user) {
    user = {
      id: `u_google_${googleId || Date.now()}`,
      name: name || email.split('@')[0],
      email: email,
      phone: '+62 812-3456-7890',
      photoUrl: photoUrl || null,
      skillLevel: 'Menengah (Intermediate)',
      preferredHand: 'Tangan Kanan (Right-handed)',
      role: 'player',
      authProvider: 'google',
      googleId: googleId || null,
      createdAt: new Date().toISOString()
    };
    db.users.push(user);
    saveDb();
  } else {
    if (name) user.name = name;
    if (photoUrl) user.photoUrl = photoUrl;
    user.authProvider = 'google';
    if (googleId) user.googleId = googleId;
    saveDb();
  }

  res.json({
    success: true,
    message: 'Login Google berhasil',
    token: `token_google_${user.id}_${Date.now()}`,
    data: user
  });
});

// GET /api/auth/profile
router.get('/profile', (req, res) => {
  const db = getDb();
  const user = db.users[0]; // Active user

  const myBookings = db.bookings.filter((b) => b.userName === user.name);

  res.json({
    success: true,
    data: {
      ...user,
      stats: {
        totalActiveBookings: myBookings.length,
        totalHoursPlayed: myBookings.length * 2 + 10,
        playerRating: 4.9
      }
    }
  });
});

// PUT /api/auth/profile
router.put('/profile', (req, res) => {
  const db = getDb();
  const user = db.users[0];
  const { name, phone, skillLevel } = req.body;

  if (name) user.name = name;
  if (phone) user.phone = phone;
  if (skillLevel) user.skillLevel = skillLevel;

  saveDb();

  res.json({
    success: true,
    message: 'Profil berhasil diperbarui',
    data: user
  });
});

module.exports = router;

