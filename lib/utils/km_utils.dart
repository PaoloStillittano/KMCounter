// utils/km_utils.dart
import 'package:flutter/material.dart';
import '../models/km_entry.dart';

class KmUtils {
  // Category styling utilities
  static Color getCategoryColor(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Colors.blue;
      case KmCategory.work:
        return Colors.orange;
    }
  }

  static IconData getCategoryIcon(KmCategory category) {
    switch (category) {
      case KmCategory.personal:
        return Icons.person;
      case KmCategory.work:
        return Icons.work;
    }
  }

  // Formatting utilities
  static String formatKilometers(double kilometers) {
    if (kilometers == kilometers.toInt()) {
      return '${kilometers.toInt()} km';
    }
    return '${kilometers.toStringAsFixed(1)} km';
  }

  static String formatDate(DateTime date) {
    const weekdays = [
      'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 
      'Venerdì', 'Sabato', 'Domenica'
    ];
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  static String formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Entry count utilities
  static String getEntryCountText(int count) {
    return '$count ${count == 1 ? 'entry' : 'entries'}';
  }

  // Validation utilities
  static String? validateKilometers(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci i chilometri';
    }
    final km = double.tryParse(value);
    if (km == null || km <= 0) {
      return 'Inserisci un valore valido';
    }
    return null;
  }

  // Statistics utilities
  static Map<KmCategory, double> getTotalsByCategory(List<KmEntry> entries) {
    final totals = <KmCategory, double>{};
    for (final category in KmCategory.values) {
      totals[category] = entries
          .where((entry) => entry.category == category)
          .fold(0.0, (sum, entry) => sum + entry.kilometers);
    }
    return totals;
  }

  static double getTotalKilometers(List<KmEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.kilometers);
  }
}

// Extended date utilities specific to KM tracking
class KmDateUtils {
  static const List<String> _weekdayNames = [
    'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 
    'Venerdì', 'Sabato', 'Domenica'
  ];

  static const List<String> _monthNames = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  static String getWeekdayName(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday must be between 1 and 7');
    }
    return _weekdayNames[weekday - 1];
  }

  static String getMonthName(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    return _monthNames[month - 1];
  }

  static String getFullDateString(DateTime date) {
    return '${_weekdayNames[date.weekday - 1]} ${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static String getMonthYearString(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static int getDaysInMonth(DateTime date) {
    return getLastDayOfMonth(date).day;
  }

  static List<DateTime> getDaysInDateRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }
}