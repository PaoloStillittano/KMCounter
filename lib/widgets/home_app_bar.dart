// widgets/home_app_bar.dart
import 'package:counter/widgets/theme_switch_widget.dart';
import '../controllers/km_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/export_service.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime currentMonth;

  const HomeAppBar({
    super.key,
    required this.currentMonth,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha(204),
            ],
          ),
        ),
      ),
      title: _buildTitle(),
      actions: [
        const ThemeToggleIconButton(),
        _buildMenuButton(context),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Counter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Traccia il tuo progresso',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(5),
        child: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 55),
      constraints: const BoxConstraints(
        minWidth: 200,
      ),
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          Icons.bar_chart_rounded,
          'Statistiche',
          'stats',
          'Visualizza grafici e analisi',
          Colors.blue,
        ),
        _buildDivider(),
        _buildMenuItem(
          context,
          Icons.file_download_rounded,
          'Esporta dati',
          'export',
          'Salva i tuoi dati',
          Colors.green,
        ),
        _buildDivider(),
        _buildMenuItem(
          context,
          Icons.settings_rounded,
          'Impostazioni',
          'settings',
          'Personalizza l\'app',
          Colors.orange,
        ),
        _buildDivider(),
        _buildMenuItem(
          context,
          Icons.info_outline_rounded,
          'Info',
          'info',
          'Versione e supporto',
          Colors.grey,
        ),
      ],
      onSelected: (value) => _handleMenuAction(context, value),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context,
    IconData icon, 
    String title, 
    String value,
    String subtitle,
    Color iconColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon, 
              size: 20, 
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildDivider() {
    return PopupMenuItem(
      enabled: false,
      height: 1,
      child: Container(
        height: 1,
        color: Colors.grey[200],
        margin: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    HapticFeedback.lightImpact();
    final kmController = context.read<KmController>();
    final messages = {
      'settings': 'Apertura impostazioni...',
      'export': 'Esportazione dati in corso...',
      'stats': 'Caricamento statistiche...',
      'info': 'Informazioni sull\'app',
    };

    final icons = {
      'settings': Icons.settings_rounded,
      'export': Icons.file_download_rounded,
      'stats': Icons.bar_chart_rounded,
      'info': Icons.info_outline_rounded,
    };

    final message = messages[action] ?? 'Azione non riconosciuta';
    final icon = icons[action] ?? Icons.error_outline;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    
    switch (action) {
      case 'settings':
        _navigateToSettings(context);
        break;
      case 'export':
        _exportData(context, kmController);
        break;
      case 'stats':
        _navigateToStats(context);
        break;
      case 'info':
        _showInfoDialog(context);
        break;
    }
  }

  void _navigateToSettings(BuildContext context) {
    // Navigator.pushNamed(context, '/settings');
  }

  void _exportData(BuildContext context, KmController controller) {
    ExportService.exportMonthlyDataToExcel(
      context: context,
      entries: controller.entries,
      year: currentMonth.year,
      month: currentMonth.month,
    );
  }

  void _navigateToStats(BuildContext context) {
    // Navigator.pushNamed(context, '/statistics');
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Informazioni App'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Counter v1.0.0'),
            SizedBox(height: 8),
            Text('Traccia i tuoi chilometri giornalieri con facilità.'),
            SizedBox(height: 16),
            Text('Sviluppato con ❤️ per il tuo benessere'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}