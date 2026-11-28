/// Amounts and dates as the design shows them, in Spanish of Peru.
class Formats {
  const Formats._();

  static const _shortMonths = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'set', 'oct', 'nov', 'dic'];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'setiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// Soles with a comma for thousands and a dot for decimals: "S/ 2,400" or "S/ 150.50".
  static String soles(num amount) {
    final cents = (amount * 100).round();
    final whole = cents ~/ 100;
    final decimals = (cents % 100).abs();
    final digits = whole.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    final sign = cents < 0 ? '-' : '';
    final fraction = decimals == 0 ? '' : '.${decimals.toString().padLeft(2, '0')}';
    return 'S/ $sign$grouped$fraction';
  }

  /// An amount as typed in a field: "150" or "150.50".
  static String plainAmount(num amount) {
    final cents = (amount * 100).round();
    return cents % 100 == 0 ? (cents ~/ 100).toString() : (cents / 100).toStringAsFixed(2);
  }

  /// "5 de ene".
  static String shortDate(DateTime date) => '${date.day} de ${_shortMonths[date.month - 1]}';

  /// "5 nov 2026".
  static String mediumDate(DateTime date) => '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

  /// "5 de enero de 2027".
  static String longDate(DateTime date) => '${date.day} de ${_months[date.month - 1]} de ${date.year}';

  /// "14:05".
  static String time(DateTime moment) {
    final local = moment.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// A date of the backend ("2026-11-05") as a local date without time.
  static DateTime parseDate(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// A date as the backend expects it: "2026-11-05".
  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Today, without time.
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Adds months keeping the day inside the month: 31 jan + 1 month is 28 or 29 feb.
  static DateTime plusMonths(DateTime date, int months) {
    final month = date.month - 1 + months;
    final year = date.year + month ~/ 12;
    final targetMonth = month % 12 + 1;
    final lastDay = DateTime(year, targetMonth + 1, 0).day;
    return DateTime(year, targetMonth, date.day > lastDay ? lastDay : date.day);
  }
}
