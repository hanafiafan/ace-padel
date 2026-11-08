// Opt-in integration test against a running backend:
//   cd server && PORT=3023 node src/index.js
//   LIVE_API=http://localhost:3023 flutter test test/live_api_test.dart
import 'dart:io';
import 'package:ace_padel/data.dart';
import 'package:ace_padel/services/api_service.dart';
import 'package:ace_padel/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final base = Platform.environment['LIVE_API'];
  test('live: register -> courts -> slots -> book -> 409 -> pay -> cancel -> notifications',
      skip: base == null ? 'set LIVE_API to run' : false, () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiService.instance..client = http.Client();
    // baseUrl comes from --dart-define=API_URL in the app; here we hit the server directly via a rewriting client.
    api.client = _Rebase(base!);
    final user = UserStore.instance;
    final email = 'it${DateTime.now().millisecondsSinceEpoch}@acepadel.id';

    await user.register(name: 'Integration Tester', email: email, password: 'secret123');
    expect(user.isLoggedIn, true);
    expect(user.profile.role, 'player');

    await CatalogStore.instance.refreshCourts();
    expect(CatalogStore.instance.isOffline, false);
    expect(courts.length, greaterThan(3));
    final court = courts.first;

    final day = DateTime.now().add(const Duration(days: 3));
    final store = BookingStore.instance;
    await store.loadSlots(court, day);
    expect(store.isTaken(court, day, '19:00'), false);

    final b = await store.book(court, day, '19:00',
        paymentMethod: 'BCA Virtual Account', addOnIds: ['racket', 'racket']);
    expect(b.paymentStatus, 'Menunggu');
    expect(b.paymentRef, isNotEmpty);
    expect(b.addOnsTotal, 60); // server-side pricing: 2 x 30
    expect(b.finalPrice, court.pricePerHour + 60);

    await expectLater(store.book(court, day, '19:00'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)));
    expect(store.isTaken(court, day, '19:00'), true);

    final paid = await store.pay(b);
    expect(paid.paymentStatus, 'Lunas');

    await store.cancel(paid);
    await store.loadSlots(court, day);
    expect(store.isTaken(court, day, '19:00'), false);
    expect(store.history.first.status, 'Dibatalkan');

    await NotificationStore.instance.refresh();
    expect(NotificationStore.instance.items.length, greaterThanOrEqualTo(3));
    await NotificationStore.instance.markAllRead();
    expect(NotificationStore.instance.unread, 0);

    await FavoriteStore.instance.toggle(court.id);
    expect(FavoriteStore.instance.isFavorite(court.id), true);
    await StatsStore.instance.refresh();
    expect(StatsStore.instance.achievementList.length, 8);
    await FriendStore.instance.refresh();
    expect(FriendStore.instance.globalBoard, isNotEmpty);
    await PaymentPrefStore.instance.save('QRIS Instant');
    await PaymentPrefStore.instance.refresh();
    expect(PaymentPrefStore.instance.method, 'QRIS Instant');

    // Owner endpoints with the dev owner account.
    await user.logout();
    await user.login('owner@acepadel.id', 'owner12345');
    expect(user.isVenueOwner, true);
    final o = OwnerStore.instance;
    await o.init();
    expect(o.ownCourts, isNotEmpty);
    expect(o.schedule.length, 14);
    await o.toggleSlot('08:00', block: true);
    expect(o.schedule['08:00']?.isMaintenance, true);
    await o.toggleSlot('08:00', block: false);
    expect(o.schedule['08:00'], isNull);
    final r = await o.verify('NOPE');
    expect(r.valid, false);
    await user.logout();
  });
}

/// Sends every request to [base] regardless of the app's configured API_URL.
class _Rebase extends http.BaseClient {
  final Uri base;
  final http.Client _inner = http.Client();
  _Rebase(String b) : base = Uri.parse(b);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final u = request.url.replace(scheme: base.scheme, host: base.host, port: base.port);
    final r = http.Request(request.method, u)
      ..headers.addAll(request.headers)
      ..bodyBytes = (request as http.Request).bodyBytes;
    return _inner.send(r);
  }
}
