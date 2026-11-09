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
  static Color get blue => _p(const Color(0xFF2334DB), const Color(0xFF4C5CFF));
  static const blueDark = Color(0xFF0A0F36); // header/gradient gelap (konstan)
  static const blueLight = Color(0xFF4D6BFF);
  static Color get blueSurface => _p(const Color(0xFFE9EDFF), const Color(0xFF1B2552));

  static const lime = Color(0xFFC7F23C);
  static const limeDark = Color(0xFF9CC41A);
  static Color get limeLight => _p(const Color(0xFFF3FCD0), const Color(0xFF263308));
  /// Teks/ikon di atas permukaan lime: selalu gelap.
  static const onLime = Color(0xFF1A2300);

  // Neutrals & surfaces
  static Color get ink => _p(const Color(0xFF12152B), const Color(0xFFEEF0FA));
  static Color get inkSecondary => _p(const Color(0xFF384061), const Color(0xFFC4CBE6));
  static Color get slate => _p(const Color(0xFF5A6180), const Color(0xFF98A0C4));
  static Color get cloud => _p(const Color(0xFFF2F4FB), const Color(0xFF070A16));
  static Color get surface => _p(Colors.white, const Color(0xFF0E1226));
  static Color get line => _p(const Color(0xFFE7EAF3), const Color(0xFF1E2548));
  static Color get lineDark => _p(const Color(0xFFD4D9EA), const Color(0xFF333E68));

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

