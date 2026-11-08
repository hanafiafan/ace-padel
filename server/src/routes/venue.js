const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// POST /api/venue/verify-ticket
router.post('/verify-ticket', (req, res) => {
  const db = getDb();
  const { bookingId } = req.body;

  if (!bookingId) {
    return res
      .status(400)
      .json({ success: false, message: 'Kode booking wajib diisi' });
  }

  const cleanId = bookingId.trim().toUpperCase();
  const booking = db.bookings.find(
    (b) => b.id.toUpperCase() === cleanId || b.id.toUpperCase().startsWith(cleanId)
  );

  if (!booking) {
    // Check if it was cancelled
    const cancelled = db.history.find(
      (b) => b.id.toUpperCase() === cleanId || b.id.toUpperCase().startsWith(cleanId)
    );
    if (cancelled) {
      return res.status(400).json({
        success: false,
        valid: false,
        message: 'Tiket ini telah DIBATALKAN oleh pemain.',
        data: cancelled
      });
    }
    return res.status(404).json({
      success: false,
      valid: false,
      message: 'Kode tiket tidak ditemukan dalam sistem.'
    });
  }

  const court = db.courts.find((c) => c.id === booking.courtId);

  res.json({
    success: true,
    valid: true,
    message: 'Tiket valid dan terkonfirmasi.',
    data: {
      ...booking,
      court
    }
  });
});

// POST /api/venue/check-in
router.post('/check-in', (req, res) => {
  const db = getDb();
  const { bookingId } = req.body;

  if (!bookingId) {
    return res
      .status(400)
      .json({ success: false, message: 'Kode booking wajib diisi' });
  }

  const cleanId = bookingId.trim().toUpperCase();
  const booking = db.bookings.find(
    (b) => b.id.toUpperCase() === cleanId || b.id.toUpperCase().startsWith(cleanId)
  );

  if (!booking) {
    return res
      .status(404)
      .json({ success: false, message: 'Reservasi tidak ditemukan' });
  }

  booking.status = 'Check-in Selesai';
  booking.checkedInAt = new Date().toISOString();
  saveDb();

  res.json({
    success: true,
    message: `Pemain ${booking.userName} berhasil check-in. Selamat bermain!`,
    data: booking
  });
});

// POST /api/venue/toggle-slot (Block or unblock slot for maintenance/tournament)
router.post('/toggle-slot', (req, res) => {
  const db = getDb();
  const {
    courtId,
    date, // YYYY-MM-DD
    slot,
    action = 'block', // 'block' or 'unblock'
    reason = 'Perawatan Rutin Lapangan'
  } = req.body;

  if (!courtId || !date || !slot) {
    return res
      .status(400)
      .json({ success: false, message: 'courtId, date, dan slot wajib diisi' });
  }

  const dateStr = date.split('T')[0];

  if (action === 'block') {
    const existing = db.bookings.find(
      (b) => b.courtId === courtId && b.date.startsWith(dateStr) && b.slot === slot
    );

    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Slot ini sudah terisi booking pemain, batalkan booking terlebih dahulu.'
      });
    }

    const blockBooking = {
      id: `MAINT-${courtId.toUpperCase()}-${slot.replace(':', '')}`,
      courtId,
      userName: `[Blokir Mitra: ${reason}]`,
      date: dateStr,
      slot,
      pricePerHour: 0,
      discount: 0,
      finalPrice: 0,
      paymentMethod: 'Khusus Pengelola',
      status: 'Maintenance',
      createdAt: new Date().toISOString()
    };

    db.bookings.push(blockBooking);
    saveDb();

    return res.json({
      success: true,
      message: `Slot ${slot} pada ${dateStr} berhasil diblokir untuk ${reason}.`,
      data: blockBooking
    });
  } else {
    // Unblock
    const idx = db.bookings.findIndex(
      (b) =>
        b.courtId === courtId &&
        b.date.startsWith(dateStr) &&
        b.slot === slot &&
        b.status === 'Maintenance'
    );

    if (idx >= 0) {
      db.bookings.splice(idx, 1);
      saveDb();
      return res.json({
        success: true,
        message: `Slot ${slot} pada ${dateStr} berhasil dibuka kembali untuk publik.`
      });
    }

    return res
      .status(404)
      .json({ success: false, message: 'Slot maintenance tidak ditemukan.' });
  }
});

// GET /api/venue/stats/:courtId
router.get('/stats/:courtId', (req, res) => {
  const db = getDb();
  const { courtId } = req.params;

  const court = db.courts.find((c) => c.id === courtId);
  if (!court) {
    return res.status(404).json({ success: false, message: 'Court not found' });
  }

  const courtBookings = db.bookings.filter((b) => b.courtId === courtId);
  const checkedIn = courtBookings.filter((b) => b.status === 'Check-in Selesai');
  const totalRevenue = courtBookings
    .filter((b) => b.status !== 'Maintenance')
    .reduce((sum, b) => sum + (b.finalPrice || 0), 0);

  res.json({
    success: true,
    data: {
      court,
      totalBookings: courtBookings.length,
      checkedInCount: checkedIn.length,
      estimatedRevenueThousands: totalRevenue,
      estimatedRevenueFormatted: `Rp${totalRevenue}.000`
    }
  });
});

module.exports = router;

