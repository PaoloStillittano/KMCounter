import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/km_controller.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_themes.dart';
import 'pages/home_page.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  // Initialize Hive database
  await DatabaseService.initialize();
 
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeController _themeController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    _themeController = ThemeController();
    await _themeController.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => KmController()),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Contatore Km',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeController.themeMode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}