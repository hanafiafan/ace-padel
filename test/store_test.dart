import 'dart:convert';
import 'package:ace_padel/data.dart';
import 'package:ace_padel/services/api_service.dart';
import 'package:ace_padel/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _court = {
  'id': 'c1', 'name': 'Court A', 'venue': 'Venue A', 'area': 'Kemang, Jakarta',
  'pricePerHour': 220, 'indoor': true, 'rating': 4.8, 'image': 'assets/images/court1.jpg',
  'imageUrl': '/img/court1.jpg', 'facilities': ['WiFi'], 'description': 'x',
};

Map<String, dynamic> _booking({String status = 'Terkonfirmasi', String pay = 'Menunggu'}) => {
      'id': 'ACE-C1-1800-1234', 'courtId': 'c1', 'date': '2030-01-02', 'slot': '18:00',
      'paymentMethod': 'QRIS Instant', 'paymentStatus': pay, 'paymentRef': 'QRIS-ACE-C1-1800-1234',
      'finalPrice': 250, 'discount': 0, 'addOns': ['Sewa Raket Bullpadel Pro'], 'addOnsTotal': 30,
      'status': status, 'court': _court,
    };

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

/// Tiny fake backend. [log] records "METHOD path" and the auth header.
MockClient _server(List<String> log, {String role = 'player', bool conflict = false}) {
  return MockClient((req) async {
    final path = req.url.path.replaceFirst('/api', '');
    log.add('${req.method} $path auth=${req.headers['Authorization']}');
    switch ('${req.method} $path') {
      case 'POST /auth/login':
        final b = jsonDecode(req.body) as Map;
        if (b['password'] != 'secret123') return _json({'success': false, 'message': 'Email atau password salah'}, 401);
        return _json({
          'success': true, 'token': 'tok-1',
          'data': {'id': 'u1', 'name': 'Budi', 'email': b['email'], 'role': role, 'authProvider': 'email'},
        });
      case 'POST /bookings':
        if (conflict) return _json({'success': false, 'message': 'Slot jam tersebut sudah dipesan pemain lain.'}, 409);
        return _json({'success': true, 'data': _booking()}, 201);
      case 'POST /bookings/ACE-C1-1800-1234/pay':
        return _json({'success': true, 'data': _booking(pay: 'Lunas')});
      case 'DELETE /bookings/ACE-C1-1800-1234':
        return _json({'success': true, 'data': _booking(status: 'Dibatalkan')});
      case 'GET /courts/c1/slots':
        return _json({'success': true, 'data': [
          {'slot': '17:00', 'available': true}, {'slot': '18:00', 'available': false},
        ]});
      case 'GET /bookings':
        return _json({'success': true, 'data': {'active': [], 'history': []}});
      case 'GET /me/stats':
      case 'GET /payment-method':
        return _json({'success': true, 'data': {'method': 'QRIS Instant'}});
      case 'GET /owner/courts':
        return _json({'success': true, 'data': [_court]});
      case 'GET /owner/stats':
        return _json({'success': true, 'data': {'perCourt': []}});
      case 'GET /owner/schedule':
        return _json({'success': true, 'data': [{'slot': '18:00', 'booking': null}]});
      case 'GET /courts':
        return _json({'success': true, 'data': [_court]});
    }
    return _json({'success': true, 'data': []});
  });
}

