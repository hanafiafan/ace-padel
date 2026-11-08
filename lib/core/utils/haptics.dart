import 'package:flutter/services.dart';

class APHaptics {
  /// Diatur dari Pengaturan > "Getar saat menyentuh" (disimpan di perangkat).
  static bool enabled = true;

  /// Subtle click for buttons, tabs, chips
  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Medium click for selections, toggles
  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Heavy click for confirmations, bookings
  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Success pattern
  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
