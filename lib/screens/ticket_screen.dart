import '../core/widgets/ap_shape.dart';
import '../core/widgets/ap_banners.dart';
import 'package:flutter/material.dart';
import '../core/utils/launch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/widgets/responsive_container.dart';
import '../data.dart';
import '../theme.dart';

class TicketScreen extends StatelessWidget {
  final Booking booking;

  const TicketScreen({super.key, required this.booking});

  void _showSaveCalendarSheet(BuildContext context) {
    final c = booking.court;
    final formattedDate = DateFormat('EEEE, d MMM yyyy').format(booking.date);

    showModalBottomSheet(
      context: context,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AP.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AP.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:  Icon(LucideIcons.calendarCheck,
                        color: AP.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SIMPAN KE KALENDER',
                        style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                            fontSize: 20.7, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Sinkronisasi jadwal main padel Anda',
                        style: TextStyle(color: AP.slate, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AP.cloud,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AP.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Main Padel @ ${c.name}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('$formattedDate • ${booking.slot} WIB (${booking.durationMinutes} menit)',
                        style: TextStyle(color: AP.slate, fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text('${c.venue}, ${c.area}', style: TextStyle(color: AP.slate, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    APLaunch.open(context, _calendarUri(), failMessage: 'Tidak bisa membuka Google Calendar.');
                  },
                  icon: const Icon(LucideIcons.calendarCheck, size: 18),
                  label: const Text('Buka di Google Calendar',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    shape: const ChamferBorder(br: 10, tl: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Template Google Calendar: acara sudah terisi, pengguna tinggal menyimpan.
  Uri _calendarUri() {
    final c = booking.court;
    final parts = booking.slot.split(':');
    final start = DateTime(booking.date.year, booking.date.month, booking.date.day,
        int.tryParse(parts[0]) ?? 0, int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    final end = start.add(Duration(minutes: booking.durationMinutes));
    final f = DateFormat("yyyyMMdd'T'HHmmss");
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': 'Main Padel @ ${c.name}',
      'dates': '${f.format(start)}/${f.format(end)}',
      'location': '${c.venue}, ${c.area}',
      'details': 'Kode booking: ${booking.id}',
    });
  }

  void _showDirectionsSheet(BuildContext context) {
    String selectedApp = 'Google Maps';
    final c = booking.court;

    showModalBottomSheet(
      context: context,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AP.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AP.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.navigation, color: AP.success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 19.55, fontWeight: FontWeight.w800)),
                        Text('${c.venue} • ${c.area}', style: TextStyle(color: AP.slate, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
               Text('Buka Menggunakan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AP.slate)),
              const SizedBox(height: 10),
              Row(
                children: [
                  'Google Maps',
                  'Waze',
                ].map((app) {
                  final sel = selectedApp == app;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(app),
                      selected: sel,
                      onSelected: (val) {
                        if (val) setSheetState(() => selectedApp = app);
                      },
                      selectedColor: AP.blue,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : AP.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    APLaunch.route(context,
                        place: '${c.venue}, ${c.area}', waze: selectedApp == 'Waze');
                  },
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  label: Text('Mulai Rute dengan $selectedApp',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    shape: const ChamferBorder(br: 10, tl: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = booking.court;
    final isCancelled = booking.status == 'Dibatalkan';

    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'E-Ticket Reservasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Bagikan Tiket',
            icon:  Icon(LucideIcons.share2, color: AP.blue),
            onPressed: () {
              final formattedDate =
                  DateFormat('EEEE, d MMM yyyy').format(booking.date);
              Clipboard.setData(ClipboardData(
                text:
                    '🎾 E-TICKET ACE PADEL\nKode Booking: ${booking.id}\nVenue: ${c.name} (${c.venue}, ${c.area})\nJadwal: $formattedDate • ${booking.slot} WIB\nTotal Biaya: Rp${booking.finalPrice}.000 (${booking.paymentMethod})\nStatus: ${booking.status}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Detail E-Ticket berhasil disalin ke clipboard.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveContainer(
        child: APList(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
          // Main ticket container
          Container(
            decoration: BoxDecoration(
              color: AP.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AP.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: apImageProvider(c.image),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: isCancelled ? .75 : .6), BlendMode.darken),
                    ),
                    gradient: LinearGradient(
                      colors: isCancelled
                          ? [Colors.grey.shade700, Colors.grey.shade800]
                          : c.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(23)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : AP.lime,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              isCancelled ? 'DIBATALKAN' : 'TERKONFIRMASI',
                              style: TextStyle(
                                color: isCancelled ? Colors.white : AP.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            booking.id,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        c.name,
                        style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                          color: Colors.white,
                          fontSize: 24.64,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${c.venue} • ${c.area}',
                              style: const TextStyle(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Booking details grid
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _infoBlock(
                              'TANGGAL',
                              DateFormat('EEEE, d MMM yyyy')
                                  .format(booking.date),
                              LucideIcons.calendar,
                            ),
                          ),
                          Expanded(
                            child: _infoBlock(
                              'WAKTU MAIN',
                              '${booking.slot} WIB (1 jam)',
                              LucideIcons.clock,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                       Divider(color: AP.line, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _infoBlock(
                              'METODE BAYAR',
                              booking.paymentMethod,
                              LucideIcons.creditCard,
                            ),
                          ),
                          Expanded(
                            child: _infoBlock(
                              'TOTAL BIAYA',
                              booking.discount > 0
                                  ? 'Rp${booking.finalPrice}k (Hemat Rp${booking.discount}k)'
                                  : 'Rp${booking.finalPrice}k',
                              LucideIcons.receipt,
                              valueColor: AP.blue,
                            ),
                          ),
                        ],
                      ),
                      if (booking.addOns.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AP.cloud,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AP.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                   APRacketIcon(size: 16, color: AP.blue),
                                  const SizedBox(width: 6),
                                   Text(
                                    'Perlengkapan Tambahan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AP.ink,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '+Rp${booking.addOnsTotal}k',
                                    style:  TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AP.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...booking.addOns.map(
                                (addon) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.check,
                                          size: 12, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text(
                                        addon,
                                        style:  TextStyle(
                                            fontSize: 11,
                                            color: AP.slate,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Perforated line design
                Row(
                  children: [
                     SizedBox(
                      width: 16,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AP.cloud,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const dashWidth = 6.0;
                          const dashSpace = 4.0;
                          final count = (constraints.constrainWidth() /
                                  (dashWidth + dashSpace))
                              .floor();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              count,
                              (_) =>  SizedBox(
                                width: dashWidth,
                                height: 1.5,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(color: AP.line),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                     SizedBox(
                      width: 16,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AP.cloud,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // QR Code Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AP.line, width: 1.5),
                        ),
                        child: _QrCodeMockup(bookingId: booking.id),
                      ),
                      const SizedBox(height: 12),
                       Text(
                        'Pindai QR ini di meja resepsionis saat check-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AP.slate,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSaveCalendarSheet(context),
                  icon:  Icon(LucideIcons.calendarCheck, color: AP.blue),
                  label: const Text('Simpan Kalender'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AP.ink,
                    side:  BorderSide(color: AP.line),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const ChamferBorder(br: 10, tl: 10),
                    backgroundColor: AP.surface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDirectionsSheet(context),
                  icon:  Icon(LucideIcons.navigation, color: AP.ink),
                  label: const Text(
                    'Petunjuk Arah',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: const ChamferBorder(br: 10, tl: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _infoBlock(String label, String value, IconData icon,
      {Color? valueColor}) {
    valueColor ??= AP.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AP.slate),
            const SizedBox(width: 4),
            Text(
              label,
              style:  TextStyle(
                color: AP.slate,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Stylized realistic QR Code generator mockup
class _QrCodeMockup extends StatelessWidget {
  final String bookingId;

  const _QrCodeMockup({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      color: Colors.white, // QR selalu gelap-di-atas-putih agar terbaca pemindai
      child: CustomPaint(
        painter: _QrPainter(seed: bookingId.hashCode),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final int seed;

  _QrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF151C4E)
      ..style = PaintingStyle.fill;

    final step = size.width / 21;

    // Corner finder patterns
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, 7 * step, 7 * step), paint);
      canvas.drawRect(
        Rect.fromLTWH(x + step, y + step, 5 * step, 5 * step),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 2 * step, y + 2 * step, 3 * step, 3 * step),
        paint,
      );
    }

    drawFinder(0, 0);
    drawFinder(size.width - 7 * step, 0);
    drawFinder(0, size.height - 7 * step);

    // Pseudorandom grid points inside based on seed
    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        // Skip corner finder areas
        if ((r < 8 && c < 8) ||
            (r < 8 && c > 12) ||
            (r > 12 && c < 8)) {
          continue;
        }
        final val = ((r * 31 + c * 17 + seed) % 7) < 3;
        if (val) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * step + 0.5, r * step + 0.5, step - 1, step - 1),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

