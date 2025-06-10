//lib/widgets/calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_day.dart';
import '../view_models/calendar_view_model.dart';

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
    // Use addPostFrameCallback to safely call the callback after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access the ViewModel safely after it's built
      final viewModel = Provider.of<CalendarViewModel>(context, listen: false);
      widget.onMonthChanged?.call(viewModel.currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel for changes
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

// --- UI Helper Widgets ---

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
          Text(
            monthYear,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _WeekdayHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (day == 'Sab' || day == 'Dom') ? Colors.red : Colors.grey[600],
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
      return const Center(child: CircularProgressIndicator());
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

  Color _getDayTextColor() {
    if (day.isToday) return Colors.white;
    if (!day.isCurrentMonth) return Colors.grey[400]!;
    if (day.isHoliday) return Colors.red;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: day.isCurrentMonth ? () => onDateSelected(day.date) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: day.isToday ? Colors.blue.withAlpha(190) : null,
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
                            color: Colors.green,
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
                            color: Colors.orange,
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
                  color: _getDayTextColor(),
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