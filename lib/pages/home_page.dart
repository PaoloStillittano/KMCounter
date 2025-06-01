// pages/home_page.dart
import 'package:counter/models/km_entry.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildModernAppBar(context),
      body: _buildResponsiveBody(context),
    );
  }

  Widget _buildResponsiveBody(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isLandscape = screenWidth > screenHeight;
        final isTablet = screenWidth > 600;
        
        // Layout diverso per landscape e tablet
        if (isLandscape && isTablet) {
          return _buildLandscapeLayout();
        } else if (isTablet) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // Layout per mobile (portrait)
  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final summaryHeight = _calculateSummaryHeight();
        final detailCardHeight = _showDetailCard ? 200.0 : 0.0;
        final calendarHeight = availableHeight - summaryHeight - detailCardHeight - 16; // padding
        
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              children: [
                // Riepilogo mensile con altezza fissa
                _buildCompactSummary(),
                
                // Calendario con altezza calcolata
                SizedBox(
                  height: calendarHeight.clamp(300.0, double.infinity),
                  child: CalendarWidget(
                    controller: _controller,
                    onDateSelected: (date) {
                      setState(() {
                        _showDetailCard = true;
                        _selectedDate = date;
                      });
                    },
                    onMonthChanged: (newMonth) {
                      setState(() {
                        _currentMonth = newMonth;
                      });
                    },
                  ),
                ),
                
                // Card dettaglio
                if (_showDetailCard && _selectedDate != null)
                  _buildDetailCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Layout per tablet (portrait)
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Sidebar con riepilogo
        SizedBox(
          width: 320,
          child: Column(
            children: [
              MonthlySummaryWidget(
                controller: _controller,
                currentMonth: _currentMonth,
              ),
              if (_showDetailCard && _selectedDate != null)
                Expanded(child: _buildDetailCard()),
            ],
          ),
        ),
        
        // Calendario principale
        Expanded(
          child: CalendarWidget(
            controller: _controller,
            onDateSelected: (date) {
              setState(() {
                _showDetailCard = true;
                _selectedDate = date;
              });
            },
            onMonthChanged: (newMonth) {
              setState(() {
                _currentMonth = newMonth;
              });
            },
          ),
        ),
      ],
    );
  }

  // Layout per landscape
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Pannello sinistro
        SizedBox(
          width: 350,
          child: Column(
            children: [
              MonthlySummaryWidget(
                controller: _controller,
                currentMonth: _currentMonth,
              ),
              if (_showDetailCard && _selectedDate != null)
                Expanded(child: _buildDetailCard()),
            ],
          ),
        ),
        
        const VerticalDivider(width: 1),
        
        // Calendario a schermo intero
        Expanded(
          child: CalendarWidget(
            controller: _controller,
            onDateSelected: (date) {
              setState(() {
                _showDetailCard = true;
                _selectedDate = date;
              });
            },
            onMonthChanged: (newMonth) {
              setState(() {
                _currentMonth = newMonth;
              });
            },
          ),
        ),
      ],
    );
  }

  // Versione compatta del riepilogo per mobile
  Widget _buildCompactSummary() {
    final totalKm = _controller.getTotalKilometersForMonth(_currentMonth.year, _currentMonth.month);
    final personalKm = _controller.getTotalKilometersForMonthAndCategory(
        _currentMonth.year, _currentMonth.month, KmCategory.personal);
    final workKm = _controller.getTotalKilometersForMonthAndCategory(
        _currentMonth.year, _currentMonth.month, KmCategory.work);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compatto
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_view_month,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMonthYearString(_currentMonth),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Riepilogo mensile',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalKm.toStringAsFixed(0)} km',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats compatte
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard('Personali', personalKm, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard('Lavoro', workKm, Colors.orange),
              ),
            ],
          ),
          
          // Progress bar solo se ci sono dati
          if (totalKm > 0) ...[
            const SizedBox(height: 12),
            _buildCompactProgressBar(personalKm, workKm, totalKm),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String label, double km, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${km.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProgressBar(double personalKm, double workKm, double totalKm) {
    final personalPercentage = personalKm / totalKm;
    final workPercentage = workKm / totalKm;
    
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              if (personalKm > 0)
                Expanded(
                  flex: (personalPercentage * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(2),
                        bottomLeft: Radius.circular(2),
                        topRight: workKm <= 0 ? Radius.circular(2) : Radius.zero,
                        bottomRight: workKm <= 0 ? Radius.circular(2) : Radius.zero,
                      ),
                    ),
                  ),
                ),
              if (workKm > 0)
                Expanded(
                  flex: (workPercentage * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                        topLeft: personalKm <= 0 ? Radius.circular(2) : Radius.zero,
                        bottomLeft: personalKm <= 0 ? Radius.circular(2) : Radius.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: KmDetailCard(
        controller: _controller,
        selectedDate: _selectedDate!,
        onClose: () {
          setState(() {
            _showDetailCard = false;
          });
        },
      ),
    );
  }

  double _calculateSummaryHeight() {
    final totalKm = _controller.getTotalKilometersForMonth(_currentMonth.year, _currentMonth.month);
    // Altezza base + progress bar se ci sono dati
    return totalKm > 0 ? 140.0 : 120.0;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // AppBar moderna e migliorata
  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Counter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Track your progress',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Statistiche rapide
        ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final monthlyTotal = _controller.getTotalKilometersForMonth(
              _currentMonth.year, 
              _currentMonth.month
            );
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${monthlyTotal.toStringAsFixed(0)}km',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Menu opzioni
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20,
            ),
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Text('Impostazioni'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Text('Esporta dati'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Text('Statistiche'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _handleMenuAction(value);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Gestione azioni del menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apertura impostazioni...')),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esportazione dati...')),
        );
        break;
      case 'stats':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apertura statistiche...')),
        );
        break;
    }
  }
}