import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart' show Booking;

/// Error from the backend (or the network) with a user-friendly message.
class ApiException implements Exception {
  final String message;
  final int status; // 0 = network/timeout/parse error
  const ApiException(this.message, [this.status = 0]);

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isConflict => status == 409;

  @override
  String toString() => message;
}

/// Central HTTP client: base URL, bearer token, `{success,data}` envelope,
/// typed errors, timeouts and auto-logout on 401.
class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  static const String _envApiUrl =
      String.fromEnvironment('API_URL', defaultValue: '');
  static const _tokenKey = 'auth_token';

  /// Replaceable in tests (package:http/testing.dart MockClient).
  http.Client client = http.Client();
  Duration timeout = const Duration(seconds: 12);

  String? _token;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Called when the server answers 401 for an authenticated call.
  VoidCallback? onUnauthorized;

  /// Default API endpoint:
  /// - Configurable via `--dart-define=API_URL=https://your-domain.com`
  /// - Release mode default: https://acepadel.hellens.dev
  /// - Android emulator debug: http://10.0.2.2:3001
  /// - Web / desktop debug: http://localhost:3001
  String get baseUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    if (kReleaseMode) return 'https://acepadel.hellens.dev';
    if (kIsWeb) return 'http://localhost:3001';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  /// Turns `/img/x.jpg` / `/uploads/x` into an absolute URL.
  String absUrl(String path) =>
      path.startsWith('http') ? path : '$baseUrl${path.startsWith('/') ? '' : '/'}$path';

  // ---- token persistence ----
  Future<void> loadToken() async {
    try {
      _token = (await SharedPreferences.getInstance()).getString(_tokenKey);
    } catch (_) {}
  }

  Future<void> setToken(String? t) async {
    _token = t;
    try {
      final p = await SharedPreferences.getInstance();
      if (t == null) {
        await p.remove(_tokenKey);
      } else {
        await p.setString(_tokenKey, t);
      }
    } catch (_) {}
  }

  // ---- core request ----
  /// Returns the whole decoded envelope (`data`, `token`, `slots`, ...).
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) async {
    var uri = Uri.parse('$baseUrl/api$path');
    if (query != null) {
      final q = <String, String>{
        for (final e in query.entries)
          if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
      };
      if (q.isNotEmpty) uri = uri.replace(queryParameters: q);
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (auth && hasToken) 'Authorization': 'Bearer $_token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    late http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await client.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          res = await client.post(uri, headers: headers, body: encoded ?? '{}').timeout(timeout);
        case 'PUT':
          res = await client.put(uri, headers: headers, body: encoded ?? '{}').timeout(timeout);
        case 'DELETE':
          res = await client.delete(uri, headers: headers).timeout(timeout);
        default:
          throw ArgumentError('Unsupported method $method');
      }
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Coba lagi.');
    } catch (e) {
      debugPrint('ApiService $method $path network error: $e');
      throw const ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }

    Map<String, dynamic> json = {};
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map<String, dynamic>) json = d;
    } catch (_) {}

    final ok = res.statusCode >= 200 && res.statusCode < 300 && json['success'] != false;
    if (!ok) {
      final msg = (json['message'] as String?) ?? 'Terjadi kesalahan (${res.statusCode}).';
      if (res.statusCode == 401 && auth && hasToken) {
        await setToken(null);
        onUnauthorized?.call();
      }
      throw ApiException(msg, res.statusCode == 0 ? 500 : res.statusCode);
    }
    return json;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async =>
      (await request('GET', path, query: query, auth: auth))['data'];
  Future<Map<String, dynamic>> post(String path, [Object? body, bool auth = true]) =>
      request('POST', path, body: body ?? const {}, auth: auth);
  Future<Map<String, dynamic>> put(String path, Object body) => request('PUT', path, body: body);
  Future<Map<String, dynamic>> delete(String path) => request('DELETE', path);

  /// Quick reachability probe.
  Future<bool> checkHealth() async {
    try {
      final res = await client
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- payments (DOKU) ----
  String? _paymentProvider;

  /// Test hook: forget the cached provider.
  void resetPaymentProvider() => _paymentProvider = null;

  /// `'doku'` or `'simulated'`; cached per session. Falls back to
  /// 'simulated' (uncached) when the server cannot be reached.
  Future<String> getPaymentProvider() async {
    if (_paymentProvider != null) return _paymentProvider!;
    try {
      final d = await get('/payments/config', auth: false);
      return _paymentProvider = ((d as Map)['provider'] as String?) ?? 'simulated';
    } on ApiException {
      return 'simulated';
    }
  }

  /// POST /bookings/:id/checkout -> DOKU hosted payment URL.
  Future<String> checkoutBooking(String id) async {
    final res = await post('/bookings/$id/checkout');
    final url = res['paymentUrl'] as String?;
    if (url == null || url.isEmpty) throw const ApiException('Link pembayaran tidak tersedia. Coba lagi.');
    return url;
  }

  /// GET /bookings/:id/payment-status (server syncs with DOKU).
  Future<(Booking, bool)> refreshPaymentStatus(String id) async {
    final res = await request('GET', '/bookings/$id/payment-status');
    return (Booking.fromJson(res['data'] as Map<String, dynamic>), res['paid'] == true);
  }
}

/// `YYYY-MM-DD` as the backend expects.
String apiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
