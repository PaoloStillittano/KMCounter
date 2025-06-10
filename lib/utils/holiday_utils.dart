class ItalianHolidayUtils {
  static bool isItalianHoliday(DateTime date) {
    // Weekend
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return true;
    }

    // Fixed holidays
    final fixedHolidays = [
      DateTime(date.year, 1, 1),  // Capodanno
      DateTime(date.year, 1, 6),  // Epifania
      DateTime(date.year, 4, 25), // Festa della Liberazione
      DateTime(date.year, 5, 1),  // Festa del Lavoro
      DateTime(date.year, 6, 2),  // Festa della Repubblica
      DateTime(date.year, 8, 15), // Ferragosto
      DateTime(date.year, 11, 1), // Ognissanti
      DateTime(date.year, 12, 8), // Immacolata Concezione
      DateTime(date.year, 12, 25),// Natale
      DateTime(date.year, 12, 26),// Santo Stefano
    ];

    for (final holiday in fixedHolidays) {
      if (date.year == holiday.year && date.month == holiday.month && date.day == holiday.day) {
        return true;
      }
    }

    // Easter and Easter Monday (variable dates)
    final easter = _calculateEaster(date.year);
    final easterMonday = easter.add(const Duration(days: 1));

    if ((date.year == easter.year && date.month == easter.month && date.day == easter.day) ||
        (date.year == easterMonday.year && date.month == easterMonday.month && date.day == easterMonday.day)) {
      return true;
    }

    return false;
  }

  static DateTime _calculateEaster(int year) {
    // Gauss algorithm for calculating Easter date
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }
}