import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import '../core/widgets/ap_banners.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/utils/ui.dart';
import '../data.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';
import '../main.dart' show tabIndex;
import 'doku_payment_sheet.dart';
import 'ticket_screen.dart';

class ConfirmScreen extends StatefulWidget {
  final Court court;
  final DateTime date;
  final String slot;
  final int durationMinutes;
  const ConfirmScreen({
    super.key,
    required this.court,
    required this.date,
    required this.slot,
    this.durationMinutes = 60,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool _done = false;
  String _selectedPayment = PaymentPrefStore.instance.method;
  Voucher? _appliedVoucher;
  Booking? _createdBooking;
  final Map<String, int> _selectedAddOns = {};

  int get _addOnsTotal {
    int total = 0;
    for (final entry in _selectedAddOns.entries) {
      if (entry.value > 0) {
        final item = equipmentAddOns.firstWhere(
          (e) => e.id == entry.key,
          orElse: () => equipmentAddOns.first,
        );
        total += item.price * entry.value;
      }
    }
    return total;
  }

  int get _baseCourtPrice =>
      (widget.court.pricePerHour * widget.durationMinutes / 60).round();

  int get _discountAmount =>
      _appliedVoucher?.calculateDiscount(_baseCourtPrice) ?? 0;

  int get _finalTotal =>
      (_baseCourtPrice + _addOnsTotal - _discountAmount).clamp(0, 999999);

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'id': 'Bayar di tempat',
      'title': 'Bayar di Venue',
      'subtitle': 'Bayar tunai/kartu di meja resepsionis',
      'icon': LucideIcons.banknote,
    },
    {
      'id': 'QRIS Instant',
      'title': 'QRIS Instant Pay',
      'subtitle': 'BCA, GoPay, OVO, ShopeePay, Dana',
      'icon': LucideIcons.qrCode,
    },
    {
      'id': 'BCA Virtual Account',
      'title': 'BCA Virtual Account',
      'subtitle': 'Transfer otomatis via m-BCA / ATM',
      'icon': LucideIcons.landmark,
    },
    {
      'id': 'Mandiri Virtual Account',
      'title': 'Mandiri Virtual Account',
      'subtitle': 'Transfer instan Livin by Mandiri',
      'icon': LucideIcons.wallet,
    },
  ];

  bool _submitting = false;

  /// Server-side add-on ids, repeated by quantity (server prices them).
  List<String> get _addOnIds => [
        for (final e in _selectedAddOns.entries)
          for (var i = 0; i < e.value; i++) e.key,
      ];

