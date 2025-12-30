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
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20ZM12 7C9.24 7 7 9.24 7 12C7 14.76 9.24 17 12 17C14.76 17 17 14.76 17 12C17 9.24 14.76 7 12 7ZM12 15C10.34 15 9 13.66 9 12C9 10.34 10.34 9 12 9C13.66 9 15 10.34 15 12C15 13.66 13.66 15 12 15Z" fill="currentColor"/>
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
