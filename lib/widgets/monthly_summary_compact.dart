// widgets/monthly_summary_compact.dart
import 'package:flutter/material.dart';
import '../models/km_entry.dart';
import 'package:provider/provider.dart';
import '../controllers/km_controller.dart';
import '../utils/date_utils.dart' as my_date_utils;
import '../utils/app_themes.dart';

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

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withAlpha(20)
                : Colors.white70,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(38)
                  : Colors.black.withAlpha(38),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, totalKm),
              const SizedBox(height: 12),
              _buildStatsRow(personalKm, workKm),
              if (totalKm > 0) ...[
                const SizedBox(height: 12),
                _buildProgressBar(context, personalKm, workKm, totalKm),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double totalKm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(38): Colors.blue.withAlpha(115),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_view_month,
            color: isDark ? Colors.white: Colors.black.withAlpha(200),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Riepilogo mensile',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(153), 
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(38)
                : Colors.blue.withAlpha(115),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${totalKm.toStringAsFixed(0)} km',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
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
            color: AppThemes.personalKmColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Lavoro',
            km: workKm,
            color: AppThemes.workKmColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double personalKm, double workKm, double totalKm) {
    final personalPercentage = personalKm / totalKm;
    final workPercentage = workKm / totalKm;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withAlpha(80),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          if (personalKm > 0)
            Expanded(
              flex: (personalPercentage * 100).round(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemes.personalKmColor,
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
                  color: AppThemes.workKmColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? color.withAlpha(50) 
            : color.withAlpha(45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
              ? color.withAlpha(120) 
              : color.withAlpha(80),
        ),
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
                    color: theme.colorScheme.onSurface, 
                  ),
                ),
                Text(
                  '${km.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark 
                        ? color.withAlpha(220) 
                        : color,
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