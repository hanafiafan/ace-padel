import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'data.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/court_repository.dart';
import 'services/api_service.dart';

/// ViewModel & State Manager for Bookings, backed by BookingRepository.
class BookingStore extends ChangeNotifier {
  static final BookingStore instance = BookingStore._();
  BookingStore._();

  final _repo = BookingRepository.instance;

  List<Booking> get bookings => _repo.activeBookings;
  List<Booking> get activeBookings => _repo.activeBookings;
  List<Booking> get history => _repo.history;

  bool isTaken(Court court, DateTime day, String slot) =>
      _repo.isSlotTaken(court, day, slot);

  bool book(
    Court court,
    DateTime day,
    String slot, {
    int durationMinutes = 60,
    String paymentMethod = 'Bayar di tempat',
    String? voucherCode,
    int discount = 0,
    List<String> addOns = const [],
    int addOnsTotal = 0,
  }) {
    final success = _repo.createBooking(
      court: court,
      date: day,
      slot: slot,
      durationMinutes: durationMinutes,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      discount: discount,
      addOns: addOns,
      addOnsTotal: addOnsTotal,
    );
    if (success) notifyListeners();
    return success;
  }

  void cancel(Booking b) {
    _repo.cancelBooking(b);
    notifyListeners();
  }

  Booking? findBookingById(String id) => _repo.findById(id);

  bool checkIn(String bookingId) {
    final success = _repo.checkIn(bookingId);
    if (success) notifyListeners();
    return success;
  }

  bool toggleMaintenance(
    Court court,
    DateTime day,
    String slot, {
    bool block = true,
    String reason = 'Perawatan Rutin Lapangan',
  }) {
    final success = _repo.toggleMaintenance(
      court: court,
      date: day,
      slot: slot,
      block: block,
      reason: reason,
    );
    if (success) notifyListeners();
    return success;
  }

  List<Booking> getBookingsForCourtAndDate(String courtId, DateTime day) {
    return _repo.activeBookings
        .where((b) => b.court.id == courtId && _sameDay(b.date, day))
        .toList();
  }

  Map<String, dynamic> getVenueStats(String courtId) =>
      _repo.getVenueStats(courtId);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// ViewModel & State Manager for Favorite Courts, backed by CourtRepository.
class FavoriteStore extends ChangeNotifier {
  static final FavoriteStore instance = FavoriteStore._();
  FavoriteStore._();

  final _repo = CourtRepository.instance;

  bool isFavorite(String courtId) => _repo.isFavorite(courtId);

  List<Court> get favoriteCourts => _repo.favoriteCourts;

  void toggle(String courtId) {
    _repo.toggleFavorite(courtId);
    notifyListeners();
  }
}

/// User profile data model.
class UserProfile {
  String name;
  String email;
  String phone;
  String skillLevel;
  String preferredHand;
  String role; // 'player', 'venue_owner', 'admin'
  String managedCourtId; // e.g. 'c1'
  String? photoUrl;
  String authProvider; // 'google', 'guest', 'email'
  String? googleId;
  bool isLoggedIn;

  UserProfile({
    this.name = 'Afan',
    this.email = 'hanafiafan20@gmail.com',
    this.phone = '+62 812-3456-7890',
    this.skillLevel = 'Menengah (Intermediate)',
    this.preferredHand = 'Tangan Kanan (Right-handed)',
    this.role = 'player',
    this.managedCourtId = 'c1',
    this.photoUrl,
    this.authProvider = 'guest',
    this.googleId,
    this.isLoggedIn = false,
  });
}

/// ViewModel for User session & profile management.
class UserStore extends ChangeNotifier {
  static final UserStore instance = UserStore._();
  UserStore._();

  final UserProfile profile = UserProfile();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool get isVenueOwner => profile.role == 'venue_owner';
  bool get isLoggedIn => profile.isLoggedIn;

  void switchRole(String newRole) {
    profile.role = newRole;
    notifyListeners();
  }

  void setManagedCourt(String courtId) {
    profile.managedCourtId = courtId;
    notifyListeners();
  }

  Future<void> loginWithGoogleAccount({
    required String name,
    required String email,
    String? photoUrl,
    String? googleId,
    String? idToken,
  }) async {
    profile.name = name;
    profile.email = email;
    profile.photoUrl = photoUrl;
    profile.googleId = googleId;
    profile.authProvider = 'google';
    profile.isLoggedIn = true;
    notifyListeners();

    await ApiService.instance.loginGoogle(
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      await loginWithGoogleAccount(
        name: account.displayName ?? 'Player Padel',
        email: account.email,
        photoUrl: account.photoUrl,
        googleId: account.id,
      );
      return true;
    } catch (e) {
      debugPrint('Error signInWithGoogle: $e');
      return false;
    }
  }

