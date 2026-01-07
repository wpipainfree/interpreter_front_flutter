import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          const BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: '검사'),
          BottomNavigationBarItem(
            icon: _AtomIcon(size: 26),
            label: '내 마음',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: '마이'),
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

class _AtomIcon extends StatelessWidget {
  const _AtomIcon({this.size = 24});

  final double size;

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="2.5" fill="currentColor"/>
  
  <ellipse cx="12" cy="12" rx="3.5" ry="10" fill="none" stroke="currentColor" stroke-width="1.5" transform="rotate(30 12 12)"/>
  <ellipse cx="12" cy="12" rx="3.5" ry="10" fill="none" stroke="currentColor" stroke-width="1.5" transform="rotate(-30 12 12)"/>
  <ellipse cx="12" cy="12" rx="10" ry="3.5" fill="none" stroke="currentColor" stroke-width="1.5"/>
  
  <circle cx="12" cy="2" r="1.5" fill="currentColor" transform="rotate(30 12 2)"/>
  <circle cx="20.66" cy="17" r="1.5" fill="currentColor" transform="rotate(-30 20.66 17)"/>
  <circle cx="3.34" cy="17" r="1.5" fill="currentColor"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final color = iconTheme.color;
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}
