import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../core/utils/ui.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String get _selectedMethod => PaymentPrefStore.instance.method;

  @override
  void initState() {
    super.initState();
    PaymentPrefStore.instance.addListener(_rebuild);
    PaymentPrefStore.instance.refresh(); // GET /payment-method
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PaymentPrefStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'Bayar di tempat',
      'title': 'Bayar di Venue',
      'subtitle': 'Bayar tunai atau kartu debit/kredit di resepsionis venue',
      'icon': LucideIcons.banknote,
      'badge': 'Gratis Admin',
    },
    {
      'id': 'QRIS Instant',
      'title': 'QRIS Instant Pay',
      'subtitle': 'BCA, GoPay, OVO, ShopeePay, Dana, LinkAja',
      'icon': LucideIcons.qrCode,
      'badge': 'Otomatis',
    },
    {
      'id': 'BCA Virtual Account',
      'title': 'BCA Virtual Account',
      'subtitle': 'Transfer cepat melalui m-BCA, KlikBCA, atau ATM BCA',
      'icon': LucideIcons.landmark,
      'badge': '24 Jam',
    },
    {
      'id': 'Mandiri Virtual Account',
      'title': 'Mandiri Virtual Account',
      'subtitle': 'Transfer mudah via Livin by Mandiri atau ATM',
      'icon': LucideIcons.wallet,
      'badge': '24 Jam',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: APList(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Preferred payment banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient:  LinearGradient(
                colors: [AP.blueDark, AP.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: AP.lime,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PEMBAYARAN AMAN & TRANSPARAN',
                        style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                          color: Colors.white,
                          fontSize: 18.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tidak ada biaya tersembunyi. Konfirmasi otomatis dan instan.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'METODE PEMBAYARAN TERSEDIA',
            style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          ..._methods.map((m) {
            final isSelected = _selectedMethod == m['id'];
            return GestureDetector(
              onTap: () async {
                if (!requireLogin(context, 'menyimpan metode pembayaran')) return;
                try {
                  await PaymentPrefStore.instance.save(m['id'] as String); // PUT /payment-method
                  if (mounted) showInfo(context, 'Metode utama diubah ke "${m['title']}"');
                } on ApiException catch (e) {
                  if (mounted) showError(context, e);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AP.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AP.blue : AP.line,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AP.blue.withValues(alpha: 0.1)
                            : AP.cloud,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        m['icon'] as IconData,
                        color: isSelected ? AP.blue : AP.slate,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AP.lime.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m['badge'] as String,
                                  style:  TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AP.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['subtitle'] as String,
                            style:  TextStyle(
                              color: AP.slate,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? LucideIcons.circleDot
                          : LucideIcons.circle,
                      color: isSelected ? AP.blue : AP.slate,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // FAQ Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AP.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AP.line),
            ),
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                SizedBox(height: 8),
                Text(
                  '• Pembayaran "Bayar di Venue" dapat diselesaikan saat tiba di lokasi sebelum jam main dimulai.\n'
                  '• Untuk pembayaran via QRIS dan Virtual Account, reservasi akan terverifikasi otomatis dalam 1 menit.\n'
                  '• Pembatalan reservasi dapat dilakukan gratis hingga 2 jam sebelum jadwal bermain.',
                  style: TextStyle(color: AP.slate, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
