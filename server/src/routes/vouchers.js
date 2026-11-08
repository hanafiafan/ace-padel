const express = require('express');
const { getDb } = require('../db');

const router = express.Router();

// GET /api/vouchers
router.get('/', (req, res) => {
  const db = getDb();
  res.json({ success: true, count: db.vouchers.length, data: db.vouchers });
});

// POST /api/vouchers/validate
router.post('/validate', (req, res) => {
  const db = getDb();
  const { code, amount = 0 } = req.body;

  if (!code) {
    return res.status(400).json({ success: false, message: 'Kode voucher harus diisi' });
  }

  const v = db.vouchers.find(
    (item) => item.code.toUpperCase() === code.trim().toUpperCase()
  );

  if (!v) {
    return res
      .status(404)
      .json({ success: false, valid: false, message: 'Kode voucher tidak valid' });
  }

  if (amount < (v.minSpend || 0)) {
    return res.status(400).json({
      success: false,
      valid: false,
      message: `Minimal transaksi untuk voucher ini adalah Rp${v.minSpend}k`
    });
  }

  let discount = 0;
  if (v.percentage) {
    let disc = Math.round(amount * v.percentage);
    if (v.maxDiscount && disc > v.maxDiscount) disc = v.maxDiscount;
    discount = disc;
  } else {
    discount = Math.min(amount, v.discountAmount);
  }

  res.json({
    success: true,
    valid: true,
    data: {
      voucher: v,
      discountAmount: discount,
      finalAmount: Math.max(0, amount - discount)
    }
  });
});

module.exports = router;

