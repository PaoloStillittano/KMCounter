// widgets/monthly_summary_compact.dart
import 'package:flutter/material.dart';
import 'package:counter/models/km_entry.dart';
import 'package:provider/provider.dart';
import 'package:counter/controllers/km_controller.dart';
import '../utils/date_utils.dart' as my_date_utils;

class MonthlySummaryCompact extends StatelessWidget {
  final DateTime currentMonth;

  const MonthlySummaryCompact({
    super.key,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<KmController>(
      builder: (context, controller, child) {
        final totalKm = controller.getTotalKilometersForMonth(
          currentMonth.year,
          currentMonth.month,
        );
        final personalKm = controller.getTotalKilometersForMonthAndCategory(
          currentMonth.year,
          currentMonth.month,
          KmCategory.personal,
        );
        final workKm = controller.getTotalKilometersForMonthAndCategory(
          currentMonth.year,
          currentMonth.month,
          KmCategory.work,
        );

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
                color: Colors.black.withAlpha(35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(context, totalKm),
              const SizedBox(height: 12),
              _buildStatsRow(personalKm, workKm),
              if (totalKm > 0) ...[
                const SizedBox(height: 12),
                _buildProgressBar(personalKm, workKm, totalKm),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double totalKm) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withAlpha(120),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
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
                my_date_utils.DateUtils.getMonthYearString(currentMonth),
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
            color: Theme.of(context).primaryColor.withAlpha(70),
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
    );
  }

  Widget _buildStatsRow(double personalKm, double workKm) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Personali',
            km: personalKm,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Lavoro',
            km: workKm,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double personalKm, double workKm, double totalKm) {
    final personalPercentage = personalKm / totalKm;
    final workPercentage = workKm / totalKm;

    return Container(
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
                    topLeft: const Radius.circular(2),
                    bottomLeft: const Radius.circular(2),
                    topRight:
                        workKm <= 0 ? const Radius.circular(2) : Radius.zero,
                    bottomRight:
                        workKm <= 0 ? const Radius.circular(2) : Radius.zero,
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
                    topRight: const Radius.circular(2),
                    bottomRight: const Radius.circular(2),
                    topLeft: personalKm <= 0
                        ? const Radius.circular(2)
                        : Radius.zero,
                    bottomLeft: personalKm <= 0
                        ? const Radius.circular(2)
                        : Radius.zero,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double km;
  final Color color;

  const _StatCard({
    required this.label,
    required this.km,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
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
}
