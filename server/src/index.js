const express = require('express');
const cors = require('cors');
const path = require('path');

const courtsRouter = require('./routes/courts');
const bookingsRouter = require('./routes/bookings');
const matchesRouter = require('./routes/matches');
const vouchersRouter = require('./routes/vouchers');
const reviewsRouter = require('./routes/reviews');
const authRouter = require('./routes/auth');
const venueRouter = require('./routes/venue');
const friendsRouter = require('./routes/friends');
const adminRouter = require('./routes/admin');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Request logger
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ace-padel-backend',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Web Admin Dashboard Routes
app.get(['/', '/admin'], (req, res) => {
  res.sendFile(path.join(__dirname, 'public/admin.html'));
});

// Routes
app.use('/api/courts', courtsRouter);
app.use('/api/bookings', bookingsRouter);
app.use('/api/matches', matchesRouter);
app.use('/api/vouchers', vouchersRouter);
app.use('/api/reviews', reviewsRouter);
app.use('/api/auth', authRouter);
app.use('/api/venue', venueRouter);
app.use('/api/friends', friendsRouter);
app.use('/api/admin', adminRouter);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: err.message
  });
});

// Start server if executed directly
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🎾 Ace Padel Backend Server is running at http://localhost:${PORT}`);
    console.log(`📋 Health Check: http://localhost:${PORT}/api/health`);
    console.log(`🏟️ Courts API:  http://localhost:${PORT}/api/courts`);
    console.log(`📅 Bookings API: http://localhost:${PORT}/api/bookings`);
  });
}

module.exports = app;

