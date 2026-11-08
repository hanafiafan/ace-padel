import '../../data.dart';
import '../../services/api_service.dart';

class BookingRepository {
  static final BookingRepository instance = BookingRepository._();
  BookingRepository._();

  final List<Booking> _bookings = [];
  final List<Booking> _history = [];

  List<Booking> get activeBookings => List.unmodifiable(_bookings);
  List<Booking> get history => List.unmodifiable(_history);

  bool isSlotTaken(Court court, DateTime day, String slot) {
    return _bookings.any((b) =>
        b.court.id == court.id &&
        _sameDay(b.date, day) &&
        b.slot == slot);
  }

  bool createBooking({
    required Court court,
    required DateTime date,
    required String slot,
    int durationMinutes = 60,
    String paymentMethod = 'Bayar di tempat',
    String? voucherCode,
    int discount = 0,
    List<String> addOns = const [],
    int addOnsTotal = 0,
  }) {
    if (isSlotTaken(court, date, slot)) return false;

    final booking = Booking(
      court: court,
      date: _dayOnly(date),
      slot: slot,
      durationMinutes: durationMinutes,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      discount: discount,
      addOns: addOns,
      addOnsTotal: addOnsTotal,
      status: 'Terkonfirmasi',
    );

    _bookings.add(booking);

    // Sync to backend asynchronously
    ApiService.instance.createBooking(
      court: court,
      date: date,
      slot: slot,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      addOns: addOns,
      addOnsTotal: addOnsTotal,
    );

    return true;
  }

  void cancelBooking(Booking booking) {
    _bookings.removeWhere((b) => b.key == booking.key);
    _history.insert(
      0,
      Booking(
        id: booking.id,
        court: booking.court,
        date: booking.date,
        slot: booking.slot,
        paymentMethod: booking.paymentMethod,
        voucherCode: booking.voucherCode,
        discount: booking.discount,
        status: 'Dibatalkan',
      ),
    );

    ApiService.instance.cancelBooking(booking.id);
  }

  Booking? findById(String id) {
    final clean = id.trim().toUpperCase();
    return _bookings.where((b) => b.id.toUpperCase() == clean).firstOrNull ??
        _history.where((b) => b.id.toUpperCase() == clean).firstOrNull;
  }

  bool checkIn(String bookingId) {
    final clean = bookingId.trim().toUpperCase();
    final idx = _bookings.indexWhere((b) => b.id.toUpperCase() == clean);
    if (idx == -1) return false;

    final existing = _bookings[idx];
    _bookings[idx] = existing.copyWith(status: 'Check-in Selesai');

    ApiService.instance.checkInTicket(existing.id);
    return true;
  }

  bool toggleMaintenance({
    required Court court,
    required DateTime date,
    required String slot,
    bool block = true,
    String reason = 'Perawatan Rutin Lapangan',
  }) {
    if (block) {
      if (isSlotTaken(court, date, slot)) return false;
      final m = Booking(
        id: 'MAINT-${court.id.toUpperCase()}-${slot.replaceAll(':', '')}',
        court: court,
        date: _dayOnly(date),
        slot: slot,
        paymentMethod: 'Khusus Pengelola',
        status: 'Maintenance',
      );
      _bookings.add(m);

      ApiService.instance.toggleSlotMaintenance(
        courtId: court.id,
        date: date,
        slot: slot,
        block: true,
        reason: reason,
      );
      return true;
    } else {
      final idx = _bookings.indexWhere((b) =>
          b.court.id == court.id &&
          _sameDay(b.date, date) &&
          b.slot == slot &&
          b.status == 'Maintenance');
      if (idx == -1) return false;

      _bookings.removeAt(idx);

      ApiService.instance.toggleSlotMaintenance(
        courtId: court.id,
        date: date,
        slot: slot,
        block: false,
        reason: reason,
      );
      return true;
    }
  }

  Map<String, dynamic> getVenueStats(String courtId) {
    final list = _bookings.where((b) => b.court.id == courtId).toList();
    final checkedIn = list.where((b) => b.status == 'Check-in Selesai').length;
    // Hanya booking yang benar-benar berbayar: bukan maintenance, bukan batal.
    final paying =
        list.where((b) => b.status != 'Maintenance' && b.status != 'Dibatalkan').toList();
    int count(bool Function(String m) f) =>
        paying.where((b) => f(b.paymentMethod)).length;
    bool isQris(String m) => m.contains('QRIS');
    bool isVa(String m) => m.contains('Virtual');

    return {
      'totalBookings': list.length,
      'checkedInCount': checkedIn,
      'estimatedRevenue': paying.fold<int>(0, (sum, b) => sum + b.finalPrice),
      'paymentCounts': {
        'QRIS & e-wallet': count(isQris),
        'Transfer Virtual Account': count(isVa),
        'Bayar di tempat': count((m) => !isQris(m) && !isVa(m)),
      },
    };
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
