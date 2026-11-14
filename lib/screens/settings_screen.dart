import '../core/widgets/ap_shape.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/ap_decor.dart';
import '../core/widgets/responsive_container.dart';
import '../core/utils/ui.dart';
import '../services/api_service.dart';
import '../store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefs = {
    'notif_reminder': ('Pengingat Jadwal Sesi', 'Notifikasi 2 jam sebelum waktu booking dimulai', true),
    'notif_match': ('Open Mabar & Turnamen', 'Pemberitahuan bila ada slot mabar baru di sekitar Anda', true),
    'notif_weather': ('Peringatan Cuaca & Venue', 'Update kondisi outdoor court dan status angin/hujan', false),
    'notif_promo': ('Promo Member & Flash Sale', 'Penawaran diskon sewa dan voucher raket turnamen', true),
    'haptics': ('Haptic Engine Atletik', 'Umpan balik getar taktis pada sentuhan tombol & stepper', true),
    'sound_fx': ('Audio Whistle & Padel FX', 'Efek suara pukulan padel dan peluit saat aksi selesai', false),
    'health_sync': ('Sinkronisasi Apple / Health Connect', 'Kirim data kalori & durasi match ke Apple Health / Fit', true),
    'public_dupr': ('Tampilkan Peringkat di Publik', 'Izinkan pemain lain melihat rating DUPR & statistik Anda', true),
  };

  final Map<String, bool> _values = {for (final e in _prefs.entries) e.key: e.value.$3};
  String _cacheSize = '0.0 MB';
  String _apiStatus = 'MENGECEK…';
  bool _apiOnline = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshCacheSize();
    _pingApi();
  }

  void _refreshCacheSize() {
    final mb = PaintingBinding.instance.imageCache.currentSizeBytes / (1024 * 1024);
    _cacheSize = '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _pingApi() async {
    final t = Stopwatch()..start();
    try {
      await ApiService.instance.get('/health', auth: false);
      if (!mounted) return;
      setState(() {
        _apiOnline = true;
        _apiStatus = 'ONLINE • ${t.elapsedMilliseconds}ms';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiOnline = false;
        _apiStatus = 'OFFLINE';
      });
    }
  }

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        for (final k in _prefs.keys) {
          _values[k] = sp.getBool(k) ?? _values[k]!;
        }
        APHaptics.enabled = _values['haptics']!;
      });
    } catch (_) {}
  }

  Future<void> _set(String k, bool v) async {
    APHaptics.light();
    setState(() => _values[k] = v);
    if (k == 'haptics') APHaptics.enabled = v;
    try {
      await (await SharedPreferences.getInstance()).setBool(k, v);
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    APHaptics.medium();
    setState(() => _isClearingCache = true);
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    if (!mounted) return;
    setState(() {
      _refreshCacheSize();
      _isClearingCache = false;
    });
    showInfo(context, 'Cache aset dan data visual berhasil dibersihkan.');
  }

  Future<void> _exportData() async {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'stats': StatsStore.instance.stats,
      'bookings': [
        for (final b in BookingStore.instance.bookings)
          {'id': b.id, 'court': b.court.name, 'date': b.date.toIso8601String(), 'slot': b.slot, 'status': b.status},
      ],
    };
    await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)));
    APHaptics.success();
    if (mounted) showInfo(context, 'Data profil & riwayat booking (JSON) disalin ke clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final mode = ThemeController.instance.mode;
    return ResponsiveContainer(
      child: SportyCourtBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AP.ink,
            title: Text(
              'PENGATURAN SISTEM',
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AP.ink,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              // 1. Tampilan & Mode Gelap
              _sectionHeader('TAMPILAN & TEMA ARENA', LucideIcons.palette),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: _cardDeco(),
                child: Row(
                  children: [
                    for (final m in ThemeMode.values)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            APHaptics.light();
                            ThemeController.instance.set(m);
                            setState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: ShapeDecoration(
                              color: mode == m ? APColors.lime : Colors.transparent,
                              shape: const ChamferBorder(br: 10, tl: 4),
                              shadows: mode == m ? [BoxShadow(color: APColors.lime.withValues(alpha: 0.3), blurRadius: 6)] : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  switch (m) {
                                    ThemeMode.system => LucideIcons.smartphone,
                                    ThemeMode.light => LucideIcons.sun,
                                    ThemeMode.dark => LucideIcons.moon,
                                  },
                                  size: 20,
                                  color: mode == m ? APColors.onLime : AP.slate,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ThemeController.label(m).toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: mode == m ? APColors.onLime : AP.slate,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Notifikasi & Telemetri Real-time
              _sectionHeader('NOTIFIKASI & TELEMETRI', LucideIcons.bell),
              Container(
                decoration: _cardDeco(),
                child: Column(
                  children: [
                    _switchItem('notif_reminder'),
                    Divider(height: 1, color: AP.line),
                    _switchItem('notif_match'),
                    Divider(height: 1, color: AP.line),
                    _switchItem('notif_weather'),
                    Divider(height: 1, color: AP.line),
                    _switchItem('notif_promo'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Hardware & Umpan Balik Taktis
              _sectionHeader('HARDWARE & HAPTIC ENGINE', LucideIcons.vibrate),
              Container(
                decoration: _cardDeco(),
                child: Column(
                  children: [
                    _switchItem('haptics'),
                    Divider(height: 1, color: AP.line),
                    _switchItem('sound_fx'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Integrasi Olahraga & Privasi
              _sectionHeader('DATA OLAHRAGA & PRIVASI', LucideIcons.shieldCheck),
              Container(
                decoration: _cardDeco(),
                child: Column(
                  children: [
                    _switchItem('health_sync'),
                    Divider(height: 1, color: AP.line),
                    _switchItem('public_dupr'),
                    Divider(height: 1, color: AP.line),
                    // Clear Cache Action
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: ShapeDecoration(
                          color: APColors.blue.withValues(alpha: 0.1),
                          shape: const ChamferBorder(br: 6, tl: 3),
                        ),
                        child: Icon(LucideIcons.trash2, color: APColors.blue, size: 17),
                      ),
                      title: const Text(
                        'Bersihkan Cache Aset',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        'Ukuran penyimpanan cache: $_cacheSize',
                        style: TextStyle(color: AP.slate, fontSize: 11),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isClearingCache ? null : _clearCache,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AP.cloud,
                          foregroundColor: AP.ink,
                          elevation: 0,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: const ChamferBorder(br: 6, tl: 3),
                        ),
                        child: _isClearingCache
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Bersihkan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    Divider(height: 1, color: AP.line),
                    // Export Data Action
                    ListTile(
                      onTap: _exportData,
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: ShapeDecoration(
                          color: APColors.blue.withValues(alpha: 0.1),
                          shape: const ChamferBorder(br: 6, tl: 3),
                        ),
                        child: Icon(LucideIcons.fileSpreadsheet, color: APColors.blue, size: 17),
                      ),
                      title: const Text(
                        'Ekspor Data & Riwayat Pertandingan',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        'Salin data profil & statistik (JSON) ke clipboard',
                        style: TextStyle(color: AP.slate, fontSize: 11),
                      ),
                      trailing: Icon(LucideIcons.download, size: 16, color: AP.slate),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Tentang Sistem & Telemetri
              _sectionHeader('INFORMASI SISTEM', LucideIcons.cpu),
              Container(
                decoration: _cardDeco(),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: ShapeDecoration(
                          color: APColors.blue.withValues(alpha: 0.1),
                          shape: const ChamferBorder(br: 6, tl: 3),
                        ),
                        child: Icon(LucideIcons.info, color: APColors.blue, size: 17),
                      ),
                      title: const Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: const ShapeDecoration(
                          color: APColors.lime,
                          shape: ChamferBorder(br: 4, tl: 2),
                        ),
                        child: const Text(
                          'v1.0.0 (build 1)',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            color: APColors.onLime,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: AP.line),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: ShapeDecoration(
                          color: APColors.blue.withValues(alpha: 0.1),
                          shape: const ChamferBorder(br: 6, tl: 3),
                        ),
                        child: Icon(LucideIcons.server, color: APColors.blue, size: 17),
                      ),
                      title: const Text('Status API Gateway', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _apiOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _apiStatus,
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: _apiOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AP.line),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: ShapeDecoration(
                          color: APColors.blue.withValues(alpha: 0.1),
                          shape: const ChamferBorder(br: 6, tl: 3),
                        ),
                        child: Icon(LucideIcons.code, color: APColors.blue, size: 17),
                      ),
                      title: const Text('Pengembang & Arsitektur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      trailing: Text('hellens.dev • Afan', style: TextStyle(color: AP.slate, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchItem(String key) {
    final entry = _prefs[key]!;
    return SwitchListTile.adaptive(
      value: _values[key]!,
      onChanged: (v) => _set(key, v),
      title: Text(entry.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      subtitle: Text(entry.$2, style: TextStyle(color: AP.slate, fontSize: 11)),
      activeThumbColor: APColors.onLime,
      activeTrackColor: APColors.lime,
    );
  }

  ShapeDecoration _cardDeco() => ShapeDecoration(
        color: AP.surface,
        shape: const ChamferBorder(br: 18, tl: 8),
        shadows: APShadows.card,
      );

  Widget _sectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: const ShapeDecoration(
                color: APColors.lime,
                shape: ChamferBorder(br: 2, tl: 2),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 15, color: APColors.blue),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AP.ink,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
}
