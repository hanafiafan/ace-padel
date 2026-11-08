import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ace_padel/main.dart';
import 'package:ace_padel/widgets.dart';
import 'package:ace_padel/screens/coaches_screen.dart';

void main() {
  testWidgets('App renders successfully with RootNav and 5 tabs',
      (WidgetTester tester) async {
    // Set surface size to realistic modern mobile viewport
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AcePadelApp());
    await tester.pumpAndSettle();

    // Verify LoginScreen renders on fresh start
    expect(find.text('Selamat Datang di Ace Padel'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Lanjutkan sebagai Tamu (Guest)'), findsOneWidget);

    // Tap Lanjutkan sebagai Tamu to enter the main app
    await tester.tap(find.text('Lanjutkan sebagai Tamu (Guest)'));
    await tester.pumpAndSettle();

    // Verify Brand Logo lockup and greeting
    expect(find.byType(AceLogo), findsOneWidget);
    expect(find.textContaining('Ayo main padel'), findsOneWidget);

    // Verify Navigation Destination labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Courts'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Switch to Courts tab
    await tester.tap(find.text('Courts'));
    await tester.pumpAndSettle();
    expect(find.text('Cari Lapangan'), findsOneWidget);

    // Switch to Ranking tab
    await tester.tap(find.text('Ranking'));
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.textContaining('Global'), findsWidgets);
    expect(find.textContaining('Teman'), findsWidgets);
    expect(find.text('Tambah Teman'), findsOneWidget);

    // Switch scope to Teman
    await tester.tap(find.textContaining('Teman ('));
    await tester.pumpAndSettle();

    // Open Tambah Teman modal
    await tester.tap(find.text('Tambah Teman'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Teman Pemain'), findsOneWidget);
    expect(find.text('Daftar Pemain:'), findsOneWidget);

    // Close modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Switch to Bookings tab
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Booking Saya'), findsOneWidget);
    expect(find.text('Mendatang'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Venue favorit'), findsOneWidget);
    expect(find.text('Metode pembayaran'), findsOneWidget);

    // Open Portal Mitra Lapangan
    expect(find.text('Portal Mitra Lapangan'), findsOneWidget);
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    // Verify Venue Dashboard
    expect(find.text('Portal Pengelola'), findsOneWidget);
    expect(find.text('Validasi QR'), findsOneWidget);
    expect(find.text('Jadwal Slot'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
    expect(find.text('Pemindai Tiket Masuk'), findsOneWidget);

    // Switch to Jadwal Slot tab in Venue Dashboard
    await tester.tap(find.text('Jadwal Slot'));
    await tester.pumpAndSettle();
    expect(find.text('Tersedia'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);

    // Return to Player Mode
    await tester.tap(find.text('Mode Pemain'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);
  });

  testWidgets('CoachesScreen renders coach roster and opens booking sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CoachesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pelatih & Coaching Padel'), findsOneWidget);
    expect(find.text('Edu Altimires Ros'), findsOneWidget);
    expect(find.text('Adrià Mercadal'), findsOneWidget);
    expect(find.text('Adi Sila Pratama'), findsOneWidget);

    // Tap Book Sesi for first coach
    await tester.tap(find.text('Book Sesi').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Private Coaching: Edu Altimires Ros'),
        findsOneWidget);
    expect(find.text('Konfirmasi Jadwal Coaching'), findsOneWidget);

    // Confirm booking session
    await tester.tap(find.text('Konfirmasi Jadwal Coaching'));
    await tester.pumpAndSettle();

    expect(find.textContaining('berhasil dijadwalkan'), findsOneWidget);
  });
}
