import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';
import '../models/km_entry.dart';

class MonthlySummaryWidget extends StatelessWidget {
  final KmController controller;

  const MonthlySummaryWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalKm = controller.getTotalKilometersForMonth(now.year, now.month);
    final personalKm = controller.getTotalKilometersForMonthAndCategory(
        now.year, now.month, KmCategory.personal);
    final workKm = controller.getTotalKilometersForMonthAndCategory(
        now.year, now.month, KmCategory.work);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riepilogo mese di ${now.month}/${now.year}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Totale',
                totalKm,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Personali',
                personalKm,
                Colors.green,
              ),
              _buildSummaryCard(
                'Lavoro',
                workKm,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double km, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${km.toStringAsFixed(0)} km',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}