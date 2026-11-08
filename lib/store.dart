import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'services/api_service.dart';

ApiService get _api => ApiService.instance;

/// Shared `isLoading` / `error` handling for list stores.
mixin LoadState on ChangeNotifier {
  bool isLoading = false;
  String? error;

  /// Runs [fn], capturing ApiException into [error]. Returns true on success.
  Future<bool> load(Future<void> Function() fn) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await fn();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      debugPrint('$runtimeType load error: $e');
      error = 'Gagal memuat data.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

List<Map<String, dynamic>> _maps(dynamic d) =>
    (d as List? ?? const []).whereType<Map<String, dynamic>>().toList();

// ================= Catalog (public, offline fallback) =================

/// Courts, coaches and vouchers. Falls back to bundled data when offline.
class CatalogStore extends ChangeNotifier with LoadState {
  static final CatalogStore instance = CatalogStore._();
  CatalogStore._();

  bool isOffline = false;
  List<Coach> coaches = initialCoaches;
  List<Voucher> vouchers = const [];

  Court? courtById(String id) => courts.where((c) => c.id == id).firstOrNull;

  Future<void> loadAll() async {
    await Future.wait([refreshCourts(), refreshCoaches(), refreshVouchers()]);
  }

  /// GET /courts. Filters are passed through; screens may also filter locally.
  Future<void> refreshCourts({String? q, bool? indoor, String? city, String? sortBy}) async {
    await load(() async {
      try {
        final data = await _api.get('/courts', auth: false, query: {
          'q': q,
          'indoor': indoor?.toString(),
          'city': city,
          'sortBy': sortBy,
        });
        final list = _maps(data).map(Court.fromJson).toList();
        // Only replace the shared catalog on unfiltered loads.
        if (q == null && indoor == null && city == null && sortBy == null) courts = list;
        isOffline = false;
      } on ApiException catch (e) {
        if (!e.isNetwork) rethrow;
        isOffline = true;
        error = null;
      }
    });
  }

  Future<void> refreshCoaches() async {
    try {
      final data = await _api.get('/coaches', auth: false);
      final list = _maps(data).map(Coach.fromJson).toList();
      if (list.isNotEmpty) coaches = list;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isNetwork) {
        isOffline = true;
        notifyListeners();
      }
    }
  }

  Future<void> refreshVouchers() async {
    try {
      vouchers = _maps(await _api.get('/vouchers', auth: false)).map(Voucher.fromJson).toList();
      notifyListeners();
    } on ApiException catch (_) {}
  }

  /// Server-side check. Returns the voucher plus the discount (thousands).
  Future<(Voucher, int)> validateVoucher(String code, int price) async {
    final res = await _api.post('/vouchers/validate', {'code': code, 'price': price}, false);
    final d = res['data'] as Map<String, dynamic>;
    return (Voucher.fromJson(d), (d['discount'] as num?)?.toInt() ?? 0);
  }
}

// ================= Bookings =================

class BookingStore extends ChangeNotifier with LoadState {
  static final BookingStore instance = BookingStore._();
  BookingStore._();

  List<Booking> _active = [];
  List<Booking> _history = [];
  // courtId|date -> slot -> unavailable
  final Map<String, Map<String, bool>> _slots = {};
  bool slotsLoading = false;

  List<Booking> get bookings => List.unmodifiable(_active);
  List<Booking> get activeBookings => List.unmodifiable(_active);
  List<Booking> get history => List.unmodifiable(_history);

