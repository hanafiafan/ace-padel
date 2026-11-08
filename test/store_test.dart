import 'package:flutter_test/flutter_test.dart';
import 'package:ace_padel/data.dart';
import 'package:ace_padel/store.dart';

void main() {
  final store = BookingStore.instance;
  final court = courts.first;
  final day = DateTime(2026, 10, 6);

  test('slot bisa dibooking lalu jadi taken', () {
    expect(store.isTaken(court, day, '18:00'), false);
    expect(store.book(court, day, '18:00'), true);
    expect(store.isTaken(court, day, '18:00'), true);
  });

  test('tidak boleh double-booking slot sama', () {
    expect(store.book(court, day, '18:00'), false);
  });

  test('cancel mengosongkan slot dan masuk ke history', () {
    final activeBooking =
        store.bookings.firstWhere((b) => b.slot == '18:00');
    store.cancel(activeBooking);
    expect(store.isTaken(court, day, '18:00'), false);
    expect(store.history.isNotEmpty, true);
    expect(store.history.first.status, 'Dibatalkan');
  });

  test('booking dengan metode pembayaran spesifik tersimpan dengan benar', () {
    expect(store.book(court, day, '20:00', paymentMethod: 'QRIS Instant'), true);
    final b = store.bookings.firstWhere((x) => x.slot == '20:00');
    expect(b.paymentMethod, 'QRIS Instant');
    expect(b.status, 'Terkonfirmasi');
    expect(b.id.startsWith('ACE-'), true);
    store.cancel(b);
  });

  test('booking dengan voucher menghitung harga diskon dengan akurat', () {
    final voucher = vouchers.firstWhere((v) => v.code == 'ACEWEEKEND');
    final discount = voucher.calculateDiscount(court.pricePerHour);
    expect(discount, 25);

    expect(
      store.book(
        court,
        day,
        '10:00',
        voucherCode: voucher.code,
        discount: discount,
      ),
      true,
    );

    final b = store.bookings.firstWhere((x) => x.slot == '10:00');
    expect(b.voucherCode, 'ACEWEEKEND');
    expect(b.discount, 25);
    expect(b.finalPrice, court.pricePerHour - 25);
    store.cancel(b);
  });

  test('booking dengan sewa alat dan perlengkapan menghitung total akurat', () {
    expect(
      store.book(
        court,
        day,
        '12:00',
        addOns: ['2x Sewa Raket Bullpadel Pro', '1x 1 Can Bola Baru (3 Pcs)'],
        addOnsTotal: 135,
      ),
      true,
    );
    final b = store.bookings.firstWhere((x) => x.slot == '12:00');
    expect(b.addOns.length, 2);
    expect(b.addOnsTotal, 135);
    expect(b.finalPrice, court.pricePerHour + 135);
    store.cancel(b);
  });

  test('FavoriteStore toggle dan kueri favorit berfungsi', () {
    final fav = FavoriteStore.instance;
    const testCourtId = 'c3';
    final initial = fav.isFavorite(testCourtId);
    fav.toggle(testCourtId);
    expect(fav.isFavorite(testCourtId), !initial);
    fav.toggle(testCourtId);
    expect(fav.isFavorite(testCourtId), initial);
  });

  test('UserStore update profile bekerja dengan baik', () {
    final user = UserStore.instance;
    user.updateProfile(name: 'Hanafi Afan', skillLevel: 'Mahir (Advanced / Pro)');
    expect(user.profile.name, 'Hanafi Afan');
    expect(user.profile.skillLevel, 'Mahir (Advanced / Pro)');
  });

  test('MatchStore toggle join dan leave mabar berfungsi', () {
    final matchStore = MatchStore.instance;
    final matchId = matchStore.matches.first.id;
    final initialPlayers = matchStore.matches.first.currentPlayers;
    final initialJoined = matchStore.matches.first.isJoined;

    // Join
    final joined = matchStore.toggleJoin(matchId);
    expect(joined, !initialJoined);
    expect(
      matchStore.matches.first.currentPlayers,
      initialJoined ? initialPlayers - 1 : initialPlayers + 1,
    );

    // Revert
    matchStore.toggleJoin(matchId);
    expect(matchStore.matches.first.currentPlayers, initialPlayers);
  });

  test('Venue Owner: verifikasi tiket dan check-in berfungsi', () {
    expect(store.book(court, day, '14:00', paymentMethod: 'Transfer VA'), true);
    final booking = store.bookings.firstWhere((b) => b.slot == '14:00');

    // Find by booking code
    final found = store.findBookingById(booking.id);
    expect(found != null, true);
    expect(found!.id, booking.id);
    expect(found.isCheckedIn, false);

    // Perform check-in
    final checkInOk = store.checkIn(booking.id);
    expect(checkInOk, true);

    final updated = store.findBookingById(booking.id);
    expect(updated!.status, 'Check-in Selesai');
    expect(updated.isCheckedIn, true);

    store.cancel(updated);
  });

  test('Venue Owner: blokir slot maintenance dan buka kembali berfungsi', () {
    // Blokir slot 12:00 untuk maintenance
    final blocked = store.toggleMaintenance(
      court,
      day,
      '12:00',
      block: true,
      reason: 'Pembersihan Kaca & Net',
    );
    expect(blocked, true);
    expect(store.isTaken(court, day, '12:00'), true);

    final mBooking = store.bookings.firstWhere((b) => b.slot == '12:00');
    expect(mBooking.isMaintenance, true);
    expect(mBooking.status, 'Maintenance');

    // Buka kembali slot
    final unblocked = store.toggleMaintenance(
      court,
      day,
      '12:00',
      block: false,
    );
    expect(unblocked, true);
    expect(store.isTaken(court, day, '12:00'), false);
  });

  test('Venue Owner: UserStore role switching dan stats perhitungan akurat', () {
    final user = UserStore.instance;
    user.switchRole('venue_owner');
    expect(user.isVenueOwner, true);
    expect(user.profile.role, 'venue_owner');

    user.setManagedCourt('c2');
    expect(user.profile.managedCourtId, 'c2');

    final stats = store.getVenueStats('c1');
    expect(stats.containsKey('totalBookings'), true);
    expect(stats.containsKey('checkedInCount'), true);
    expect(stats.containsKey('estimatedRevenue'), true);

    user.switchRole('player');
    expect(user.isVenueOwner, false);
  });

  test('FriendStore: tambah/hapus teman dan leaderboard teman berfungsi', () {
    final friendStore = FriendStore.instance;

    // Initial friends are p1 (Rizky) and p5 (Putri)
    expect(friendStore.isFriend('p1'), true);
    expect(friendStore.isFriend('p5'), true);
    expect(friendStore.isFriend('p2'), false);

    // Toggle friend p2 (Dewi Anggraini)
    final added = friendStore.toggleFriend('p2');
    expect(added, true);
    expect(friendStore.isFriend('p2'), true);

    // Verify friendsLeaderboard includes friends + Afan (isMe)
    final friendsLb = friendStore.friendsLeaderboard;
    expect(friendsLb.any((p) => p.isMe), true);
    expect(friendsLb.any((p) => p.id == 'p2'), true);

    // Verify sorted high to low
    for (int i = 0; i < friendsLb.length - 1; i++) {
      expect(friendsLb[i].points >= friendsLb[i + 1].points, true);
    }

    // Toggle remove p2
    final removed = friendStore.toggleFriend('p2');
    expect(removed, false);
    expect(friendStore.isFriend('p2'), false);
  });

  test('UserStore: Google login dan logout mengelola status autentikasi', () async {
    final userStore = UserStore.instance;

    await userStore.loginWithGoogleAccount(
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      photoUrl: 'https://lh3.googleusercontent.com/avatar',
      googleId: 'g_99887766',
    );

    expect(userStore.isLoggedIn, true);
    expect(userStore.profile.name, 'Budi Santoso');
    expect(userStore.profile.email, 'budi.santoso@gmail.com');
    expect(userStore.profile.authProvider, 'google');
    expect(userStore.profile.photoUrl, 'https://lh3.googleusercontent.com/avatar');

    userStore.logout();
    expect(userStore.isLoggedIn, false);

    userStore.loginAsGuest();
    expect(userStore.isLoggedIn, true);
    expect(userStore.profile.authProvider, 'guest');
  });
}
