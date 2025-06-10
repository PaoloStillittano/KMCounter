class CalendarDay {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isHoliday;
  final bool hasEntries;
  final double personalKm;
  final double workKm;
  final double totalKm;

  CalendarDay({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isHoliday,
    required this.hasEntries,
    required this.personalKm,
    required this.workKm,
    required this.totalKm,
  });

  // Calculated getters can be useful here
  double get personalPercentage => totalKm > 0 ? personalKm / totalKm : 0.0;
  double get workPercentage => totalKm > 0 ? workKm / totalKm : 0.0;
}