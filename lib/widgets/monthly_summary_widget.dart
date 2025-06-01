// widgets/monthly_summary_widget.dart
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';

class MonthlySummaryWidget extends StatelessWidget {
  final KmController controller;
  final DateTime currentMonth; // Aggiunto per sincronizzazione
  
  const MonthlySummaryWidget({
    super.key,
    required this.controller,
    required this.currentMonth, // Ricevuto dal calendario
  });

  @override
  Widget build(BuildContext context) {
    final totalKm = controller.getTotalKilometersForMonth(currentMonth.year, currentMonth.month);
    final personalKm = controller.getTotalKilometersForMonthAndCategory(
        currentMonth.year, currentMonth.month, KmCategory.personal);
    final workKm = controller.getTotalKilometersForMonthAndCategory(
        currentMonth.year, currentMonth.month, KmCategory.work);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icona e titolo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_view_month,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riepilogo Mensile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        _getMonthYearString(currentMonth),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge con totale
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${totalKm.toStringAsFixed(0)} km',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Cards statistiche
            Row(
              children: [
                Expanded(
                  child: _buildModernSummaryCard(
                    context,
                    'Totale',
                    totalKm,
                    Colors.blue,
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernSummaryCard(
                    context,
                    'Personali',
                    personalKm,
                    Colors.green,
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernSummaryCard(
                    context,
                    'Lavoro',
                    workKm,
                    Colors.orange,
                    Icons.work,
                  ),
                ),
              ],
            ),
            
            // Progress bar se ci sono dati
            if (totalKm > 0) ...[
              const SizedBox(height: 20),
              _buildProgressBar(context, personalKm, workKm, totalKm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernSummaryCard(
    BuildContext context,
    String label,
    double km,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${km.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'km',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double personalKm, double workKm, double totalKm) {
    final personalPercentage = personalKm / totalKm;
    final workPercentage = workKm / totalKm;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Distribuzione',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${((personalPercentage + workPercentage) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
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
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                        topRight: workKm <= 0 ? Radius.circular(4) : Radius.zero,
                        bottomRight: workKm <= 0 ? Radius.circular(4) : Radius.zero,
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
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                        topLeft: personalKm <= 0 ? Radius.circular(4) : Radius.zero,
                        bottomLeft: personalKm <= 0 ? Radius.circular(4) : Radius.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (personalKm > 0) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Personali (${(personalPercentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (workKm > 0) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Lavoro (${(workPercentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}