  void clear() {
    _active = [];
    _history = [];
    _slots.clear();
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_api.hasToken) return;
    await load(() async {
      final d = await _api.get('/bookings') as Map<String, dynamic>;
      _active = _maps(d['active']).map(Booking.fromJson).toList();
      _history = _maps(d['history']).map(Booking.fromJson).toList();
    });
  }

  // ---- slots ----
  String _k(String courtId, DateTime d) => '$courtId|${apiDate(d)}';

  bool isTaken(Court court, DateTime day, String slot) =>
      _slots[_k(court.id, day)]?[slot] ?? false;

  bool slotsKnown(Court court, DateTime day) => _slots.containsKey(_k(court.id, day));

  Future<void> loadSlots(Court court, DateTime day) async {
    slotsLoading = true;
    notifyListeners();
    try {
      final d = await _api.get('/courts/${court.id}/slots', query: {'date': apiDate(day)}, auth: false);
      _slots[_k(court.id, day)] = {
        for (final s in _maps(d)) '${s['slot']}': s['available'] != true,
      };
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      slotsLoading = false;
      notifyListeners();
    }
  }

  // ---- player actions ----
  /// Creates a booking. Prices are computed by the server.
  /// Throws [ApiException] (409 = slot taken; slots are refreshed first).
  Future<Booking> book(
    Court court,
    DateTime day,
    String slot, {
    String paymentMethod = 'Bayar di tempat',
    String? voucherCode,
    List<String> addOnIds = const [],
  }) async {
    try {
      final res = await _api.post('/bookings', {
        'courtId': court.id,
        'date': apiDate(day),
        'slot': slot,
        'paymentMethod': paymentMethod,
        if (voucherCode != null) 'voucherCode': voucherCode,
        'addOns': addOnIds,
      });
      final b = Booking.fromJson(res['data'] as Map<String, dynamic>);
      _active = [b, ..._active];
      _slots[_k(court.id, day)]?[slot] = true;
      notifyListeners();
      return b;
    } on ApiException catch (e) {
      if (e.isConflict) await loadSlots(court, day);
      rethrow;
    }
  }

  /// Simulated gateway callback (POST /bookings/:id/pay).
  Future<Booking> pay(Booking b) async {
    final res = await _api.post('/bookings/${b.id}/pay');
    final nb = Booking.fromJson(res['data'] as Map<String, dynamic>);
    _active = [for (final x in _active) x.id == nb.id ? nb : x];
    notifyListeners();
    return nb;
  }

  Future<void> cancel(Booking b) async {
    final res = await _api.delete('/bookings/${b.id}');
    final nb = Booking.fromJson(res['data'] as Map<String, dynamic>);
    _active = _active.where((x) => x.id != b.id).toList();
    _history = [nb, ..._history.where((x) => x.id != b.id)];
    _slots[_k(b.court.id, b.date)]?[b.slot] = false;
    notifyListeners();
  }

  Booking? findBookingById(String id) {
    final clean = id.trim().toUpperCase();
    return _active.where((b) => b.id.toUpperCase() == clean).firstOrNull ??
        _history.where((b) => b.id.toUpperCase() == clean).firstOrNull;
  }
}

// ================= Favorites =================

class FavoriteStore extends ChangeNotifier with LoadState {
  static final FavoriteStore instance = FavoriteStore._();
  FavoriteStore._();

  final Set<String> _ids = {};

  bool isFavorite(String courtId) => _ids.contains(courtId);
  List<Court> get favoriteCourts => courts.where((c) => _ids.contains(c.id)).toList();

