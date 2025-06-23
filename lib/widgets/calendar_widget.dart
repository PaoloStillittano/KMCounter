//lib/widgets/calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_day.dart';
import '../view_models/calendar_view_model.dart';
import '../utils/app_themes.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onMonthChanged;

  const CalendarWidget({
    super.key,
    required this.onDateSelected,
    this.onMonthChanged,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<CalendarViewModel>(context, listen: false);
      widget.onMonthChanged?.call(viewModel.currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    return Column(
      children: [
        _CalendarHeader(
          monthYear: viewModel.monthYearString,
          onPrevious: () {
            viewModel.previousMonth();
            widget.onMonthChanged?.call(viewModel.currentMonth);
          },
          onNext: () {
            viewModel.nextMonth();
            widget.onMonthChanged?.call(viewModel.currentMonth);
          },
        ),
        _WeekdayHeaders(),
        Expanded(
          child: _CalendarGrid(
            days: viewModel.calendarDays,
            onDateSelected: widget.onDateSelected,
          ),
        ),
      ],
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final String monthYear;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _CalendarHeader({
    required this.monthYear,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious, 
            icon: Icon(
              Icons.chevron_left,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            monthYear,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: onNext, 
            icon: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (day == 'Sab' || day == 'Dom') 
                    ? AppThemes.holidayColor 
                    : theme.colorScheme.onSurface.withAlpha(153),
                fontSize: 12,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<CalendarDay> days;
  final Function(DateTime) onDateSelected;

  const _CalendarGrid({required this.days, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _CalendarDayCell(day: day, onDateSelected: onDateSelected);
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final Function(DateTime) onDateSelected;

  const _CalendarDayCell({required this.day, required this.onDateSelected});

  Color _getDayTextColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (day.isToday) return Colors.white;
    if (!day.isCurrentMonth) return theme.colorScheme.onSurface.withAlpha(77);
    if (day.isHoliday) return AppThemes.holidayColor;
    return theme.colorScheme.onSurface;
  }

  Color _getDayBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (day.isToday) {
      return isDark ? Colors.blue.withAlpha(115) : Colors.blue.withAlpha(230);
    }
    return Colors.transparent;
  }

  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    
    return theme.brightness == Brightness.dark 
        ? theme.colorScheme.outline.withAlpha(77)
        : Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: day.isCurrentMonth ? () => onDateSelected(day.date) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _getBorderColor(context), width: 1),
          borderRadius: BorderRadius.circular(8),
          color: _getDayBackgroundColor(context),
        ),
        child: Stack(
          children: [
            // Category indicator bar at the bottom
            if (day.hasEntries && day.isCurrentMonth && day.totalKm > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 8,
                child: Row(
                  children: [
                    if (day.personalKm > 0)
                      Expanded(
                        flex: (day.personalPercentage * 100).round(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppThemes.personalKmColor, 
                            borderRadius: BorderRadius.only(
                              bottomLeft: const Radius.circular(7),
                              bottomRight: day.workKm <= 0 ? const Radius.circular(7) : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                    if (day.workKm > 0)
                      Expanded(
                        flex: (day.workPercentage * 100).round(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppThemes.workKmColor, 
                            borderRadius: BorderRadius.only(
                              bottomRight: const Radius.circular(7),
                              bottomLeft: day.personalKm <= 0 ? const Radius.circular(7) : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Day number
            Center(
              child: Text(
                '${day.date.day}',
                style: TextStyle(
                  color: _getDayTextColor(context),
                  fontWeight: day.hasEntries && day.isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                  fontSize: day.isCurrentMonth ? 14 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}