  /// POST /bookings. Returns null on failure (message already shown).
  Future<Booking?> _createBooking() async {
    if (_submitting) return null;
    if (!requireLogin(context, 'memesan lapangan')) return null;
    setState(() => _submitting = true);
    try {
      return await BookingStore.instance.book(
        widget.court,
        widget.date,
        widget.slot,
        paymentMethod: _selectedPayment,
        voucherCode: _appliedVoucher?.code,
        addOnIds: _addOnIds,
      );
    } on ApiException catch (e) {
      if (!mounted) return null;
      if (e.isConflict) {
        showInfo(context, 'Slot itu baru saja dipesan pemain lain. Silakan pilih jam lain.');
        Navigator.pop(context); // kembali ke pilih jam (slot sudah di-refresh)
      } else {
        showError(context, e);
      }
      return null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _finish(Booking b) {
    setState(() {
      _createdBooking = b;
      _done = true;
    });
  }

  /// Pay-at-venue: create the booking directly.
  Future<void> _confirm() async {
    final b = await _createBooking();
    if (b != null && mounted) _finish(b);
  }

  /// Simulated gateway callback for online methods.
  Future<void> _payNow(Booking b) async {
    try {
      final paid = await BookingStore.instance.pay(b);
      if (mounted) _finish(paid);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// Dismissing the payment sheet cancels the unpaid booking so the slot reopens.
  Future<void> _abandon(Booking b) async {
    try {
      await BookingStore.instance.cancel(b);
    } on ApiException catch (_) {}
  }

  /// POST /vouchers/validate (server is authoritative). Returns true if applied.
  Future<bool> _applyVoucher(String code) async {
    try {
      final (v, _) = await CatalogStore.instance.validateVoucher(code, _baseCourtPrice);
      if (!mounted) return false;
      setState(() => _appliedVoucher = v);
      showInfo(context, 'Voucher ${v.code} berhasil dipasang!');
      return true;
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
      return false;
    }
  }

  void _showVoucherPicker() {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
            const Text(
              'GUNAKAN VOUCHER PROMO',
              style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            // Input manual code
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kode promo',
                      filled: true,
                      fillColor: AP.cloud,
                      prefixIcon:
                           Icon(LucideIcons.tag, color: AP.slate),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final typed = codeCtrl.text.trim().toUpperCase();
                    if (typed.isEmpty) return;
                    if (await _applyVoucher(typed) && ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.blue,
                    foregroundColor: Colors.white,
                    shape: const ChamferBorder(br: 10, tl: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Pakai',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),

            const SizedBox(height: 16),
             Text(
              'Voucher Tersedia Untukmu',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AP.slate),
            ),
            const SizedBox(height: 10),

            ...CatalogStore.instance.vouchers.map((v) {
              final isApplied = _appliedVoucher?.code == v.code;
              final disc = v.calculateDiscount(_baseCourtPrice);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isApplied
                      ? AP.lime.withValues(alpha: 0.15)
                      : AP.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isApplied ? AP.blue : AP.line,
                    width: isApplied ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AP.lime.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  Icon(LucideIcons.ticket,
                          color: AP.ink, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Hemat Rp${disc}k',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            v.description,
                            style:  TextStyle(
                                color: AP.slate, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (isApplied) {
                          setState(() => _appliedVoucher = null);
                          Navigator.pop(ctx);
                        } else if (await _applyVoucher(v.code) && ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(
                        isApplied ? 'Lepas' : 'Gunakan',
                        style: TextStyle(
                          color: isApplied ? Colors.red : AP.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPaymentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            const Text(
              'PILIH METODE PEMBAYARAN',
              style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ..._paymentOptions.map((opt) {
              final isSelected = _selectedPayment == opt['id'];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? AP.blue : AP.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Icon(opt['icon'] as IconData,
                    color: isSelected ? AP.blue : AP.slate),
                title: Text(
                  opt['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  opt['subtitle'] as String,
                  style:  TextStyle(color: AP.slate, fontSize: 12),
                ),
                trailing: Icon(
                  isSelected
                      ? LucideIcons.circleDot
                      : LucideIcons.circle,
                  color: isSelected ? AP.blue : AP.slate,
                ),
                onTap: () {
                  setState(() => _selectedPayment = opt['id'] as String);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentFlow() async {
    if (_selectedPayment == 'Bayar di tempat') {
      await _confirm();
      return;
    }
    // Online: reserve the slot first (status Menunggu) to get the VA / QRIS reference.
    final b = await _createBooking();
    if (b == null || !mounted) return;
    if (await ApiService.instance.getPaymentProvider() == 'doku') {
      if (!mounted) return;
      final paid = await showDokuPaymentSheet(context, b);
      if (paid != null && mounted) _finish(paid);
      return;
    }
    if (!mounted) return;
    if (_selectedPayment == 'QRIS Instant') {
      _showQrisSheet(b);
    } else {
      _showVaSheet(b);
    }
  }

  void _showQrisSheet(Booking b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'QRIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                 Text(
                  'Standar Pembayaran Nasional',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AP.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.court.venue} • Ace Padel',
              style:  TextStyle(color: AP.slate, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp${b.finalPrice}.000',
              style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                fontSize: 29.12,
                fontWeight: FontWeight.w800,
                color: AP.blue,
              ),
            ),
            const SizedBox(height: 16),
            // Simulated QRIS Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AP.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AP.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _QrisPatternPainter(),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AP.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AP.ink, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child:  APRacketIcon(color: AP.blue, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AP.lime.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child:  Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.timer, size: 14, color: AP.ink),
                  const SizedBox(width: 6),
                  Text(
                    b.paymentExpiresAt != null
                        ? 'Selesaikan pembayaran sebelum ${DateFormat('HH:mm').format(b.paymentExpiresAt!)}'
                        : 'Selesaikan pembayaran dalam 15 menit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AP.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(b.paymentRef ?? '',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
             Text(
              'Scan menggunakan BCA Mobile, GoPay, OVO, ShopeePay, Dana, atau LinkAja',
              textAlign: TextAlign.center,
              style: TextStyle(color: AP.slate, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _payNow(b);
                },
                icon:  Icon(LucideIcons.badgeCheck, color: AP.ink),
                label:  Text(
                  'Simulasikan Pembayaran Berhasil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AP.ink,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AP.lime,
                  elevation: 0,
                  shape: const ChamferBorder(br: 10, tl: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _abandon(b);
              },
              child:  Text(
                'Batalkan Pembayaran',
                style: TextStyle(color: AP.slate, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVaSheet(Booking b) {
    final isBca = _selectedPayment.contains('BCA');
    final rawRef = b.paymentRef ?? '';
    final vaNumber = RegExp(r'.{1,4}').allMatches(rawRef).map((m) => m.group(0)).join(' ');
    final bankName = isBca ? 'BCA Virtual Account' : 'Mandiri Virtual Account';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBca ? LucideIcons.landmark : LucideIcons.wallet,
                    color: AP.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 18.4, fontWeight: FontWeight.w800),
                    ),
                     Text(
                      'Transfer instan otomatis terverifikasi',
                      style: TextStyle(color: AP.slate, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AP.cloud,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AP.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Nomor Virtual Account',
                      style: TextStyle(color: AP.slate, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vaNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: vaNumber.replaceAll(' ', '')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor VA berhasil disalin!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AP.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AP.line),
                          ),
                          child:  Row(
                            children: [
                              Icon(LucideIcons.copy, size: 14, color: AP.blue),
                              const SizedBox(width: 4),
                              Text('Salin',
                                  style: TextStyle(
                                      color: AP.blue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                   Divider(color: AP.line, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text('Total Tagihan',
                          style: TextStyle(color: AP.slate, fontSize: 12)),
                      Text(
                        'Rp${b.finalPrice}.000',
                        style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                          fontSize: 18.4,
                          fontWeight: FontWeight.w800,
                          color: AP.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Petunjuk Transfer:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
             Text(
              '1. Buka aplikasi m-Banking atau ATM Anda\n2. Pilih menu Transfer > Virtual Account\n3. Masukkan nomor VA di atas lalu pastikan nama tertera "Ace Padel - Afan"\n4. Konfirmasi transaksi',
              style: TextStyle(color: AP.slate, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _payNow(b);
                },
                icon:  Icon(LucideIcons.circleCheck, color: AP.ink),
                label:  Text(
                  'Simulasikan Transfer Berhasil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AP.ink,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AP.lime,
                  elevation: 0,
                  shape: const ChamferBorder(br: 10, tl: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _abandon(b);
                },
                child:  Text(
                  'Batalkan',
                  style: TextStyle(color: AP.slate, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: Text(
          _done ? 'Booking Berhasil' : 'Konfirmasi Reservasi',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        automaticallyImplyLeading: !_done,
      ),
      body: _done ? _success() : _summary(),
      bottomNavigationBar: _done
          ? null
          : _bottom(
              label: _selectedPayment == 'Bayar di tempat'
                  ? 'Konfirmasi Booking Sekarang'
                  : 'Lanjut ke Pembayaran ($_selectedPayment)',
              onTap: _submitting ? () {} : _handlePaymentFlow,
            ),
    );
  }

  // ---- Ringkasan sebelum konfirmasi ----
  Widget _summary() {
    final c = widget.court;
    return APList(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 132,
            child: APPhoto(
              asset: c.image, fallbackUrl: c.imageUrl,
              scrim: .82,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                                  color: Colors.white,
                                  fontSize: 20.7,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('${c.venue} • ${c.area}',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
              const SizedBox(height: 18),
              _card([
                _row(LucideIcons.calendar, 'Tanggal',
                    DateFormat('EEE, d MMM yyyy').format(widget.date)),
                _divider(),
                _row(LucideIcons.clock, 'Jam',
                    '${widget.slot} – ${_plusOneHour(widget.slot)}'),
                _divider(),
                _row(LucideIcons.mapPin, 'Lokasi', c.area),
                _divider(),
                InkWell(
                  onTap: _showPaymentPicker,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                         Icon(LucideIcons.banknote,
                            size: 20, color: AP.blue),
                        const SizedBox(width: 12),
                         Text('Pembayaran',
                            style: TextStyle(color: AP.slate)),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            _selectedPayment,
                            textAlign: TextAlign.right,
                            style:  TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AP.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                         Icon(LucideIcons.chevronRight,
                            size: 18, color: AP.slate),
                      ],
                    ),
                  ),
                ),
                _divider(),
                InkWell(
                  onTap: _showVoucherPicker,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.tag,
                            size: 20, color: Color(0xFFF08A3A)),
                        const SizedBox(width: 12),
                         Text('Voucher Promo',
                            style: TextStyle(color: AP.slate)),
                        const Spacer(),
                        if (_appliedVoucher != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AP.lime.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${_appliedVoucher!.code} (-Rp${_discountAmount}k)',
                                  style:  TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AP.ink,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _appliedVoucher = null);
                                  },
                                  child:  Icon(LucideIcons.x,
                                      size: 14, color: AP.slate),
                                ),
                              ],
                            ),
                          )
                        else
                           Row(
                            children: [
                              Text(
                                'Pilih voucher',
                                style: TextStyle(
                                  color: AP.blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.chevronRight,
                                  size: 18, color: AP.slate),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),

              // Card Sewa Alat & Perlengkapan Tambahan (Opsional)
              Container(
                decoration: BoxDecoration(
                  color: AP.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AP.line),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AP.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:  APRacketIcon(color: AP.blue, size: 20),
                        ),
                        const SizedBox(width: 10),
                         Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sewa Alat & Perlengkapan',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Disediakan langsung di lapangan sebelum main',
                                style:
                                    TextStyle(color: AP.slate, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AP.cloud,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:  Text(
                            'Opsional',
                            style: TextStyle(
                              color: AP.slate,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                     Divider(color: AP.line, height: 1),
                    ...equipmentAddOns.map((item) {
                      final count = _selectedAddOns[item.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AP.cloud,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: APGlyph(item.icon, size: 20, color: AP.ink),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+Rp${item.price}k • ${item.description}',
                                    style:  TextStyle(
                                      color: AP.slate,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stepper counter [-] qty [+]
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: count > 0
                                      ? () {
                                          setState(() {
                                            _selectedAddOns[item.id] =
                                                count - 1;
                                          });
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: count > 0 ? AP.blue : AP.line,
                                      ),
                                      color:
                                          count > 0 ? AP.surface : AP.cloud,
                                    ),
                                    child: Icon(
                                      LucideIcons.minus,
                                      size: 16,
                                      color: count > 0 ? AP.blue : AP.slate,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: count > 0 ? AP.ink : AP.slate,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedAddOns[item.id] = count + 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration:  BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AP.blue,
                                    ),
                                    child: const Icon(
                                      LucideIcons.plus,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Rincian Pembayaran
              _card([
                _priceRow(
                    'Harga sewa (${widget.durationMinutes} mnt)', 'Rp${_baseCourtPrice}k'),
                _divider(),
                if (_addOnsTotal > 0) ...[
                  _priceRow('Perlengkapan tambahan', '+Rp${_addOnsTotal}k',
                      valueColor: AP.blue),
                  _divider(),
                ],
                if (_discountAmount > 0) ...[
                  _priceRow('Diskon voucher promo', '-Rp${_discountAmount}k',
                      valueColor: Colors.green),
                  _divider(),
                ],
                _priceRow('Biaya layanan aplikasi', 'Gratis',
                    valueColor: Colors.green),
                _divider(),
                _priceRow('Total Pembayaran', 'Rp${_finalTotal}k', bold: true),
              ]),
            ],
          );
  }

  // ---- State sukses ----
  Widget _success() {
    final c = widget.court;
    final b = _createdBooking;
    return APList(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AP.lime,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AP.lime.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:  const Icon(LucideIcons.check, color: AP.onLime, size: 48),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'BOOKING BERHASIL!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
            fontSize: 26.88,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
         Text(
          (b?.isPaid ?? false) ? 'Reservasi dikonfirmasi dan pembayaran lunas.' : 'Reservasi Anda telah dikonfirmasi oleh sistem.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AP.slate, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Receipt Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AP.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AP.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: apImg(
c.image, fallbackUrl: c.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: AP.blue,
                        child: const APRacketIcon(color: Colors.white),
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
                          style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                            fontSize: 18.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.venue,
                          style:  TextStyle(
                            fontSize: 12,
                            color: AP.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
               Divider(color: AP.line, height: 1),
              const SizedBox(height: 16),
              _receiptRow('Tanggal Main', DateFormat('EEEE, d MMM yyyy').format(widget.date)),
              const SizedBox(height: 10),
              _receiptRow('Waktu Slot', '${widget.slot} WIB (1 jam)'),
              const SizedBox(height: 10),
              _receiptRow('Metode Pembayaran', _selectedPayment),
              if (b != null) ...[
                const SizedBox(height: 10),
                _receiptRow('Kode Reservasi', b.id, isCode: true),
              ],
              const SizedBox(height: 16),
               Divider(color: AP.line, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Total Biaya',
                    style: TextStyle(
                      fontSize: 14,
                      color: AP.slate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rp${b?.finalPrice ?? _finalTotal}k',
                    style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                      fontSize: 22.4,
                      fontWeight: FontWeight.w800,
                      color: AP.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        if (b != null) ...[
          SizedBox(
            width: double.infinity,
            child: _bottomButton(
              label: 'Lihat E-Ticket & QR',
              filled: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketScreen(booking: b),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: _bottomButton(
            label: 'Lihat Booking Saya',
            filled: b == null,
            onTap: () {
              tabIndex.value = 3; // tab Bookings
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _bottomButton(
            label: 'Kembali ke Beranda',
            filled: false,
            onTap: () {
              tabIndex.value = 0;
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value, {bool isCode = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:  TextStyle(fontSize: 13, color: AP.slate),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: isCode ? 'monospace' : null,
            color: isCode ? AP.blue : AP.ink,
          ),
        ),
      ],
    );
  }

  // ---- helpers ----
  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AP.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AP.line),
        ),
        child: Column(children: children),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AP.blue),
            const SizedBox(width: 12),
            Text(label, style:  TextStyle(color: AP.slate)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _priceRow(String label, String value,
          {bool bold = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: bold ? AP.ink : AP.slate,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                    fontSize: bold ? 16 : 14)),
            Text(value,
                style: TextStyle(
                    color: valueColor ?? (bold ? AP.blue : AP.ink),
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 18 : 14)),
          ],
        ),
      );

  Widget _divider() =>  Divider(height: 1, color: AP.line);

  Widget _bottom({required String label, required VoidCallback onTap}) =>
      Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration:  BoxDecoration(
          color: AP.surface,
          border: Border(top: BorderSide(color: AP.line)),
        ),
        child: _bottomButton(label: label, filled: true, onTap: onTap),
      );

  Widget _bottomButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        height: 54,
        child: filled
            ? ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AP.lime,
                  foregroundColor: AP.onLime,
                  elevation: 0,
                  shape: const ChamferBorder(br: 10, tl: 10),
                ),
                child: Text(label,
                    style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                        fontSize: 18.4, fontWeight: FontWeight.w800)),
              )
            : OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AP.blue,
                  side:  BorderSide(color: AP.blue),
                  shape: const ChamferBorder(br: 10, tl: 10),
                ),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
      );

  static String _plusOneHour(String slot) {
    final h = int.parse(slot.split(':').first);
    return '${(h + 1).toString().padLeft(2, '0')}:00';
  }
}

class _QrisPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFF151C4E);
    final paintLight = Paint()..color = Colors.white;

    const gridSize = 21;
    final cellSize = size.width / gridSize;

    // Helper to draw a finder pattern at (gx, gy)
    void drawFinder(int gx, int gy) {
      // 7x7 dark outer
      canvas.drawRect(
        Rect.fromLTWH(gx * cellSize, gy * cellSize, 7 * cellSize, 7 * cellSize),
        paintDark,
      );
      // 5x5 light inner
      canvas.drawRect(
        Rect.fromLTWH((gx + 1) * cellSize, (gy + 1) * cellSize, 5 * cellSize, 5 * cellSize),
        paintLight,
      );
      // 3x3 dark center
      canvas.drawRect(
        Rect.fromLTWH((gx + 2) * cellSize, (gy + 2) * cellSize, 3 * cellSize, 3 * cellSize),
        paintDark,
      );
    }

    drawFinder(0, 0); // Top left
    drawFinder(gridSize - 7, 0); // Top right
    drawFinder(0, gridSize - 7); // Bottom left

    // Deterministic pseudo pattern for remaining cells
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        // Skip finder areas
        if ((x < 8 && y < 8) ||
            (x >= gridSize - 8 && y < 8) ||
            (x < 8 && y >= gridSize - 8)) {
          continue;
        }
        // Skip center logo area (around cell 8..12)
        if (x >= 8 && x <= 12 && y >= 8 && y <= 12) {
          continue;
        }
        // Pseudo pattern
        if (((x * 17 + y * 31 + (x ^ y)) % 7) < 3) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x * cellSize + 0.5, y * cellSize + 0.5,
                  cellSize - 1, cellSize - 1),
              const Radius.circular(1.5),
            ),
            paintDark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
