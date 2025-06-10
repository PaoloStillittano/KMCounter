import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';
import '../models/calendar_day.dart';
import '../utils/holiday_utils.dart'; 

class CalendarViewModel extends ChangeNotifier {
  final KmController _kmController;
  late DateTime _currentMonth;
  List<CalendarDay> _calendarDays = [];

  DateTime get currentMonth => _currentMonth;
  List<CalendarDay> get calendarDays => _calendarDays;
  String get monthYearString => _getMonthYearString(_currentMonth);

  CalendarViewModel(this._kmController) {
    _currentMonth = DateTime.now();
    _generateCalendarDays();
  }

  void onMonthChanged(Function(DateTime)? callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback?.call(_currentMonth);
    });
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    _generateCalendarDays();
    notifyListeners(); 
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    _generateCalendarDays();
    notifyListeners(); 
  }

  void _generateCalendarDays() {
    final List<Map<String, dynamic>> dayMaps = _getCalendarDaysForMonth();
    _calendarDays = dayMaps.map((dayData) {
      final date = dayData['date'] as DateTime;
      final isCurrentMonth = dayData['isCurrentMonth'] as bool;
      final entries = _kmController.getEntriesForDate(date);
      final hasEntries = entries.isNotEmpty;

      double totalKm = 0;
      double personalKm = 0;
      double workKm = 0;

      if (hasEntries) {
        for (var entry in entries) {
          totalKm += entry.kilometers;
          if (entry.category == KmCategory.personal) {
            personalKm += entry.kilometers;
          } else if (entry.category == KmCategory.work) {
            workKm += entry.kilometers;
          }
        }
      }

      return CalendarDay(
        date: date,
        isCurrentMonth: isCurrentMonth,
        isToday: _isToday(date),
        isHoliday: ItalianHolidayUtils.isItalianHoliday(date),
        hasEntries: hasEntries,
        personalKm: personalKm,
        workKm: workKm,
        totalKm: totalKm,
      );
    }).toList();
  }

  List<Map<String, dynamic>> _getCalendarDaysForMonth() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday;
    final daysFromPreviousMonth = startingWeekday - 1;

    List<Map<String, dynamic>> calendarDays = [];

    if (daysFromPreviousMonth > 0) {
      final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      final lastDayPreviousMonth = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
      for (int i = daysFromPreviousMonth - 1; i >= 0; i--) {
        final day = lastDayPreviousMonth - i;
        calendarDays.add({
          'date': DateTime(previousMonth.year, previousMonth.month, day),
          'isCurrentMonth': false,
        });
      }
    }

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      calendarDays.add({
        'date': DateTime(_currentMonth.year, _currentMonth.month, day),
        'isCurrentMonth': true,
      });
    }

    final daysOnGrid = calendarDays.length;
    final daysFromNextMonth = (daysOnGrid > 35 ? 42 : 35) - daysOnGrid;
    if (daysFromNextMonth > 0) {
        final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
        for (int day = 1; day <= daysFromNextMonth; day++) {
            calendarDays.add({
                'date': DateTime(nextMonth.year, nextMonth.month, day),
                'isCurrentMonth': false,
            });
        }
    }
    
    return calendarDays;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  String _getMonthYearString(DateTime date) {
    const months = ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];
    return '${months[date.month - 1]} ${date.year}';
  }
}