const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/reviews/:courtId
router.get('/:courtId', (req, res) => {
  const db = getDb();
  const { courtId } = req.params;

  const list = db.reviews.filter((r) => r.courtId === courtId);
  const avg =
    list.length > 0
      ? (list.reduce((acc, curr) => acc + curr.rating, 0) / list.length).toFixed(1)
      : null;

  res.json({
    success: true,
    courtId,
    averageRating: avg ? parseFloat(avg) : null,
    totalReviews: list.length,
    data: list
  });
});

// POST /api/reviews
router.post('/', (req, res) => {
  const db = getDb();
  const {
    courtId,
    userName = 'Afan',
    rating = 5.0,
    comment,
    skillLevel = 'Menengah'
  } = req.body;

  if (!courtId || !comment) {
    return res.status(400).json({
      success: false,
      message: 'courtId dan isi ulasan (comment) wajib diisi'
    });
  }

  const court = db.courts.find((c) => c.id === courtId);
  if (!court) {
    return res.status(404).json({ success: false, message: 'Court tidak ditemukan' });
  }

  const newReview = {
    id: `r_${Date.now()}`,
    courtId,
    userName,
    rating: parseFloat(rating),
    comment: comment.trim(),
    date: 'Hari ini',
    skillLevel,
    createdAt: new Date().toISOString()
  };

  db.reviews.unshift(newReview);
  saveDb();

  res.status(201).json({
    success: true,
    message: 'Ulasan berhasil diterbitkan',
    data: newReview
  });
});

module.exports = router;

