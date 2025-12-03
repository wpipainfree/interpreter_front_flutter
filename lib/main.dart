import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const WpiApp());
}

class WpiApp extends StatelessWidget {
  const WpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WPI 마음읽기',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C81),
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