  void clear() {
    _ids.clear();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_api.hasToken) return;
    await load(() async {
      _ids
        ..clear()
        ..addAll((await _api.get('/favorites') as List).map((e) => '$e'));
    });
  }

  /// Optimistic toggle; reverts and throws on failure.
  Future<void> toggle(String courtId) async {
    final had = _ids.contains(courtId);
    had ? _ids.remove(courtId) : _ids.add(courtId);
    notifyListeners();
    try {
      final res = await _api.post('/favorites/$courtId');
      final fav = (res['data'] as Map)['favorite'] == true;
      fav ? _ids.add(courtId) : _ids.remove(courtId);
    } catch (e) {
      had ? _ids.add(courtId) : _ids.remove(courtId);
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}

// ================= User / session =================

/// User profile data model (mirrors the server user).
class UserProfile {
  String id;
  String name;
  String username;
  String email;
  String phone;
  String skillLevel;
  String preferredHand;
  String role; // 'player' | 'owner' | 'admin' (server-confirmed)
  String? photoUrl;
  String authProvider; // 'google' | 'email' | 'guest'
  int points;
  int wins;
  int matches;
  bool isLoggedIn;

  UserProfile({
    this.id = '',
    this.name = 'Tamu',
    this.username = '',
    this.email = '',
    this.phone = '',
    this.skillLevel = 'Menengah (Intermediate)',
    this.preferredHand = 'Tangan Kanan (Right-handed)',
    this.role = 'player',
    this.photoUrl,
    this.authProvider = 'guest',
    this.points = 0,
    this.wins = 0,
    this.matches = 0,
    this.isLoggedIn = false,
  });

  void applyJson(Map<String, dynamic> m) {
    id = '${m['id'] ?? id}';
    name = (m['name'] as String?) ?? name;
    username = (m['username'] as String?) ?? '';
    email = (m['email'] as String?) ?? '';
    phone = (m['phone'] as String?) ?? '';
    skillLevel = (m['skillLevel'] as String?) ?? skillLevel;
    preferredHand = (m['preferredHand'] as String?) ?? preferredHand;
    role = (m['role'] as String?) ?? 'player';
    photoUrl = m['photoUrl'] as String?;
    authProvider = (m['authProvider'] as String?) ?? 'email';
    points = (m['points'] as num?)?.toInt() ?? 0;
    wins = (m['wins'] as num?)?.toInt() ?? 0;
    matches = (m['matches'] as num?)?.toInt() ?? 0;
    isLoggedIn = true;
  }
}

class UserStore extends ChangeNotifier {
  static final UserStore instance = UserStore._();
  UserStore._() {
    _api.onUnauthorized = _onUnauthorized;
  }

  static const _userKey = 'auth_user';

  final UserProfile profile = UserProfile();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Browsing the read-only catalog without an account.
  bool isGuest = false;
  bool restoring = false;

  bool get isLoggedIn => profile.isLoggedIn;
  bool get canBrowse => isLoggedIn || isGuest;
  bool get isVenueOwner => isLoggedIn && (profile.role == 'owner' || profile.role == 'admin');
  bool get isAdmin => isLoggedIn && profile.role == 'admin';

  void enterGuest() {
    isGuest = true;
    notifyListeners();
  }

  // ---- session ----
  Future<void> restore() async {
    restoring = true;
    await _api.loadToken();
    if (_api.hasToken) {
      try {
        _apply(await _api.get('/auth/me') as Map<String, dynamic>);
      } on ApiException catch (e) {
        if (e.isNetwork) {
          // Offline: trust the cached profile until the server is reachable.
          try {
            final raw = (await SharedPreferences.getInstance()).getString(_userKey);
            if (raw != null) profile.applyJson(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {}
        } else {
          await _api.setToken(null);
        }
      }
    }
    restoring = false;
    notifyListeners();
    if (isLoggedIn) unawaited(_afterLogin());
    unawaited(CatalogStore.instance.loadAll());
  }

  void _apply(Map<String, dynamic> user) {
    profile.applyJson(user);
    isGuest = false;
    () async {
      try {
        (await SharedPreferences.getInstance()).setString(_userKey, jsonEncode(user));
      } catch (_) {}
    }();
  }

  Future<void> _afterLogin() async {
    await Future.wait([
      BookingStore.instance.refresh(),
      FavoriteStore.instance.refresh(),
      FriendStore.instance.refresh(),
      MatchStore.instance.refresh(),
      NotificationStore.instance.refresh(),
      StatsStore.instance.refresh(),
      PaymentPrefStore.instance.refresh(),
      if (isVenueOwner) OwnerStore.instance.init(),
    ]);
  }

  Future<void> _session(Map<String, dynamic> res) async {
    await _api.setToken(res['token'] as String?);
    _apply(res['data'] as Map<String, dynamic>);
    notifyListeners();
    unawaited(_afterLogin());
  }

  Future<void> login(String email, String password) async =>
      _session(await _api.post('/auth/login', {'email': email.trim(), 'password': password}, false));

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool asOwner = false,
  }) async =>
      _session(await _api.post('/auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (asOwner) 'role': 'owner',
      }, false));

  /// POST /auth/google with the Google `idToken` (the server verifies it).
  Future<void> loginWithGoogleAccount({
    required String name,
    required String email,
    String? photoUrl,
    String? googleId,
    String? idToken,
  }) async =>
      _session(await _api.post('/auth/google', {
        if (idToken != null) 'idToken': idToken,
        // Only honoured by dev servers with ALLOW_UNVERIFIED_GOOGLE=1.
        'email': email,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (googleId != null) 'googleId': googleId,
      }, false));

  Future<void> logout() async {
    final wasGoogle = profile.authProvider == 'google';
    await _api.setToken(null);
    _reset();
    if (wasGoogle) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }

  void _onUnauthorized() => _reset();

  void _reset() {
    final p = UserProfile();
    profile
      ..id = p.id
      ..name = p.name
      ..username = ''
      ..email = ''
      ..phone = ''
      ..role = 'player'
      ..photoUrl = null
      ..authProvider = 'guest'
      ..points = 0
      ..wins = 0
      ..matches = 0
      ..isLoggedIn = false;
    isGuest = false;
    () async {
      try {
        (await SharedPreferences.getInstance()).remove(_userKey);
      } catch (_) {}
    }();
    BookingStore.instance.clear();
    FavoriteStore.instance.clear();
    FriendStore.instance.clear();
    MatchStore.instance.clear();
    NotificationStore.instance.clear();
    StatsStore.instance.clear();
    OwnerStore.instance.clear();
    notifyListeners();
  }

  /// PUT /auth/me. Throws ApiException on failure.
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? skillLevel,
    String? preferredHand,
    String? photoUrl,
  }) async {
    final res = await _api.put('/auth/me', {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (skillLevel != null) 'skillLevel': skillLevel,
      if (preferredHand != null) 'preferredHand': preferredHand,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    _apply(res['data'] as Map<String, dynamic>);
    notifyListeners();
  }
}

// ================= Matches (mabar) =================

class MatchStore extends ChangeNotifier with LoadState {
  static final MatchStore instance = MatchStore._();
  MatchStore._();

  List<OpenMatch> _matches = [];
  List<OpenMatch> get matches => List.unmodifiable(_matches);

  void clear() {
    _matches = [];
    notifyListeners();
  }

  bool isJoined(String matchId) =>
      _matches.where((x) => x.id == matchId).firstOrNull?.isJoined ?? false;

  Future<void> refresh() => load(() async {
        _matches = _maps(await _api.get('/matches', auth: _api.hasToken)).map(OpenMatch.fromJson).toList();
      });

  Future<void> create({
    required Court court,
    required String dateString,
    required String time,
    required String title,
    required String skillLevel,
    required int maxPlayers,
    required int pricePerPlayer,
  }) async {
    final res = await _api.post('/matches', {
      'courtId': court.id,
      'dateString': dateString,
      'time': time,
      'title': title,
      'skillLevel': skillLevel,
      'maxPlayers': maxPlayers,
      'pricePerPlayer': pricePerPlayer,
    });
    _matches = [OpenMatch.fromJson(res['data'] as Map<String, dynamic>), ..._matches];
    notifyListeners();
  }

  /// Toggles join/leave. Returns true when the user is now joined.
  Future<bool> toggleJoin(String matchId) async {
    final res = await _api.post('/matches/$matchId/join');
    final joined = res['joined'] == true;
    // Server returns the pre-toggle row; re-fetch to get accurate counts.
    await refresh();
    return joined;
  }
}

// ================= Friends & leaderboard =================

class FriendStore extends ChangeNotifier with LoadState {
  static final FriendStore instance = FriendStore._();
  FriendStore._();

  List<Player> friends = [];
  List<Player> globalBoard = [];
  List<Player> friendsBoard = [];

  Set<String> get friendIds => friends.map((f) => f.id).toSet();

  void clear() {
    friends = [];
    globalBoard = [];
    friendsBoard = [];
    notifyListeners();
  }

  bool isFriend(String idOrUsername) =>
      friends.any((f) => f.id == idOrUsername || f.username == idOrUsername);

  /// Global leaderboard (public) + friends scope when logged in.
  Future<void> refresh() => load(() async {
        globalBoard = _maps(await _api.get('/leaderboard', auth: _api.hasToken)).map(Player.fromJson).toList();
        if (_api.hasToken) {
          friends = _maps(await _api.get('/friends')).map(Player.fromJson).toList();
          friendsBoard = _maps(await _api.get('/leaderboard', query: {'scope': 'friends'})).map(Player.fromJson).toList();
        } else {
          friends = [];
          friendsBoard = [];
        }
      });

  Future<List<Player>> search(String q) async =>
      _maps(await _api.get('/players/search', query: {'q': q})).map(Player.fromJson).toList();

  /// Adds or removes a friend. Returns true when now a friend.
  Future<bool> toggleFriend(Player p) async {
    final willAdd = !isFriend(p.id);
    await _api.post(willAdd ? '/friends/add' : '/friends/remove', {'playerId': p.id});
    await refresh();
    return willAdd;
  }
}

// ================= Reviews =================

class ReviewStore extends ChangeNotifier {
  static final ReviewStore instance = ReviewStore._();
  ReviewStore._();

  final Map<String, List<CourtReview>> _reviews = {};

  List<CourtReview> getReviewsForCourt(String courtId) => _reviews[courtId] ?? const [];

  Future<void> load(String courtId) async {
    try {
      _reviews[courtId] =
          _maps(await _api.get('/reviews/$courtId', auth: false)).map(CourtReview.fromJson).toList();
      notifyListeners();
    } on ApiException catch (_) {}
  }

  /// POST /reviews (server requires a previous booking at the court).
  Future<void> submit(String courtId, double rating, String comment) async {
    final res = await _api.post('/reviews', {'courtId': courtId, 'rating': rating, 'comment': comment});
    final r = CourtReview.fromJson(res['data'] as Map<String, dynamic>);
    _reviews[courtId] = [r, ...(_reviews[courtId] ?? const [])];
    notifyListeners();
    unawaited(CatalogStore.instance.refreshCourts()); // rating changed
  }
}

// ================= Notifications =================

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.createdAt,
  });
  factory AppNotification.fromJson(Map<String, dynamic> m) => AppNotification(
        id: (m['id'] as num).toInt(),
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        type: (m['type'] as String?) ?? 'info',
        read: m['read'] == true,
        createdAt: DateTime.tryParse('${m['createdAt']}')?.toLocal(),
      );
}

