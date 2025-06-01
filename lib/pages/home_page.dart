// pages/home_page.dart
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../widgets/monthly_summary_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = KmController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KM Counter'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Column(
            children: [
              // Riepilogo mensile
              MonthlySummaryWidget(controller: _controller),
              
              // Calendario
              Expanded(
                child: CalendarWidget(
                  controller: _controller,
                  onDateSelected: (date) {
                    _controller.setSelectedDate(date);
                    setState(() {
                      _showDetailCard = true;
                    });
                  },
                ),
              ),
              
              // Card dettaglio (quando selezionata una data)
              if (_showDetailCard)
                KmDetailCard(
                  controller: _controller,
                  selectedDate: _controller.selectedDate,
                  onClose: () {
                    setState(() {
                      _showDetailCard = false;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}