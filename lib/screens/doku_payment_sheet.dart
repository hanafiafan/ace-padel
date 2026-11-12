import '../core/widgets/ap_shape.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/utils/launch.dart';
import '../core/utils/ui.dart';
import '../data.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';

/// DOKU payment sheet: runs checkout, opens the hosted page, polls the status.
/// Resolves to the paid [Booking], or null when cancelled/expired/closed.
/// [allowClose] adds "Bayar nanti" (keeps the booking pending).
Future<Booking?> showDokuPaymentSheet(BuildContext context, Booking b, {bool allowClose = false}) {
  return showModalBottomSheet<Booking>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AP.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => DokuPaymentSheet(booking: b, allowClose: allowClose),
  );
}

enum _Phase { starting, waiting, failed, expired }

class DokuPaymentSheet extends StatefulWidget {
  final Booking booking;
  final bool allowClose;
  const DokuPaymentSheet({super.key, required this.booking, this.allowClose = false});

  @override
  State<DokuPaymentSheet> createState() => _DokuPaymentSheetState();
}

class _DokuPaymentSheetState extends State<DokuPaymentSheet> {
  static const _pollEvery = Duration(seconds: 4);

  late Booking _b = widget.booking;
  _Phase _phase = _Phase.starting;
  String _error = '';
  String? _url;
  bool _checking = false;
  bool _cancelling = false;
  Timer? _poll;
  Timer? _tick;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _stopTimers() {
    _poll?.cancel();
    _tick?.cancel();
  }

  Future<void> _start() async {
    setState(() => _phase = _Phase.starting);
    try {
      final url = _b.paymentUrl ?? await BookingStore.instance.checkout(_b);
      if (!mounted) return;
      _url = url;
      _beginWaiting();
      APLaunch.open(context, Uri.parse(url), failMessage: 'Tidak bisa membuka halaman pembayaran. Tekan tombol di bawah.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.failed;
      });
    }
  }

  void _beginWaiting() {
    _updateLeft();
    setState(() => _phase = _Phase.waiting);
    _stopTimers();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _updateLeft());
    _poll = Timer.periodic(_pollEvery, (_) => _check(silent: true));
  }

  void _updateLeft() {
    final exp = _b.paymentExpiresAt;
    final left = exp == null ? const Duration(minutes: 15) : exp.difference(DateTime.now());
    if (exp != null && left <= Duration.zero) {
      _expire();
      return;
    }
    if (mounted) setState(() => _left = left);
  }

  void _expire() {
    _stopTimers();
    if (mounted) setState(() => _phase = _Phase.expired);
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking || _phase != _Phase.waiting) return;
    _checking = true;
    if (!silent && mounted) setState(() {});
    try {
      final (nb, paid) = await BookingStore.instance.refreshPayment(_b);
      if (!mounted) return;
      _b = nb;
      if (paid || nb.isPaid) {
        _stopTimers();
        Navigator.pop(context, nb);
        return;
      }
      if (nb.isCancelled || nb.paymentStatus == 'Kedaluwarsa') {
        _expire();
        return;
      }
      if (!silent) showInfo(context, 'Pembayaran belum kami terima. Selesaikan di halaman DOKU lalu cek lagi.');
    } on ApiException catch (e) {
      if (!silent && mounted) showError(context, e);
    } finally {
      _checking = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    _stopTimers();
    try {
      await BookingStore.instance.cancel(_b);
    } on ApiException catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  String get _mmss {
    final m = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AP.line, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              if (_phase == _Phase.starting) ..._starting() else if (_phase == _Phase.waiting) ..._waiting() else ..._problem(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _starting() => [
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Menyiapkan pembayaran DOKU...', style: TextStyle(color: AP.slate)),
        const SizedBox(height: 24),
      ];

  List<Widget> _waiting() => [
        Text(_b.paymentMethod,
            style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 18.4, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Total tagihan', style: TextStyle(color: AP.slate, fontSize: 12)),
        Text('Rp${_b.finalPrice}.000',
            style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 26, fontWeight: FontWeight.w800, color: AP.ink)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AP.lime.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.timer, size: 14, color: AP.ink),
            const SizedBox(width: 6),
            Text('Selesaikan dalam $_mmss',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AP.ink)),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
          'Selesaikan pembayaran lewat QRIS / Virtual Account di halaman DOKU. '
          'Status diperiksa otomatis setiap 4 detik.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AP.slate, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 18),
        _primary('Buka halaman pembayaran DOKU', LucideIcons.externalLink,
            () => APLaunch.open(context, Uri.parse(_url!), failMessage: 'Tidak bisa membuka halaman pembayaran.')),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _checking ? null : () => _check(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AP.line),
              shape: const ChamferBorder(br: 10, tl: 10),
            ),
            child: _checking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Saya sudah bayar — cek status',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AP.ink)),
          ),
        ),
        const SizedBox(height: 4),
        if (widget.allowClose)
          TextButton(
              onPressed: _cancelling ? null : () => Navigator.pop(context),
              child: Text('Bayar nanti', style: TextStyle(color: AP.slate, fontWeight: FontWeight.w600))),
        _cancelButton(),
      ];

  List<Widget> _problem() {
    final expired = _phase == _Phase.expired;
    return [
      Icon(expired ? LucideIcons.clockAlert : LucideIcons.circleAlert, size: 40, color: AP.slate),
      const SizedBox(height: 12),
      Text(expired ? 'Waktu pembayaran habis' : 'Pembayaran belum bisa dimulai',
          style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 18.4, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(
        expired
            ? 'Booking dibatalkan otomatis dan slot dibuka kembali. Silakan pesan ulang.'
            : _error,
        textAlign: TextAlign.center,
        style: TextStyle(color: AP.slate, fontSize: 13, height: 1.4),
      ),
      const SizedBox(height: 18),
      if (expired)
        _primary('Tutup', LucideIcons.x, () {
          BookingStore.instance.refresh();
          Navigator.pop(context);
        })
      else ...[
        _primary('Coba lagi', LucideIcons.refreshCw, _start),
        const SizedBox(height: 4),
        _cancelButton(),
      ],
    ];
  }

  Widget _cancelButton() => TextButton(
        onPressed: _cancelling ? null : _cancel,
        child: Text('Batalkan booking', style: TextStyle(color: AP.slate, fontWeight: FontWeight.w600)),
      );

  Widget _primary(String label, IconData icon, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: AP.ink),
          label: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AP.ink)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AP.lime,
            elevation: 0,
            shape: const ChamferBorder(br: 10, tl: 10),
          ),
        ),
      );
}
