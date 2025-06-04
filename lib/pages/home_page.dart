// pages/home_page.dart
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
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
    return Scaffold(
      appBar: HomeAppBar(
        controller: _controller,
        currentMonth: _currentMonth,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final summaryHeight = _calculateSummaryHeight();
        final detailCardHeight = _showDetailCard ? 200.0 : 0.0;
        final calendarHeight = availableHeight - summaryHeight - detailCardHeight - 16;
        
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              children: [
                MonthlySummaryCompact(
                  controller: _controller,
                  currentMonth: _currentMonth,
                ),
                
                SizedBox(
                  height: calendarHeight.clamp(300.0, double.infinity),
                  child: CalendarWidget(
                    controller: _controller,
                    onDateSelected: _onDateSelected,
                    onMonthChanged: _onMonthChanged,
                  ),
                ),
                
                if (_showDetailCard && _selectedDate != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: KmDetailCard(
                      controller: _controller,
                      selectedDate: _selectedDate!,
                      onClose: _onDetailCardClose,
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
    final totalKm = _controller.getTotalKilometersForMonth(
      _currentMonth.year, 
      _currentMonth.month
    );
    return totalKm > 0 ? 140.0 : 120.0;
  }
}