void main() {
  final api = ApiService.instance;
  final log = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    log.clear();
    await api.setToken(null);
    api.client = _server(log);
  });

  test('Booking.fromJson memakai harga dari server', () {
    final b = Booking.fromJson(_booking());
    expect(b.finalPrice, 250);
    expect(b.isPendingPayment, true);
    expect(b.paymentRef, startsWith('QRIS-'));
    expect(b.court.pricePerHour, 220);
    expect(b.date, DateTime(2030, 1, 2));
  });

  test('ApiService: envelope, token header, error bertipe', () async {
    await api.setToken('abc');
    final d = await api.get('/courts', auth: false);
    expect(d, isA<List>());
    expect(log.single, 'GET /courts auth=null');

    api.client = _server(log, conflict: true);
    expect(
      () => BookingStore.instance.book(Court.fromJson(_court), DateTime(2030, 1, 2), '18:00'),
      throwsA(isA<ApiException>().having((e) => e.isConflict, 'conflict', true)),
    );
    api.client = MockClient((_) async => throw Exception('offline'));
    await expectLater(api.get('/x'), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'network', true)));
  });

  test('401 pada request terautentikasi menghapus token & memanggil onUnauthorized', () async {
    await api.setToken('old');
    var called = false;
    api.onUnauthorized = () => called = true;
    api.client = MockClient((_) async => _json({'success': false, 'message': 'Silakan login'}, 401));
    await expectLater(api.get('/bookings'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    expect(called, true);
    expect(api.hasToken, false);
    api.onUnauthorized = null;
  });

  test('UserStore.login: token tersimpan, role dari server, logout membersihkan', () async {
    final user = UserStore.instance;
    await expectLater(user.login('a@b.id', 'salah'), throwsA(isA<ApiException>()));
    expect(user.isLoggedIn, false);

    await user.login('a@b.id', 'secret123');
    expect(user.isLoggedIn, true);
    expect(api.token, 'tok-1');
    expect(user.profile.role, 'player');
    expect(user.isVenueOwner, false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(log.any((l) => l == 'GET /bookings auth=Bearer tok-1'), true);

    await user.logout();
    expect(user.isLoggedIn, false);
    expect(api.hasToken, false);
    expect(BookingStore.instance.bookings, isEmpty);
  });

  test('role owner dari server membuka /owner/*', () async {
    api.client = _server(log, role: 'owner');
    await UserStore.instance.login('o@b.id', 'secret123');
    expect(UserStore.instance.isVenueOwner, true);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(log.any((l) => l.startsWith('GET /owner/courts')), true);
    expect(OwnerStore.instance.selected?.id, 'c1');
    await UserStore.instance.logout();
    expect(UserStore.instance.isVenueOwner, false);
  });

  test('BookingStore: book -> slot taken -> pay -> cancel', () async {
    await UserStore.instance.login('a@b.id', 'secret123');
    final court = Court.fromJson(_court);
    final day = DateTime(2030, 1, 2);
    final store = BookingStore.instance;
    await store.loadSlots(court, day);
    expect(store.isTaken(court, day, '17:00'), false);
    expect(store.isTaken(court, day, '18:00'), true);

    final b = await store.book(court, day, '18:00', paymentMethod: 'QRIS Instant', addOnIds: ['racket']);
    expect(b.finalPrice, 250);
    expect(store.activeBookings.length, 1);

    final paid = await store.pay(b);
    expect(paid.isPaid, true);

    await store.cancel(paid);
    expect(store.activeBookings, isEmpty);
    expect(store.history.first.status, 'Dibatalkan');
    await UserStore.instance.logout();
  });

  test('CatalogStore: fallback offline memakai data lokal', () async {
    api.client = MockClient((_) async => throw Exception('down'));
    await CatalogStore.instance.refreshCourts();
    expect(CatalogStore.instance.isOffline, true);
    expect(courts, isNotEmpty);
    expect(courts.first.id, 'c1');
  });

  test('CatalogStore: online mengganti katalog dengan data server', () async {
    await CatalogStore.instance.refreshCourts();
    expect(CatalogStore.instance.isOffline, false);
    expect(courts.length, 1);
    expect(courts.first.name, 'Court A');
    courts = fallbackCourts;
  });

  test('Voucher.fromJson & hitung diskon persen dengan batas maksimum', () {
    final v = Voucher.fromJson({
      'code': 'PADELNEW', 'title': 't', 'description': 'd', 'discountAmount': 0,
      'percentage': 0.2, 'maxDiscount': 35, 'minSpend': 120,
    });
    expect(v.calculateDiscount(100), 0);
    expect(v.calculateDiscount(220), 35);
    expect(v.calculateDiscount(150), 30);
  });
}
