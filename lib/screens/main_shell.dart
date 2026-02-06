import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_navigator.dart';
import '../utils/auth_ui.dart';
import '../utils/main_shell_tab_controller.dart';
import '../widgets/atom_icon.dart';
import 'dashboard_screen.dart';
import 'test/test_intro_screen.dart';
import 'mymind/my_mind_page.dart';
import 'profile/my_page_screen.dart';
import 'payment/payment_webview_screen.dart';

/// Main shell with 4-tab bottom navigation: Home, Test, MyMind, MyPage.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with RouteAware {
  final AuthService _authService = AuthService();
  late final VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialIndex.clamp(0, 3);
    if (MainShellTabController.index.value != initialIndex) {
      MainShellTabController.index.value = initialIndex;
    }
    _authListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _authService.addListener(_authListener);

    // 결제 결과 노티파이어 리스닝
    PaymentResult.notifier.addListener(_onPaymentResultChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppNavigator.routeObserver.subscribe(this, route);
    }
  }

  void _onPaymentResultChanged() {
    // 먼저 값 확인 - null이면 바로 리턴 (consume()이 트리거한 경우)
    final result = PaymentResult.notifier.value;
    if (result == null) return;

    debugPrint('[MainShell] _onPaymentResultChanged: result=$result, mounted=$mounted');
    if (!mounted) return;

    // 값을 저장하고 notifier 초기화 (이 때 listener가 다시 트리거되지만 null이므로 위에서 리턴)
    PaymentResult.notifier.value = null;

    // 바로 SnackBar 표시
    debugPrint('[MainShell] Showing SnackBar for payment result');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? '결제가 완료되었습니다.' : (result.message ?? '결제에 실패했습니다.')),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    AppNavigator.routeObserver.unsubscribe(this);
    _authService.removeListener(_authListener);
    PaymentResult.notifier.removeListener(_onPaymentResultChanged);
    super.dispose();
  }

  @override
  void didPopNext() {
    MainShellTabController.bumpRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(),
      TestIntroScreen(),
      MyMindPage(),
      MyPageScreen(),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: MainShellTabController.index,
      builder: (context, value, _) {
        final index = value.clamp(0, 3);
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: _onTabSelected,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: '검사',
              ),
              BottomNavigationBarItem(
                icon: const AtomIcon(size: 26),
                label: '내 마음',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: '마이',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onTabSelected(int i) async {
    // Gate MyPage behind login; keep other tabs free.
    if (i == 3 && !_authService.isLoggedIn) {
      final ok = await AuthUi.promptLogin(context: context);
      if (ok && mounted) {
        MainShellTabController.index.value = 3;
      }
      return;
    }
    MainShellTabController.index.value = i;
  }
}
