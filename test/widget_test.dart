import 'dart:convert';
import 'package:ace_padel/main.dart';
import 'package:ace_padel/screens/coaches_screen.dart';
import 'package:ace_padel/services/api_service.dart';
import 'package:ace_padel/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Server unreachable: the app must still render with the offline fallback catalog.
    ApiService.instance.client = MockClient((_) async => http.Response(jsonEncode({'success': false}), 503));
  });

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Login screen -> mode tamu -> navigasi 5 tab', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const AcePadelApp());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);

    // Register form toggles
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Buat Akun Baru'), findsOneWidget);

    await tester.tap(find.text('Lihat-lihat dulu sebagai Tamu'));
    await tester.pumpAndSettle();

    for (final tab in ['Home', 'Courts', 'Ranking', 'Bookings', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }
    await tester.tap(find.text('Courts'));
    await tester.pumpAndSettle();
    expect(find.text('Cari Lapangan'), findsOneWidget);

    // Guests must log in to see bookings
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk untuk melihat booking'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Masuk / Daftar'), findsOneWidget);
    // Owner portal is only offered to server-confirmed owners
    expect(find.text('Portal Mitra'), findsNothing);
    UserStore.instance.isGuest = false;
  });

  testWidgets('CoachesScreen menampilkan pelatih (fallback offline)', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: CoachesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Pelatih & Coaching Padel'), findsOneWidget);
    expect(find.text('Edu Altimires Ros'), findsOneWidget);
  });
}
