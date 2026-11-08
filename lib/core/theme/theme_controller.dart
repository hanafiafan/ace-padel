import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan tema pengguna (Sistem/Terang/Gelap), disimpan di perangkat.
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final v = (await SharedPreferences.getInstance()).getString(_key);
      _mode = ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
    } catch (_) {/* default: sistem */}
  }

  Future<void> set(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, m.name);
    } catch (_) {}
  }

  static String label(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Ikuti sistem',
        ThemeMode.light => 'Terang',
        ThemeMode.dark => 'Gelap',
      };
}

/// Warna di aplikasi dibaca lewat getter global, jadi widget yang sudah dibangun
/// tidak otomatis tahu tema berubah: tandai seluruh pohon untuk dibangun ulang
/// (state & navigasi tetap utuh).
void apRebuildAll() {
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}
