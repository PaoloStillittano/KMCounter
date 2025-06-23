import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';

class ThemeSwitchWidget extends StatelessWidget {
  final bool showLabel;
  final String? lightLabel;
  final String? darkLabel;
  
  const ThemeSwitchWidget({
    super.key,
    this.showLabel = true,
    this.lightLabel = 'Tema chiaro',
    this.darkLabel = 'Tema scuro',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        final isDark = themeController.isDarkMode(context);
        
        if (showLabel) {
          return ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(isDark ? darkLabel! : lightLabel!),
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                themeController.toggleTheme();
              },
            ),
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Switch(
                value: isDark,
                onChanged: (value) {
                  themeController.toggleTheme();
                },
              ),
            ],
          );
        }
      },
    );
  }
}

// Variante con IconButton per la AppBar
class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        final isDark = themeController.isDarkMode(context);
        
        return IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white.withAlpha(250),
          ),
          onPressed: () {
            themeController.toggleTheme();
          },
          tooltip: isDark ? 'Passa al tema chiaro' : 'Passa al tema scuro',
        );
      },
    );
  }
}

// Variante con BottomSheet per scegliere tra tutte le opzioni
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Automatico (Sistema)'),
              trailing: themeController.themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeController.setSystemMode();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Tema chiaro'),
              trailing: themeController.themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeController.setLightMode();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Tema scuro'),
              trailing: themeController.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeController.setDarkMode();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Metodo statico per mostrare il selector
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ThemeSelector(),
    );
  }
}