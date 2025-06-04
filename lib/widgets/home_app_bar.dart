// widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import '../controllers/km_controller.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final KmController controller;
  final DateTime currentMonth;

  const HomeAppBar({
    super.key,
    required this.controller,
    required this.currentMonth,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
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
      title: _buildTitle(),
      actions: [
        _buildMonthlyStats(context),
        _buildMenuButton(context),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
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
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyStats(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final monthlyTotal = controller.getTotalKilometersForMonth(
          currentMonth.year, 
          currentMonth.month,
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
              const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${monthlyTotal.toStringAsFixed(0)}km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
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
        _buildMenuItem(Icons.settings, 'Impostazioni', 'settings'),
        _buildMenuItem(Icons.download, 'Esporta dati', 'export'),
        _buildMenuItem(Icons.bar_chart, 'Statistiche', 'stats'),
      ],
      onSelected: (value) => _handleMenuAction(context, value),
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final messages = {
      'settings': 'Apertura impostazioni...',
      'export': 'Esportazione dati...',
      'stats': 'Apertura statistiche...',
    };

    final message = messages[action] ?? 'Azione non riconosciuta';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}