class NotificationStore extends ChangeNotifier with LoadState {
  static final NotificationStore instance = NotificationStore._();
  NotificationStore._();

  List<AppNotification> items = [];
  int get unread => items.where((n) => !n.read).length;

  void clear() {
    items = [];
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_api.hasToken) return;
    await load(() async {
      items = _maps(await _api.get('/notifications')).map(AppNotification.fromJson).toList();
    });
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
    await refresh();
  }

  Future<void> markRead(AppNotification n) async {
    await _api.post('/notifications/${n.id}/read');
    await refresh();
  }
}

// ================= Profile stats & achievements =================

class StatsStore extends ChangeNotifier with LoadState {
  static final StatsStore instance = StatsStore._();
  StatsStore._();

  Map<String, dynamic> stats = {};
  List<Achievement> achievementList = achievements;

  int get activeBookings => (stats['activeBookings'] as num?)?.toInt() ?? 0;
  int get hoursPlayed => (stats['hoursPlayed'] as num?)?.toInt() ?? 0;
  int get points => (stats['points'] as num?)?.toInt() ?? 0;
  int get rank => (stats['rank'] as num?)?.toInt() ?? 0;

  void clear() {
    stats = {};
    achievementList = achievements;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_api.hasToken) return;
    await load(() async {
      stats = Map<String, dynamic>.from(await _api.get('/me/stats') as Map);
      final list = _maps(await _api.get('/achievements')).map(Achievement.fromJson).toList();
      if (list.isNotEmpty) achievementList = list;
    });
  }
}