  void loginAsGuest() {
    profile.name = 'Player Padel';
    profile.email = 'guest@acepadel.id';
    profile.photoUrl = null;
    profile.googleId = null;
    profile.authProvider = 'guest';
    profile.isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final wasGoogle = profile.authProvider == 'google';
    profile.isLoggedIn = false;
    profile.authProvider = 'guest';
    profile.googleId = null;
    notifyListeners();

    if (wasGoogle) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? skillLevel,
    String? preferredHand,
  }) {
    if (name != null) profile.name = name;
    if (email != null) profile.email = email;
    if (phone != null) profile.phone = phone;
    if (skillLevel != null) profile.skillLevel = skillLevel;
    if (preferredHand != null) profile.preferredHand = preferredHand;
    notifyListeners();
  }
}

/// ViewModel for Open Matches / Mabar.
class MatchStore extends ChangeNotifier {
  static final MatchStore instance = MatchStore._();
  MatchStore._();

  final List<OpenMatch> _matches = [...initialOpenMatches];

  List<OpenMatch> get matches => List.unmodifiable(_matches);

  bool isJoined(String matchId) {
    final m = _matches.where((x) => x.id == matchId).firstOrNull;
    return m?.isJoined ?? false;
  }

  void addMatch(OpenMatch match) {
    _matches.insert(0, match);
    notifyListeners();
  }

  bool toggleJoin(String matchId) {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx == -1) return false;

    final match = _matches[idx];
    final joined = match.isJoined;

    if (joined) {
      _matches[idx] = match.copyWith(
        currentPlayers: (match.currentPlayers - 1).clamp(0, match.maxPlayers),
        isJoined: false,
      );
      notifyListeners();
      return false;
    } else {
      if (match.currentPlayers >= match.maxPlayers) return false;
      _matches[idx] = match.copyWith(
        currentPlayers: match.currentPlayers + 1,
        isJoined: true,
      );
      notifyListeners();
      return true;
    }
  }
}

/// ViewModel for Friends & Community.
class FriendStore extends ChangeNotifier {
  static final FriendStore instance = FriendStore._();
  FriendStore._();

  final Set<String> _friendIds = {'p1', 'p5'};

  Set<String> get friendIds => _friendIds;

  List<Player> get friends =>
      players.where((p) => _friendIds.contains(p.id)).toList();

  bool isFriend(String playerIdOrUsername) =>
      _friendIds.contains(playerIdOrUsername) ||
      players
          .where((p) => p.username == playerIdOrUsername)
          .any((p) => _friendIds.contains(p.id));

  bool toggleFriend(String playerId) {
    final bool willAdd = !_friendIds.contains(playerId);
    if (willAdd) {
      _friendIds.add(playerId);
      final p = players.where((x) => x.id == playerId).firstOrNull;
      if (p != null) ApiService.instance.addFriend(p.username);
    } else {
      _friendIds.remove(playerId);
      final p = players.where((x) => x.id == playerId).firstOrNull;
      if (p != null) ApiService.instance.removeFriend(p.username);
    }
    notifyListeners();
    return willAdd;
  }

  void addFriend(Player p) {
    _friendIds.add(p.id);
    notifyListeners();
    ApiService.instance.addFriend(p.username);
  }

  void removeFriend(String username) {
    final p = players.where((x) => x.username == username).firstOrNull;
    if (p != null) _friendIds.remove(p.id);
    notifyListeners();
    ApiService.instance.removeFriend(username);
  }

  List<Player> get friendsLeaderboard {
    final currentUser = players.firstWhere((p) => p.isMe);
    final list = [
      currentUser,
      ...players.where((p) => _friendIds.contains(p.id) && !p.isMe),
    ];
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  List<Player> getLeaderboard(Player currentUser) {
    final list = [
      currentUser,
      ...players.where((p) => _friendIds.contains(p.id)),
    ];
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }
}

/// Store for user reviews & ratings.
class ReviewStore extends ChangeNotifier {
  static final ReviewStore instance = ReviewStore._();
  ReviewStore._();

  final Map<String, List<CourtReview>> _reviews = {
    'c1': [
      ...initialReviews.where((r) => r.courtId == 'c1'),
    ],
  };

  List<CourtReview> getReviewsForCourt(String courtId) {
    return _reviews[courtId] ?? initialReviews.where((r) => r.courtId == courtId).toList();
  }

  void addReview(CourtReview review, [String? courtId]) {
    final cId = courtId ?? review.courtId;
    final list = _reviews.putIfAbsent(cId, () => []);
    list.insert(0, review);
    notifyListeners();
  }
}
