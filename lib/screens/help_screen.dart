import 'package:flutter/material.dart';
import '../core/utils/launch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'Bagaimana cara membatalkan reservasi?',
      'a': 'Buka tab "Bookings", cari kartu reservasi yang ingin dibatalkan, lalu ketuk tombol silang atau menu batalkan. Konfirmasi pada dialog pembatalan dan slot akan otomatis terlepas.',
    },
    {
      'q': 'Apakah raket dan bola sudah disediakan di venue?',
      'a': 'Sebagian besar venue rekanan Ace Padel menyediakan sewa raket dan bola di lokasi. Anda juga bisa membawa raket pribadi. Cek badge fasilitas pada detail lapangan.',
    },
    {
      'q': 'Kapan saya harus tiba di lapangan?',
      'a': 'Kami menyarankan Anda tiba 10–15 menit sebelum slot jam bermain dimulai untuk proses check-in, persiapan pakaian, dan pemanasan.',
    },
    {
      'q': 'Bagaimana cara menaikkan peringkat di Leaderboard?',
      'a': 'Setiap kali menyelesaikan match dan bermain di venue mitra Ace Padel, Anda akan memperoleh poin match. Menang melawan pemain berperingkat tinggi memberikan bonus poin tambahan.',
    },
    {
      'q': 'Apakah metode pembayaran aman?',
      'a': 'Sangat aman. Anda dapat memilih bayar langsung di lokasi saat check-in, atau melakukan pembayaran instan melalui QRIS dan Virtual Account perbankan terpercaya.',
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
          'Pusat Bantuan & FAQ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: APList(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Contact banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient:  LinearGradient(
                colors: [AP.blueDark, AP.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Butuh Bantuan Langsung?',
                  style: TextStyle(fontFamily: 'Display', 
                    color: Colors.white,
                    fontSize: 20.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tim customer care Ace Padel siap membantu setiap hari pukul 08:00 – 22:00 WIB.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => APLaunch.whatsapp(context),
                      icon: const Icon(LucideIcons.messageCircle, size: 16),
                      label: const Text('Chat WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AP.lime,
                        foregroundColor: AP.onLime,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => APLaunch.email(context),
                      icon: const Icon(LucideIcons.mail, size: 16, color: Colors.white),
                      label: const Text(
                        'Kirim Email',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Pertanyaan Sering Diajukan (FAQ)',
            style: TextStyle(fontFamily: 'Display', fontSize: 20.7, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          ..._faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AP.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AP.line),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      f['q']!,
                      style:  TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AP.ink,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(
                        f['a']!,
                        style:  TextStyle(
                          color: AP.slate,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 24),

          // Company credit
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AP.lime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ace Padel by hellens.dev',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AP.ink,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                 Text(
                  'Versi 1.0.0 • https://hellens.dev',
                  style: TextStyle(
                    fontSize: 12,
                    color: AP.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