// ================= Payment method preference =================

class PaymentPrefStore extends ChangeNotifier {
  static final PaymentPrefStore instance = PaymentPrefStore._();
  PaymentPrefStore._();

  String method = 'Bayar di tempat';

  Future<void> refresh() async {
    if (!_api.hasToken) return;
    try {
      method = ((await _api.get('/payment-method')) as Map)['method'] as String? ?? method;
      notifyListeners();
    } on ApiException catch (_) {}
  }

  Future<void> save(String m) async {
    await _api.put('/payment-method', {'method': m});
    method = m;
    notifyListeners();
  }
}

// ================= Coach sessions =================

class CoachSession {
  final String id;
  final String coachId;
  final String coachName;
  final String venue;
  final String date;
  final String slot;
  final String focus;
  final int price;
  final String status;
  const CoachSession({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.venue,
    required this.date,
    required this.slot,
    required this.focus,
    required this.price,
    required this.status,
  });
  factory CoachSession.fromJson(Map<String, dynamic> m) => CoachSession(
        id: '${m['id']}',
        coachId: '${m['coachId']}',
        coachName: (m['coachName'] as String?) ?? '',
        venue: (m['venue'] as String?) ?? '',
        date: (m['date'] as String?) ?? '',
        slot: (m['slot'] as String?) ?? '',
        focus: (m['focus'] as String?) ?? '',
        price: (m['price'] as num?)?.toInt() ?? 0,
        status: (m['status'] as String?) ?? '',
      );
}

