import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const KmCounterApp());
}

class KmCounterApp extends StatelessWidget {
  const KmCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}