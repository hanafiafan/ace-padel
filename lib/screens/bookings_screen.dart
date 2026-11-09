import '../core/widgets/ap_banners.dart';
import 'package:flutter/material.dart';
import '../core/widgets/app_empty_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import 'package:intl/intl.dart';
import '../core/utils/ui.dart';
import '../data.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';
import '../main.dart' show tabIndex;
import 'doku_payment_sheet.dart';
import 'ticket_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (UserStore.instance.isLoggedIn) BookingStore.instance.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Saya',
              style: TextStyle(fontFamily: 'Display', fontSize: 24.64, fontWeight: FontWeight.w800),
            ).reveal(),
            const SizedBox(height: 14),

            // Tab bar
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AP.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AP.line),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AP.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AP.slate,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Mendatang'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab view
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([BookingStore.instance, UserStore.instance]),
                builder: (context, _) {
                  final store = BookingStore.instance;
                  final active = store.bookings;
                  final history = store.history;
                  if (!UserStore.instance.isLoggedIn) {
                    return AppEmptyState(
                      icon: LucideIcons.logIn,
                      title: 'Masuk untuk melihat booking',
                      message: 'Booking, tiket QR, dan riwayat Anda tersimpan di akun.',
                      actionLabel: 'Masuk / Daftar',
                      onAction: () => requireLogin(context, 'melihat booking Anda'),
                    );
                  }
                  if (store.isLoading && active.isEmpty && history.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (store.error != null && active.isEmpty && history.isEmpty) {
                    return AppEmptyState(
                      icon: LucideIcons.wifiOff,
                      title: 'Gagal memuat booking',
                      message: store.error!,
                      actionLabel: 'Coba lagi',
                      onAction: store.refresh,
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Active Tab
                      active.isEmpty
                          ? _emptyActive(context)
                          : RefreshIndicator(
                              onRefresh: store.refresh,
                              child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: active.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _BookingCard(
                                booking: active[i],
                                isActive: true,
                              ).reveal(i < 6 ? i : 6),
                            )),

                      // History Tab
                      history.isEmpty
                          ? _emptyHistory()
                          : RefreshIndicator(
                              onRefresh: store.refresh,
                              child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _BookingCard(
                                booking: history[i],
                                isActive: false,
                              ),
                            )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyActive(BuildContext context) => AppEmptyState(
        icon: LucideIcons.calendarX,
        title: 'Belum ada booking aktif',
        message: 'Pesan lapangan padel dari tab Home atau Courts.',
        actionLabel: 'Cari Lapangan Sekarang',
        onAction: () => tabIndex.value = 1,
      );

  Widget _emptyHistory() => const AppEmptyState(
        icon: LucideIcons.history,
        title: 'Belum ada riwayat booking',
        message: 'Booking yang telah selesai atau dibatalkan akan muncul di sini.',
      );
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isActive;

  const _BookingCard({required this.booking, required this.isActive});

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AP.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Reservasi?',
          style: TextStyle(fontFamily: 'Display', fontWeight: FontWeight.w800, fontSize: 20.7),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan jadwal bermain di ${booking.court.name} pada ${DateFormat('d MMM yyyy').format(booking.date)} pukul ${booking.slot} WIB?\n\nSlot jam ini akan segera dibuka kembali untuk pemain lain.',
          style:  TextStyle(color: AP.slate, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:  Text('Kembali',
                style: TextStyle(color: AP.slate, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await BookingStore.instance.cancel(booking);
                if (context.mounted) showInfo(context, 'Reservasi berhasil dibatalkan.');
              } on ApiException catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Batalkan',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = booking.court;
    final isCancelled = booking.status == 'Dibatalkan';
    final pending = booking.isPendingPayment;
    final statusLabel = pending ? 'Menunggu Pembayaran' : booking.status;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketScreen(booking: booking),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AP.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AP.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCancelled ? LucideIcons.circleX : LucideIcons.circleCheck,
                        size: 13,
                        color: isCancelled ? Colors.red : Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: isCancelled
                              ? Colors.red.shade700
                              : (pending ? Colors.orange.shade800 : Colors.green.shade800),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  booking.id,
                  style:  TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AP.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Court preview row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: apImg(
c.image, fallbackUrl: c.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: c.gradient),
                      ),
                      child: const APRacketIcon(color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(fontFamily: 'Display', 
                            fontSize: 18.4, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.venue} • ${c.area}',
                        style:  TextStyle(color: AP.slate, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp${booking.finalPrice}k • ${booking.paymentMethod}${booking.addOns.isNotEmpty ? ' • ${booking.addOns.length} add-on' : ''}',
                        style:  TextStyle(
                            color: AP.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
             Divider(color: AP.line, height: 1),
            const SizedBox(height: 10),

            // Date, time, and action row
            Row(
              children: [
                 Icon(LucideIcons.calendar, size: 14, color: AP.slate),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, d MMM yyyy').format(booking.date),
                  style:  TextStyle(
                      color: AP.ink, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                 Icon(LucideIcons.clock, size: 14, color: AP.slate),
                const SizedBox(width: 4),
                Text(
                  '${booking.slot} WIB',
                  style:  TextStyle(
                      color: AP.ink, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive && pending) ...[
                  InkWell(
                    onTap: () => showPendingPaymentDialog(context, booking),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text('Bayar',
                          style: TextStyle(color: AP.blue, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
                if (isActive) ...[
                  InkWell(
                    onTap: () => _showCancelDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.x, size: 14, color: Colors.red),
                          SizedBox(width: 3),
                          Text(
                            'Batalkan',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AP.lime,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.qrCode, size: 16, color: AP.onLime),
                      SizedBox(width: 4),
                      Text(
                        'Lihat E-Tiket',
                        style: TextStyle(
                          color: AP.onLime,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the VA number / QRIS reference for an unpaid online booking and lets
/// the (simulated) gateway confirm it via POST /bookings/:id/pay.
Future<void> showPendingPaymentDialog(BuildContext context, Booking b) async {
  final doku = await ApiService.instance.getPaymentProvider() == 'doku';
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AP.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(b.paymentMethod,
          style: const TextStyle(fontFamily: 'Display', fontWeight: FontWeight.w800, fontSize: 20.7)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total tagihan: Rp${b.finalPrice}.000', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (!doku) Text(b.paymentMethod.contains('QRIS') ? 'Kode QRIS' : 'Nomor Virtual Account',
              style: TextStyle(color: AP.slate, fontSize: 12)),
          if (doku)
            Text('Bayar lewat halaman DOKU (QRIS / Virtual Account).', style: TextStyle(color: AP.slate, fontSize: 12))
          else
            SelectableText(b.paymentRef ?? '-',
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 16)),
          if (b.paymentExpiresAt != null) ...[
            const SizedBox(height: 10),
            Text('Berlaku sampai ${DateFormat('HH:mm').format(b.paymentExpiresAt!)}',
                style: TextStyle(color: AP.slate, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Tutup', style: TextStyle(color: AP.slate))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            if (doku) {
              final paid = await showDokuPaymentSheet(context, b, allowClose: true);
              if (paid != null && context.mounted) showInfo(context, 'Pembayaran berhasil.');
              return;
            }
            try {
              await BookingStore.instance.pay(b);
              if (context.mounted) showInfo(context, 'Pembayaran berhasil.');
            } on ApiException catch (e) {
              if (context.mounted) showError(context, e);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AP.lime, foregroundColor: AP.onLime, elevation: 0),
          child: Text(doku ? 'Bayar sekarang' : 'Simulasikan Pembayaran', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}