class CoachSessionStore {
  static Future<CoachSession> book({
    required Coach coach,
    required String venue,
    required DateTime date,
    required String slot,
    required String focus,
  }) async {
    final res = await _api.post('/coach-sessions', {
      'coachId': coach.id,
      'venue': venue,
      'date': apiDate(date),
      'slot': slot,
      'focus': focus,
    });
    return CoachSession.fromJson(res['data'] as Map<String, dynamic>);
  }
}

// ================= Venue owner (/owner/*) =================

class VerifyResult {
  final bool valid;
  final String message;
  final Booking? booking;
  const VerifyResult(this.valid, this.message, this.booking);
}

class OwnerStore extends ChangeNotifier with LoadState {
  static final OwnerStore instance = OwnerStore._();
  OwnerStore._();

  List<Court> ownCourts = [];
  Court? selected;
  DateTime date = DateTime.now();
  Map<String, Booking?> schedule = {};
  List<Booking> courtBookings = [];
  Map<String, dynamic> stats = {};

  void clear() {
    ownCourts = [];
    selected = null;
    schedule = {};
    courtBookings = [];
    stats = {};
    notifyListeners();
  }

  Future<void> init() async {
    if (!_api.hasToken) return;
    await load(() async {
      ownCourts = _maps(await _api.get('/owner/courts')).map(Court.fromJson).toList();
      if (selected == null || !ownCourts.any((c) => c.id == selected!.id)) {
        selected = ownCourts.firstOrNull;
      }
      await _fetch();
    });
  }

  Future<void> refresh() => load(_fetch);

