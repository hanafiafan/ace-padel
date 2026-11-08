const express = require('express');
const { getDb } = require('../db');

const router = express.Router();

const ALL_SLOTS = [
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
  '18:00',
  '19:00',
  '20:00',
  '21:00'
];

// GET /api/courts
router.get('/', (req, res) => {
  const db = getDb();
  let list = [...db.courts];

  const { q, indoor, city, facility, sortBy } = req.query;

  if (indoor !== undefined && indoor !== '') {
    const isIndoor = indoor === 'true';
    list = list.filter((c) => c.indoor === isIndoor);
  }

  if (city) {
    list = list.filter((c) => c.area.toLowerCase().includes(city.toLowerCase()));
  }

  if (facility) {
    list = list.filter(
      (c) =>
        c.facilities &&
        c.facilities.some((f) =>
          f.toLowerCase().includes(facility.toLowerCase())
        )
    );
  }

  if (q) {
    const search = q.toLowerCase();
    list = list.filter(
      (c) =>
        c.name.toLowerCase().includes(search) ||
        c.venue.toLowerCase().includes(search) ||
        c.area.toLowerCase().includes(search)
    );
  }

  if (sortBy === 'rating') {
    list.sort((a, b) => b.rating - a.rating);
  } else if (sortBy === 'price_asc' || sortBy === 'Harga Terendah') {
    list.sort((a, b) => a.pricePerHour - b.pricePerHour);
  } else if (sortBy === 'price_desc' || sortBy === 'Harga Tertinggi') {
    list.sort((a, b) => b.pricePerHour - a.pricePerHour);
  }

  res.json({
    success: true,
    count: list.length,
    data: list
  });
});

// GET /api/courts/cities
router.get('/meta/cities', (req, res) => {
  const db = getDb();
  const cities = [
    ...new Set(
      db.courts.map((c) =>
        c.area.includes(',') ? c.area.split(',').pop().trim() : c.area
      )
    )
  ].sort();

  res.json({ success: true, data: cities });
});

// GET /api/courts/:id
router.get('/:id', (req, res) => {
  const db = getDb();
  const court = db.courts.find((c) => c.id === req.params.id);

  if (!court) {
    return res.status(404).json({ success: false, message: 'Court not found' });
  }

  const reviews = db.reviews.filter((r) => r.courtId === court.id);

  res.json({
    success: true,
    data: {
      ...court,
      reviews
    }
  });
});

// GET /api/courts/:id/slots?date=YYYY-MM-DD
router.get('/:id/slots', (req, res) => {
  const db = getDb();
  const { id } = req.params;
  const { date } = req.query; // e.g. "2026-10-18"

  if (!date) {
    return res
      .status(400)
      .json({ success: false, message: 'Query param date (YYYY-MM-DD) is required' });
  }

  const court = db.courts.find((c) => c.id === id);
  if (!court) {
    return res.status(404).json({ success: false, message: 'Court not found' });
  }

  // Find all active bookings for this court and date
  const dateStr = date.split('T')[0];
  const bookedSlots = db.bookings
    .filter((b) => b.courtId === id && b.date.startsWith(dateStr) && b.status === 'Terkonfirmasi')
    .map((b) => b.slot);

  const slotsStatus = ALL_SLOTS.map((slot) => ({
    slot,
    available: !bookedSlots.includes(slot),
    taken: bookedSlots.includes(slot)
  }));

  res.json({
    success: true,
    courtId: id,
    date: dateStr,
    slots: slotsStatus
  });
});

module.exports = router;

