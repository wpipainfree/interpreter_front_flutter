import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'utils/app_navigator.dart';
import 'utils/auth_ui.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 알림 서비스 초기화
  await NotificationService().initialize();
  await AuthService().restoreSession();

  runApp(const WpiApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService().handlePendingNavigation();
  });
}

class WpiApp extends StatefulWidget {
  const WpiApp({super.key});

  @override
  State<WpiApp> createState() => _WpiAppState();
}

class _WpiAppState extends State<WpiApp> {
  final AuthService _authService = AuthService();
  late final VoidCallback _authListener;
  bool _lastLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _lastLoggedIn = _authService.isLoggedIn;
    _authListener = _handleAuthChanged;
    _authService.addListener(_authListener);
  }

  @override
  void dispose() {
    _authService.removeListener(_authListener);
    super.dispose();
  }

  void _handleAuthChanged() {
    final nowLoggedIn = _authService.isLoggedIn;

    if (_lastLoggedIn && !nowLoggedIn) {
      if (_authService.lastLogoutReason == LogoutReason.sessionExpired) {
        AuthUi.promptLogin();
      }
    }

    _lastLoggedIn = nowLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WPI 구조',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const SplashScreen(),
    );
  }
}
