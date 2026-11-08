import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  static const String _envApiUrl =
      String.fromEnvironment('API_URL', defaultValue: '');

  /// Default API endpoint:
  /// - Configurable via `--dart-define=API_URL=https://your-domain.com`
  /// - Release mode default: https://api.hellens.dev
  /// - Android emulator debug: http://10.0.2.2:3001
  /// - Web / desktop debug: http://localhost:3001
  String get baseUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    if (kReleaseMode) return 'https://api.hellens.dev';
    if (kIsWeb) return 'http://localhost:3001';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  bool _isServerOnline = false;
  bool get isServerOnline => _isServerOnline;

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 2));
      _isServerOnline = res.statusCode == 200;
      return _isServerOnline;
    } catch (_) {
      _isServerOnline = false;
      return false;
    }
  }

  /// Fetch courts from backend with optional filters
  Future<List<Court>> getCourts({
    String? q,
    bool? indoor,
    String? city,
    String? facility,
    String? sortBy,
  }) async {
    try {
      final params = <String, String>{};
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (indoor != null) params['indoor'] = indoor.toString();
      if (city != null) params['city'] = city;
      if (facility != null) params['facility'] = facility;
      if (sortBy != null) params['sortBy'] = sortBy;

      final uri =
          Uri.parse('$baseUrl/api/courts').replace(queryParameters: params);
      final res = await http.get(uri).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = (json['data'] as List)
            .map((item) => _parseCourt(item as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('ApiService getCourts fallback to local: $e');
    }
    return courts;
  }

  /// Fetch availability for court on a date
  Future<Map<String, bool>> getSlotsAvailability(
      String courtId, DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri =
          Uri.parse('$baseUrl/api/courts/$courtId/slots?date=$dateStr');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final slots = json['slots'] as List;
        final map = <String, bool>{};
        for (final s in slots) {
          map[s['slot'] as String] = s['taken'] as bool;
        }
        return map;
      }
    } catch (e) {
      debugPrint('ApiService getSlotsAvailability fallback: $e');
    }
    return {};
  }

  /// Create booking in backend
  Future<Booking?> createBooking({
    required Court court,
    required DateTime date,
    required String slot,
    String paymentMethod = 'Bayar di tempat',
    String? voucherCode,
    List<String> addOns = const [],
    int addOnsTotal = 0,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$baseUrl/api/bookings');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courtId': court.id,
          'date': dateStr,
          'slot': slot,
          'paymentMethod': paymentMethod,
          'voucherCode': voucherCode,
          'addOns': addOns,
          'addOnsTotal': addOnsTotal,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final bData = json['data'] as Map<String, dynamic>;
        final parsedAddOns = (bData['addOns'] as List?)?.map((e) => e.toString()).toList() ?? addOns;
        final parsedAddOnsTotal = (bData['addOnsTotal'] as num?)?.toInt() ?? addOnsTotal;
        return Booking(
          id: bData['id'] as String?,
          court: court,
          date: date,
          slot: slot,
          paymentMethod: paymentMethod,
          voucherCode: bData['voucherCode'] as String?,
          discount: (bData['discount'] as num?)?.toInt() ?? 0,
          addOns: parsedAddOns,
          addOnsTotal: parsedAddOnsTotal,
          status: 'Terkonfirmasi',
        );
      }
    } catch (e) {
      debugPrint('ApiService createBooking fallback: $e');
    }
    return null;
  }

  /// Cancel booking in backend
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/bookings/$bookingId');
      final res =
          await http.delete(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService cancelBooking fallback: $e');
      return false;
    }
  }

  /// Verify ticket QR code with backend
  Future<Map<String, dynamic>?> verifyTicket(String bookingId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/venue/verify-ticket');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bookingId': bookingId}),
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('ApiService verifyTicket fallback: $e');
      return null;
    }
  }

  /// Check-in ticket on backend
  Future<Map<String, dynamic>?> checkInTicket(String bookingId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/venue/check-in');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bookingId': bookingId}),
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('ApiService checkInTicket fallback: $e');
      return null;
    }
  }

  /// Block or unblock slot for maintenance/tournament
  Future<bool> toggleSlotMaintenance({
    required String courtId,
    required DateTime date,
    required String slot,
    bool block = true,
    String reason = 'Perawatan Rutin Lapangan',
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$baseUrl/api/venue/toggle-slot');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courtId': courtId,
          'date': dateStr,
          'slot': slot,
          'action': block ? 'block' : 'unblock',
          'reason': reason,
        }),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService toggleSlotMaintenance fallback: $e');
      return false;
    }
  }

  /// Fetch venue dashboard stats from backend
  Future<Map<String, dynamic>?> getVenueStats(String courtId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/venue/stats/$courtId');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('ApiService getVenueStats fallback: $e');
    }
    return null;
  }

  /// Fetch friends list from backend
  Future<List<String>?> getFriends() async {
    try {
      final uri = Uri.parse('$baseUrl/api/friends');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return (json['data'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('ApiService getFriends fallback: $e');
    }
    return null;
  }

  /// Add friend on backend
  Future<bool> addFriend(String playerId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/friends/add');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerId': playerId}),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService addFriend fallback: $e');
      return false;
    }
  }

  /// Remove friend on backend
  Future<bool> removeFriend(String playerId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/friends/remove');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerId': playerId}),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService removeFriend fallback: $e');
      return false;
    }
  }

  /// Sync Google OAuth profile with backend
  Future<Map<String, dynamic>?> loginGoogle({
    required String email,
    required String name,
    String? photoUrl,
    String? idToken,
    String? googleId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'name': name,
              'photoUrl': photoUrl,
              'idToken': idToken,
              'googleId': googleId,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService loginGoogle fallback: $e');
    }
    return null;
  }

  Court _parseCourt(Map<String, dynamic> map) {
    final existing = courts.where((c) => c.id == map['id']).firstOrNull;
    if (existing != null) return existing;

    return Court(
      id: map['id'] as String,
      name: map['name'] as String,
      venue: map['venue'] as String,
      area: map['area'] as String,
      rating: (map['rating'] as num).toDouble(),
      pricePerHour: (map['pricePerHour'] as num).toInt(),
      indoor: map['indoor'] as bool,
      gradient: const [Color(0xFF2334DB), Color(0xFF4756F0)],
      image: 'assets/images/court1.jpg',
      facilities: (map['facilities'] as List?)?.map((e) => e.toString()).toList() ??
          const ['Sewa Raket & Bola', 'Shower Air Panas', 'Parkir Luas'],
      description: map['description'] as String? ?? 'Lapangan padel profesional.',
    );
  }
}
