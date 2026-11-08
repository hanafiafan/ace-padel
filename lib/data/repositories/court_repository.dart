import '../../data.dart';
import '../../services/api_service.dart';

class CourtRepository {
  static final CourtRepository instance = CourtRepository._();
  CourtRepository._();

  List<Court> _cachedCourts = courts;
  final Set<String> _favoriteIds = {'c1', 'c4'};

  List<Court> get allCourts => List.unmodifiable(_cachedCourts);

  bool isFavorite(String courtId) => _favoriteIds.contains(courtId);

  List<Court> get favoriteCourts =>
      _cachedCourts.where((c) => _favoriteIds.contains(c.id)).toList();

  void toggleFavorite(String courtId) {
    if (_favoriteIds.contains(courtId)) {
      _favoriteIds.remove(courtId);
    } else {
      _favoriteIds.add(courtId);
    }
  }

  Court? getCourtById(String id) {
    try {
      return _cachedCourts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Court>> fetchCourts({
    String? query,
    bool? indoor,
    String? city,
    String? sortBy,
  }) async {
    final remote = await ApiService.instance.getCourts(
      q: query,
      indoor: indoor,
      city: city,
      sortBy: sortBy,
    );
    if (remote.isNotEmpty) {
      _cachedCourts = remote;
    }
    return _cachedCourts;
  }
}
