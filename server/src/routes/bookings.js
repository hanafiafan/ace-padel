const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/bookings
router.get('/', (req, res) => {
  const db = getDb();

  // Populate court data
  const enrich = (booking) => {
    const court = db.courts.find((c) => c.id === booking.courtId);
    return {
      ...booking,
      court: court || null
    };
  };

  const active = db.bookings.map(enrich);
  const history = db.history.map(enrich);

  res.json({
    success: true,
    data: {
      active,
      history,
      totalActive: active.length,
      totalHistory: history.length
    }
  });
});

// POST /api/bookings
router.post('/', (req, res) => {
  const db = getDb();
  const {
    courtId,
    date, // YYYY-MM-DD
    slot, // "18:00"
    paymentMethod = 'Bayar di tempat',
    voucherCode,
    addOns = [],
    addOnsTotal = 0,
    userName = 'Afan'
  } = req.body;

  if (!courtId || !date || !slot) {
    return res.status(400).json({
      success: false,
      message: 'courtId, date (YYYY-MM-DD), and slot are required'
    });
  }

  const court = db.courts.find((c) => c.id === courtId);
  if (!court) {
    return res.status(404).json({ success: false, message: 'Court not found' });
  }

  const dateStr = date.split('T')[0];

  // Anti double-booking validation
  const existing = db.bookings.find(
    (b) =>
      b.courtId === courtId &&
      b.date.startsWith(dateStr) &&
      b.slot === slot &&
      b.status === 'Terkonfirmasi'
  );

  if (existing) {
    return res.status(409).json({
      success: false,
      message: 'Slot jam tersebut sudah dipesan oleh pemain lain (Anti Double-Booking).'
    });
  }

  // Voucher validation & discount calculation
  let discount = 0;
  let appliedVoucherCode = null;

  if (voucherCode) {
    const v = db.vouchers.find(
      (item) => item.code.toUpperCase() === voucherCode.trim().toUpperCase()
    );
    if (v && court.pricePerHour >= (v.minSpend || 0)) {
      appliedVoucherCode = v.code;
      if (v.percentage) {
        let disc = Math.round(court.pricePerHour * v.percentage);
        if (v.maxDiscount && disc > v.maxDiscount) disc = v.maxDiscount;
        discount = disc;
      } else {
        discount = v.discountAmount;
      }
    }
  }

  const addOnsList = Array.isArray(addOns) ? addOns : [];
  const addOnsPrice = Math.max(0, Number(addOnsTotal) || 0);
  const finalPrice = Math.max(0, court.pricePerHour + addOnsPrice - discount);
  const randomSuffix = Math.floor(1000 + Math.random() * 9000);
  const bookingId = `ACE-${courtId.toUpperCase()}-${slot.replace(':', '')}-${randomSuffix}`;

  const newBooking = {
    id: bookingId,
    courtId,
    userName,
    date: dateStr,
    slot,
    pricePerHour: court.pricePerHour,
    discount,
    addOns: addOnsList,
    addOnsTotal: addOnsPrice,
    finalPrice,
    paymentMethod,
    voucherCode: appliedVoucherCode,
    status: 'Terkonfirmasi',
    createdAt: new Date().toISOString()
  };

  db.bookings.push(newBooking);
  saveDb();

  res.status(201).json({
    success: true,
    message: 'Booking berhasil dikonfirmasi',
    data: {
      ...newBooking,
      court
    }
  });
});

// DELETE /api/bookings/:id
router.delete('/:id', (req, res) => {
  const db = getDb();
  const { id } = req.params;

  const index = db.bookings.findIndex((b) => b.id === id);
  if (index === -1) {
    return res
      .status(404)
      .json({ success: false, message: 'Booking tidak ditemukan' });
  }

  const [cancelled] = db.bookings.splice(index, 1);
  const historyEntry = {
    ...cancelled,
    status: 'Dibatalkan',
    cancelledAt: new Date().toISOString()
  };

  db.history.unshift(historyEntry);
  saveDb();

  res.json({
    success: true,
    message: 'Reservasi berhasil dibatalkan dan slot jam kembali terbuka',
    data: historyEntry
  });
});

module.exports = router;

