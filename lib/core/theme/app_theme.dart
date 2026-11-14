import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mode tema global; di-set oleh MaterialApp.builder tiap build.
class APTheme {
  static bool isDark = false;
}

/// Ace Padel design system palette and styling tokens.
/// Warna brand tetap; warna permukaan/teks mengikuti [APTheme.isDark].
class APColors {
  static Color _p(Color light, Color dark) => APTheme.isDark ? dark : light;

  // Brand
  static Color get blue => _p(const Color(0xFF1632E6), const Color(0xFF4C5CFF));
  static const blueDark = Color(0xFF070B24); // header/gradient gelap (konstan)
  static const blueLight = Color(0xFF3B56FF);
  static Color get blueSurface => _p(const Color(0xFFEEF2FF), const Color(0xFF141C42));

  static const lime = Color(0xFFD4FF00); // Championship neon volt
  static const limeDark = Color(0xFFA6CC00);
  static Color get limeLight => _p(const Color(0xFFF7FFE0), const Color(0xFF1E2805));
  /// Teks/ikon di atas permukaan lime: selalu gelap pekat untuk kontras maksimal.
  static const onLime = Color(0xFF070B24);

  // Neutrals & surfaces
  static Color get ink => _p(const Color(0xFF070B1F), const Color(0xFFF1F3FB));
  static Color get inkSecondary => _p(const Color(0xFF1E2642), const Color(0xFFB8C0DE));
  static Color get slate => _p(const Color(0xFF556080), const Color(0xFF8F9BBF));
  static Color get cloud => _p(const Color(0xFFE9EEF8), const Color(0xFF050816));
  static Color get surface => _p(Colors.white, const Color(0xFF0D122B));
  static Color get line => _p(const Color(0xFFD8E0F0), const Color(0xFF1B2245));
  static Color get lineDark => _p(const Color(0xFFC4D0E8), const Color(0xFF2D3768));

  // Status
  static const success = Color(0xFF12A150);
  static Color get successLight => _p(const Color(0xFFD1FAE5), const Color(0xFF0C3326));
  static const warning = Color(0xFFD98A00);
  static Color get warningLight => _p(const Color(0xFFFEF3C7), const Color(0xFF3A2C09));
  static const danger = Color(0xFFD92D4A);
  static Color get dangerLight => _p(const Color(0xFFFEE2E2), const Color(0xFF3B1417));
  static const info = Color(0xFF3B82F6);
}

/// Backwards compatibility alias for existing code
typedef AP = APColors;

class APShadows {
  static const subtle = [
    BoxShadow(
      color: Color(0x080F143A),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const card = [
    BoxShadow(
      color: Color(0x0A0F143A),
      blurRadius: 18,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F143A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x120F143A),
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
  ];

  static const primaryButton = [
    BoxShadow(
      color: Color(0x401F3BFF),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const limeButton = [
    BoxShadow(
      color: Color(0x55B8FF1F),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

ThemeData buildAceTheme([Brightness brightness = Brightness.light]) {
  APTheme.isDark = brightness == Brightness.dark;
  final base = ThemeData(useMaterial3: true, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: APColors.cloud,
    colorScheme: base.colorScheme.copyWith(
      primary: APColors.blue,
      secondary: APColors.lime,
      surface: APColors.surface,
      onPrimary: Colors.white,
      onSecondary: APColors.ink,
      onSurface: APColors.ink,
    ),
    cardColor: APColors.surface,
    canvasColor: APColors.surface,
    dialogTheme: DialogThemeData(backgroundColor: APColors.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: APColors.surface, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: InputDecorationTheme(hintStyle: TextStyle(color: APColors.slate)),
    dividerColor: APColors.line,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: APColors.ink,
      displayColor: APColors.ink,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme:  AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: APColors.ink),
      titleTextStyle: TextStyle(
        color: APColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: APColors.blueDark,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

