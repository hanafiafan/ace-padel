import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/responsive_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefs = {
    'notif_reminder': ('Pengingat jadwal main', 'Ingatkan 2 jam sebelum sesi dimulai', true),
    'notif_promo': ('Promo & voucher', 'Info diskon dan kode promo terbaru', true),
    'notif_match': ('Mabar & komunitas', 'Ajakan main dan update match terbuka', false),
    'haptics': ('Getar saat menyentuh', 'Umpan balik haptic pada tombol', true),
  };
  final Map<String, bool> _values = {for (final e in _prefs.entries) e.key: e.value.$3};

  @override
  void initState() {
    super.initState();
    _load();
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
    setState(() => _values[k] = v);
    if (k == 'haptics') APHaptics.enabled = v;
    try {
      await (await SharedPreferences.getInstance()).setBool(k, v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mode = ThemeController.instance.mode;
    return ResponsiveContainer(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _section('Tampilan'),
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
                          decoration: BoxDecoration(
                            color: mode == m ? AP.lime : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
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
                                color: mode == m ? AP.onLime : AP.slate,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ThemeController.label(m),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: mode == m ? AP.onLime : AP.slate,
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
            _section('Notifikasi & umpan balik'),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: [
                  for (final e in _prefs.entries) ...[
                    SwitchListTile.adaptive(
                      value: _values[e.key]!,
                      onChanged: (v) => _set(e.key, v),
                      title: Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(e.value.$2, style: TextStyle(color: AP.slate, fontSize: 12)),
                      activeThumbColor: AP.onLime,
                      activeTrackColor: AP.lime,
                    ),
                    if (e.key != _prefs.keys.last) Divider(height: 1, color: AP.line),
                  ],
                ],
              ),
            ),
            _section('Tentang'),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(LucideIcons.info, color: AP.blue),
                    title: const Text('Versi aplikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    trailing: Text('1.0.0', style: TextStyle(color: AP.slate)),
                  ),
                  Divider(height: 1, color: AP.line),
                  ListTile(
                    leading: Icon(LucideIcons.code, color: AP.blue),
                    title: const Text('Dibuat oleh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    trailing: Text('hellens.dev', style: TextStyle(color: AP.slate)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AP.line),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(t, style: const TextStyle(fontFamily: 'Display', fontSize: 20, fontWeight: FontWeight.w800)),
      );
}
