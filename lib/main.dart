import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 알림 서비스 초기화
  await NotificationService().initialize();
  
  runApp(const WpiApp());
}

class WpiApp extends StatelessWidget {
  const WpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WPI 마음읽기',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
