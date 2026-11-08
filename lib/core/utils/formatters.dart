import 'package:intl/intl.dart';

class APFormatters {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Format as full IDR, e.g. "Rp180.000"
  static String idr(int amount) => _currencyFormatter.format(amount);

  /// Format as compact thousands, e.g. "Rp180k"
  static String idrCompact(int thousands) => 'Rp${thousands}k';

  /// Format as standard date e.g. "Sabtu, 7 Nov 2026"
  static String date(DateTime d) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    return '$dayName, ${d.day} $monthName ${d.year}';
  }

  /// Format as full date e.g. "Sabtu, 7 November 2026"
  static String fullDate(DateTime d) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    return '$dayName, ${d.day} $monthName ${d.year}';
  }

  /// Relative date e.g. "Hari ini", "Besok", or "Sabtu, 7 Nov"
  static String relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    if (diff == 2) return 'Lusa';
    return date(d);
  }
}

