import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Pengingat Jadwal Main',
      'body':
          'Jadwal bermain Anda di Center Court Senayan akan dimulai dalam 2 jam. Jangan lupa membawa sepatu padel!',
      'time': '30 menit lalu',
      'icon': LucideIcons.clock,
      'color': AP.blue,
      'unread': true,
    },
    {
      'title': 'Poin Leaderboard Bertambah!',
      'body':
          'Kemenangan match terakhir menambahkan +120 poin. Peringkat Anda kini berada di Top 4!',
      'time': '3 jam lalu',
      'icon': LucideIcons.trophy,
      'color': const Color(0xFFF5B301),
      'unread': true,
    },
    {
      'title': 'Promo Weekend Smash',
      'body':
          'Gunakan kode ACEWEEKEND untuk potongan Rp25.000 pada seluruh lapangan outdoor akhir pekan ini.',
      'time': 'Kemarin',
      'icon': LucideIcons.tag,
      'color': AP.lime,
      'unread': false,
    },
    {
      'title': 'Badge Baru Terbuka!',
      'body':
          'Selamat, Anda telah membuka badge "Rajin Main" setelah menyelesaikan 10 sesi booking.',
      'time': '2 hari lalu',
      'icon': LucideIcons.medal,
      'color': AP.slate,
      'unread': false,
    },
  ];

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item['unread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua notifikasi ditandai telah dibaca.')),
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
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child:  Text(
              'Tandai dibaca',
              style: TextStyle(color: AP.blue, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final n = _items[i];
          final unread = n['unread'] as bool;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AP.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unread ? AP.blue.withValues(alpha: 0.4) : AP.line,
                width: unread ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (n['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    n['icon'] as IconData,
                    color: n['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n['title'] as String,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: AP.ink,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration:  BoxDecoration(
                                color: AP.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n['body'] as String,
                        style:  TextStyle(
                          color: AP.slate,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n['time'] as String,
                        style: TextStyle(
                          color: AP.slate.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
