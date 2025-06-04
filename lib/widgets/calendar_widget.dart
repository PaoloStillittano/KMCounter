// widgets/calendar_widget.dart
import 'package:counter/models/km_entry.dart';
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';

class CalendarWidget extends StatefulWidget {
  final KmController controller;
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onMonthChanged; // NUOVO PARAMETRO

  const CalendarWidget({
    super.key,
    required this.controller,
    required this.onDateSelected,
    this.onMonthChanged, // NUOVO PARAMETRO OPZIONALE
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late PageController _pageController;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _pageController = PageController();

    // AGGIUNGI QUESTA RIGA per notificare il mese iniziale:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMonthChanged?.call(_currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con navigazione mese
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _getMonthYearString(_currentMonth),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Header giorni della settimana
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: _buildWeekdayHeaders(),
          ),
        ),

        // Calendario
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  List<Widget> _buildWeekdayHeaders() {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return weekdays
        .map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (day == 'Sab' || day == 'Dom')
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget _buildCalendarGrid() {
    final calendarDays = _getCalendarDays();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: calendarDays.length,
      itemBuilder: (context, index) {
        final dayData = calendarDays[index];
        final date = dayData['date'] as DateTime;
        final isCurrentMonth = dayData['isCurrentMonth'] as bool;
        final entries = widget.controller.getEntriesForDate(date);
        final hasEntries = entries.isNotEmpty;
        final isToday = _isToday(date);
        final isHoliday = _isItalianHoliday(date);

        // Calculate category proportions
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

        // Calculate percentages
        final personalPercentage = totalKm > 0 ? personalKm / totalKm : 0.0;
        final workPercentage = totalKm > 0 ? workKm / totalKm : 0.0;

        return GestureDetector(
          onTap: isCurrentMonth ? () => widget.onDateSelected(date) : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Background for the day
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday ? Colors.blue.withAlpha(40) : null,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),

                // Category colors at the bottom of the cell
                if (hasEntries && isCurrentMonth && totalKm > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 8, // Fixed height for the color bar
                    child: Row(
                      children: [
                        // Personal category (left portion)
                        if (personalKm > 0)
                          Expanded(
                            flex: (personalPercentage * 100).round(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(7),
                                  bottomRight: workKm <= 0
                                      ? Radius.circular(7)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          ),

                        // Work category (right portion)
                        if (workKm > 0)
                          Expanded(
                            flex: (workPercentage * 100).round(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(40),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(7),
                                  bottomLeft: personalKm <= 0
                                      ? Radius.circular(7)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Day number (on top of the colors)
                Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color:
                          _getDayTextColor(isToday, isHoliday, isCurrentMonth),
                      fontWeight: hasEntries && isCurrentMonth
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: isCurrentMonth ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getCalendarDays() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Calcola i giorni del mese precedente da mostrare
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Lunedì, 7 = Domenica
    final daysFromPreviousMonth = startingWeekday - 1;

    // Calcola i giorni del mese successivo da mostrare
    final endingWeekday = lastDayOfMonth.weekday;
    final daysFromNextMonth = 7 - endingWeekday;

    List<Map<String, dynamic>> calendarDays = [];

    // Aggiungi giorni del mese precedente
    if (daysFromPreviousMonth > 0) {
      final previousMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1);
      final lastDayPreviousMonth =
          DateTime(_currentMonth.year, _currentMonth.month, 0).day;

      for (int i = daysFromPreviousMonth - 1; i >= 0; i--) {
        final day = lastDayPreviousMonth - i;
        calendarDays.add({
          'date': DateTime(previousMonth.year, previousMonth.month, day),
          'isCurrentMonth': false,
        });
      }
    }

    // Aggiungi giorni del mese corrente
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      calendarDays.add({
        'date': DateTime(_currentMonth.year, _currentMonth.month, day),
        'isCurrentMonth': true,
      });
    }

    // Aggiungi giorni del mese successivo per completare la griglia
    if (daysFromNextMonth < 7) {
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

  Color _getDayTextColor(bool isToday, bool isHoliday, bool isCurrentMonth) {
    if (isToday) return Colors.white;
    if (!isCurrentMonth) return Colors.grey[400]!;
    if (isHoliday) return Colors.red;
    return Colors.black;
  }

  bool _isItalianHoliday(DateTime date) {
    // Weekend
    if (date.weekday == 6 || date.weekday == 7)
      return true; // Sabato e Domenica

    // Feste fisse
    final fixedHolidays = [
      DateTime(date.year, 1, 1), // Capodanno
      DateTime(date.year, 1, 6), // Epifania
      DateTime(date.year, 4, 25), // Festa della Liberazione
      DateTime(date.year, 5, 1), // Festa del Lavoro
      DateTime(date.year, 6, 2), // Festa della Repubblica
      DateTime(date.year, 8, 15), // Ferragosto
      DateTime(date.year, 11, 1), // Ognissanti
      DateTime(date.year, 12, 8), // Immacolata Concezione
      DateTime(date.year, 12, 25), // Natale
      DateTime(date.year, 12, 26), // Santo Stefano
    ];

    for (final holiday in fixedHolidays) {
      if (date.year == holiday.year &&
          date.month == holiday.month &&
          date.day == holiday.day) {
        return true;
      }
    }

    // Pasqua e Lunedì dell'Angelo (date variabili)
    final easter = _calculateEaster(date.year);
    final easterMonday = easter.add(const Duration(days: 1));

    if ((date.year == easter.year &&
            date.month == easter.month &&
            date.day == easter.day) ||
        (date.year == easterMonday.year &&
            date.month == easterMonday.month &&
            date.day == easterMonday.day)) {
      return true;
    }

    return false;
  }

  DateTime _calculateEaster(int year) {
    // Algoritmo per calcolare la data di Pasqua (Algoritmo di Gauss)
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

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });

    // AGGIUNGI QUESTA RIGA:
    widget.onMonthChanged?.call(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });

    // AGGIUNGI QUESTA RIGA:
    widget.onMonthChanged?.call(_currentMonth);
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}