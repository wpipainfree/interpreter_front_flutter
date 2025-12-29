import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'test/test_intro_screen.dart';
import 'mymind/my_mind_page.dart';
import 'profile/my_page_screen.dart';

/// Main shell with 4-tab bottom navigation: Home, Test, MyMind, MyPage.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      const TestIntroScreen(),
      const MyMindPage(),
      const MyPageScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabSelected,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: '검사'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: '내 마음'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: '마이'),
        ],
      ),
    );
  }

  Future<void> _onTabSelected(int i) async {
    // Gate MyPage behind login; keep other tabs free.
    if (i == 3 && !_authService.isLoggedIn) {
      final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const LoginScreen(),
        ),
      );
      if (ok == true && mounted) {
        setState(() => _index = 3);
      }
      return;
    }
    setState(() => _index = i);
  }
}