  Future<void> _fetch() async {
    final c = selected;
    stats = Map<String, dynamic>.from(await _api.get('/owner/stats', query: {'days': 14}) as Map);
    if (c == null) {
      schedule = {};
      courtBookings = [];
      return;
    }
    final sched = _maps(await _api.get('/owner/schedule', query: {'courtId': c.id, 'date': apiDate(date)}));
    schedule = {
      for (final s in sched)
        '${s['slot']}': s['booking'] is Map<String, dynamic> ? Booking.fromJson(s['booking'] as Map<String, dynamic>) : null,
    };
    final from = DateTime.now().subtract(const Duration(days: 13));
    courtBookings = _maps(await _api.get('/owner/bookings', query: {'courtId': c.id, 'from': apiDate(from)}))
        .map(Booking.fromJson)
        .toList();
  }

  Future<void> select(Court c) {
    selected = c;
    return refresh();
  }

  Future<void> setDate(DateTime d) {
    date = d;
    return refresh();
  }

  /// Per-court report derived from /owner/stats (perCourt) + booking list.
  Map<String, dynamic> courtStats() {
    final c = selected;
    final live = courtBookings.where((b) => b.status == 'Terkonfirmasi' || b.isCheckedIn).toList();
    final per = (stats['perCourt'] as List? ?? const [])
        .whereType<Map>()
        .where((x) => x['id'] == c?.id)
        .firstOrNull;
    int count(bool Function(String m) f) => live.where((b) => f(b.paymentMethod)).length;
    return {
      'totalBookings': (per?['bookings'] as num?)?.toInt() ?? live.length,
      'checkedInCount': courtBookings.where((b) => b.isCheckedIn).length,
      'estimatedRevenue': (per?['revenue'] as num?)?.toInt() ?? live.fold<int>(0, (s, b) => s + b.finalPrice),
      'paymentCounts': {
        'QRIS & e-wallet': count((m) => m.contains('QRIS')),
        'Transfer Virtual Account': count((m) => m.contains('Virtual')),
        'Bayar di tempat': count((m) => !m.contains('QRIS') && !m.contains('Virtual')),
      },
    };
  }

  /// POST /owner/verify-ticket. Invalid-but-found tickets (400) still carry the booking.
  Future<VerifyResult> verify(String code) async {
    final uri = Uri.parse('${_api.baseUrl}/api/owner/verify-ticket');
    try {
      final r = await _api.client
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                if (_api.hasToken) 'Authorization': 'Bearer ${_api.token}',
              },
              body: jsonEncode({'bookingId': code}))
          .timeout(_api.timeout);
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      if (r.statusCode == 401) {
        await _api.setToken(null);
        _api.onUnauthorized?.call();
      }
      if (r.statusCode == 403) return VerifyResult(false, (j['message'] as String?) ?? 'Akses ditolak', null);
      final b = j['data'] is Map<String, dynamic> ? Booking.fromJson(j['data'] as Map<String, dynamic>) : null;
      return VerifyResult(j['valid'] == true, (j['message'] as String?) ?? 'Tiket tidak valid.', b);
    } catch (_) {
      return const VerifyResult(false, 'Tidak dapat terhubung ke server.', null);
    }
  }

  Future<String> checkIn(String bookingId) async {
    final res = await _api.post('/owner/check-in', {'bookingId': bookingId});
    await refresh();
    return (res['message'] as String?) ?? 'Check-in berhasil';
  }

  Future<String> toggleSlot(String slot, {required bool block, String reason = 'Perawatan Rutin Lapangan'}) async {
    final res = await _api.post('/owner/toggle-slot', {
      'courtId': selected!.id,
      'date': apiDate(date),
      'slot': slot,
      'action': block ? 'block' : 'unblock',
      'reason': reason,
    });
    await refresh();
    return (res['message'] as String?) ?? 'Slot diperbarui';
  }

  Future<void> manualBooking(String slot, String customerName) async {
    await _api.post('/owner/manual-booking', {
      'courtId': selected!.id,
      'date': apiDate(date),
      'slot': slot,
      'customerName': customerName,
    });
    await refresh();
  }
}
