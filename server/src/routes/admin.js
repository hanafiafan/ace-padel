const express = require('express');
const { getDb, saveDb } = require('../db');

const router = express.Router();

// GET /api/admin/overview - Platform-wide KPI & metrics
router.get('/overview', (req, res) => {
  const db = getDb();
  const allBookings = [...(db.bookings || []), ...(db.history || [])];

  const paidBookings = allBookings.filter(
    (b) => b.status !== 'Maintenance' && b.status !== 'Dibatalkan'
  );

  const totalRevenue = paidBookings.reduce(
    (sum, b) => sum + (b.finalPrice || b.pricePerHour || 0),
    0
  );

  const activeBookings = (db.bookings || []).filter(
    (b) => b.status === 'Terkonfirmasi'
  ).length;

  const checkedInBookings = (db.bookings || []).filter(
    (b) => b.status === 'Check-in Selesai'
  ).length;

  const cancelledBookings = (db.history || []).filter(
    (b) => b.status === 'Dibatalkan'
  ).length;

  // Breakdown per court
  const courtsBreakdown = (db.courts || []).map((court) => {
    const courtBookings = (db.bookings || []).filter(
      (b) => b.courtId === court.id && b.status !== 'Maintenance'
    );
    const rev = courtBookings.reduce((sum, b) => sum + (b.finalPrice || 0), 0);
    return {
      id: court.id,
      name: court.name,
      venue: court.venue,
      area: court.area,
      pricePerHour: court.pricePerHour,
      indoor: court.indoor,
      totalBookings: courtBookings.length,
      revenueThousands: rev,
      revenueFormatted: `Rp${rev}.000`
    };
  });

  // Recent 10 transactions
  const recentBookings = [...(db.bookings || [])]
    .filter((b) => b.status !== 'Maintenance')
    .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
    .slice(0, 10);

  res.json({
    success: true,
    data: {
      metrics: {
        totalVenues: new Set((db.courts || []).map((c) => c.venue)).size,
        totalCourts: (db.courts || []).length,
        totalBookings: allBookings.length,
        activeBookings,
        checkedInBookings,
        cancelledBookings,
        totalRevenueThousands: totalRevenue,
        totalRevenueFormatted: `Rp${totalRevenue}.000`,
        totalUsers: (db.users || []).length + 4, // Including guests
        totalVouchers: (db.vouchers || []).length
      },
      courtsBreakdown,
      recentBookings
    }
  });
});

// GET /api/admin/courts - Get all courts with details
router.get('/courts', (req, res) => {
  const db = getDb();
  res.json({
    success: true,
    data: db.courts || []
  });
});

// POST /api/admin/courts - Add new venue court
router.post('/courts', (req, res) => {
  const db = getDb();
  const {
    name,
    venue,
    area,
    rating = 4.8,
    pricePerHour,
    indoor = true,
    facilities = [],
    description
  } = req.body;

  if (!name || !venue || !area || !pricePerHour) {
    return res.status(400).json({
      success: false,
      message: 'Field name, venue, area, dan pricePerHour wajib diisi'
    });
  }

  const newId = `c${(db.courts || []).length + 1}`;
  const newCourt = {
    id: newId,
    name,
    venue,
    area,
    rating: parseFloat(rating) || 4.8,
    pricePerHour: parseInt(pricePerHour, 10),
    indoor: Boolean(indoor),
    facilities: facilities.length > 0 ? facilities : ['Sewa Raket & Bola', 'Shower Air Panas', 'WiFi Cepat', 'Parkir Luas'],
    description: description || 'Lapangan padel modern dengan fasilitas komprehensif berstandar FIP.'
  };

  db.courts.push(newCourt);
  saveDb();

  res.status(201).json({
    success: true,
    message: `Lapangan ${name} di ${venue} berhasil ditambahkan ke platform.`,
    data: newCourt
  });
});

// PUT /api/admin/courts/:id - Update court
router.put('/courts/:id', (req, res) => {
  const db = getDb();
  const { id } = req.params;
  const court = (db.courts || []).find((c) => c.id === id);

  if (!court) {
    return res.status(404).json({ success: false, message: 'Lapangan tidak ditemukan' });
  }

  const { name, venue, area, pricePerHour, indoor, rating, description, facilities } = req.body;
  if (name !== undefined) court.name = name;
  if (venue !== undefined) court.venue = venue;
  if (area !== undefined) court.area = area;
  if (pricePerHour !== undefined) court.pricePerHour = parseInt(pricePerHour, 10);
  if (indoor !== undefined) court.indoor = Boolean(indoor);
  if (rating !== undefined) court.rating = parseFloat(rating);
  if (description !== undefined) court.description = description;
  if (facilities !== undefined) court.facilities = facilities;

  saveDb();

  res.json({
    success: true,
    message: `Lapangan ${court.name} berhasil diperbarui.`,
    data: court
  });
});

// GET /api/admin/bookings - List all bookings
router.get('/bookings', (req, res) => {
  const db = getDb();
  const { status, courtId, search } = req.query;

  let list = [...(db.bookings || []), ...(db.history || [])];

  if (status) {
    list = list.filter((b) => b.status.toLowerCase() === status.toLowerCase());
  }
  if (courtId) {
    list = list.filter((b) => b.courtId === courtId);
  }
  if (search) {
    const q = search.toLowerCase();
    list = list.filter(
      (b) =>
        (b.id && b.id.toLowerCase().includes(q)) ||
        (b.userName && b.userName.toLowerCase().includes(q)) ||
        (b.slot && b.slot.includes(q))
    );
  }

  // Sort descending by date & created
  list.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));

  res.json({
    success: true,
    data: list
  });
});

// GET /api/admin/vouchers - List all vouchers
router.get('/vouchers', (req, res) => {
  const db = getDb();
  res.json({
    success: true,
    data: db.vouchers || []
  });
});

// POST /api/admin/vouchers - Create new voucher
router.post('/vouchers', (req, res) => {
  const db = getDb();
  const { code, discount, description } = req.body;

  if (!code || !discount) {
    return res.status(400).json({
      success: false,
      message: 'Kode voucher dan nominal diskon wajib diisi'
    });
  }

  const cleanCode = code.trim().toUpperCase();
  const existing = (db.vouchers || []).find((v) => v.code === cleanCode);

  if (existing) {
    return res.status(409).json({
      success: false,
      message: `Kode voucher ${cleanCode} sudah ada.`
    });
  }

  const newVoucher = {
    code: cleanCode,
    discount: parseInt(discount, 10),
    description: description || `Diskon Rp${discount}.000 untuk reservasi lapangan.`
  };

  db.vouchers.push(newVoucher);
  saveDb();

  res.status(201).json({
    success: true,
    message: `Voucher promo ${cleanCode} berhasil dibuat.`,
    data: newVoucher
  });
});

// DELETE /api/admin/vouchers/:code - Delete voucher
router.delete('/vouchers/:code', (req, res) => {
  const db = getDb();
  const { code } = req.params;
  const cleanCode = code.trim().toUpperCase();

  const idx = (db.vouchers || []).findIndex((v) => v.code === cleanCode);
  if (idx === -1) {
    return res.status(404).json({
      success: false,
      message: 'Voucher tidak ditemukan'
    });
  }

  db.vouchers.splice(idx, 1);
  saveDb();

  res.json({
    success: true,
    message: `Voucher promo ${cleanCode} berhasil dihapus.`
  });
});

module.exports = router;

