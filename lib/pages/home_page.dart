import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/km_controller.dart';
import '../view_models/calendar_view_model.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/monthly_summary_compact.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/km_detail_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final KmController _controller;
  bool _showDetailCard = false;
  DateTime? _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _controller = KmController();
    _currentMonth = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _showDetailCard = true;
      _selectedDate = date;
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _currentMonth = newMonth;
    });
  }

  void _onDetailCardClose() {
    setState(() {
      _showDetailCard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: HomeAppBar(
          currentMonth: _currentMonth,
        ),
        body: Stack(
          children: [
            ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                return _buildMobileLayout();
              },
            ),
            if (_showDetailCard && _selectedDate != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onDetailCardClose,
                  child: Container(
                    color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(60),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: MediaQuery.of(context).size.height * 0.1,
                      ),
                      child: Center(
                        child: KmDetailCard(
                          controller: _controller,
                          selectedDate: _selectedDate!,
                          onClose: _onDetailCardClose,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final summaryHeight = _calculateSummaryHeight();
        final calendarHeight = availableHeight - summaryHeight - 16;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              children: [
                MonthlySummaryCompact(
                  currentMonth: _currentMonth,
                ),
                SizedBox(
                  height: calendarHeight.clamp(300.0, double.infinity),
                  child: ChangeNotifierProvider<CalendarViewModel>(
                    create: (ctx) => CalendarViewModel(
                      ctx.read<KmController>(),
                    ),
                    child: CalendarWidget(
                      onDateSelected: _onDateSelected,
                      onMonthChanged: _onMonthChanged,
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

  double _calculateSummaryHeight() {
    final totalKm = context.read<KmController>().getTotalKilometersForMonth(
          _currentMonth.year,
          _currentMonth.month,
        );
    return totalKm > 0 ? 140.0 : 120.0;
  }
}