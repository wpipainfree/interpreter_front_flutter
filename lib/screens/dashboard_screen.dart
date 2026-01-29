import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/psych_tests_service.dart';
import '../test_flow/test_flow_coordinator.dart';
import '../test_flow/test_flow_models.dart';
import '../router/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/auth_ui.dart';
import '../utils/main_shell_tab_controller.dart';
import '../widgets/app_error_view.dart';
import '../screens/payment/payment_webview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final PsychTestsService _testsService = PsychTestsService();
  final List<UserAccountItem> _accounts = [];
  bool _loading = true;
  bool _pendingIdeal = false;
  String? _error;
  static const int _maxRecent = 3;
  late final VoidCallback _authListener;
  late final VoidCallback _tabListener;
  bool _lastLoggedIn = false;
  String? _lastUserId;
  int _lastShellIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastLoggedIn = _authService.isLoggedIn;
    _lastUserId = _authService.currentUser?.id;
    _authListener = _handleAuthChanged;
    _authService.addListener(_authListener);
    _lastShellIndex = MainShellTabController.index.value;
    _tabListener = _handleShellTabChanged;
    MainShellTabController.index.addListener(_tabListener);
    _loadAccounts();
    _loadPendingIdeal();
  }

  @override
  void dispose() {
    _authService.removeListener(_authListener);
    MainShellTabController.index.removeListener(_tabListener);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (!mounted) return;
    final nowLoggedIn = _authService.isLoggedIn;
    final nowUserId = _authService.currentUser?.id;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (!nowLoggedIn) {
      setState(() {
        _accounts.clear();
        _loading = false;
        _error = '로그인이 필요합니다.';
      });
      return;
    }
    _loadAccounts();
  }

  void _handleShellTabChanged() {
    if (!mounted) return;
    final idx = MainShellTabController.index.value;
    if (idx == _lastShellIndex) return;
    _lastShellIndex = idx;
    if (idx != 0) return;
    _loadPendingIdeal();
    if (_authService.isLoggedIn) {
      _loadAccounts();
    }
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _loadAccounts();
    }
  }

  Future<void> _loadAccounts() async {
    final userId = (_authService.currentUser?.id ?? '').trim();
    if (userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = '로그인이 필요합니다.';
      });
      return;
    }
    try {
      final res = await _testsService.fetchUserAccounts(
        userId: userId,
        page: 1,
        pageSize: _maxRecent,
        fetchAll: false,
        testIds: const [1, 3],
      );
      if (!mounted) return;
      setState(() {
        _accounts
          ..clear()
          ..addAll(res.items);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadPendingIdeal() async {
    final pending = await TestFlowCoordinator.hasPendingIdeal();
    if (!mounted) return;
    setState(() => _pendingIdeal = pending);
  }

  /// 결제 처리
  Future<void> _handlePayment() async {
    // 1. 로그인 확인
    if (!_authService.isLoggedIn) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok || !mounted) return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    // 2. 결제 수단 및 검사 유형 선택 다이얼로그
    final paymentOptions = await _showPaymentMethodDialog();
    if (paymentOptions == null || !mounted) return;

    final paymentType = paymentOptions['paymentType'] as int;
    final testId = paymentOptions['testId'] as int;
    final testName = testId == 1 ? 'WPI 현실검사' : 'WPI 이상검사';

    // 3. 결제 생성
    try {
      final paymentService = PaymentService();
      final request = CreatePaymentRequest(
        userId: int.tryParse(user.id) ?? 0,
        amount: 1000, // WPI 검사 금액 (원)
        productName: testName,
        buyerName: user.displayName,
        buyerEmail: user.email.isNotEmpty ? user.email : 'user@wpiapp.com',
        buyerTel: '01000000000', // TODO: 사용자 전화번호 필드 추가 필요
        callbackUrl: 'wpiapp://payment/result',
        testId: testId,
        paymentType: paymentType,
      );

      // 로딩 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final payment = await paymentService.createPayment(request);

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
      }

      // 4. 결제 WebView 열기
      if (!mounted) return;
      final result = await PaymentWebViewScreen.open(
        context,
        webviewUrl: payment.webviewUrl,
        paymentId: payment.paymentId,
      );

      // 5. 결과 처리
      if (!mounted || result == null) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제가 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        // 결제 완료 후 계정 목록 새로고침
        await _loadAccounts();
      } else if (result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 결제 수단 및 검사 유형 선택 다이얼로그
  Future<Map<String, int>?> _showPaymentMethodDialog() async {
    int? selectedTestId = 1; // 기본값: WPI 현실검사
    int? selectedPaymentType;

    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('결제 옵션 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 검사 유형 선택 섹션
              const Text(
                '검사 유형',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text('검사를 선택하세요'),
                  value: selectedTestId,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('WPI 현실검사'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('WPI 이상검사'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedTestId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 결제 수단 선택 섹션
              const Text(
                '결제 수단',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('신용카드'),
                subtitle: const Text('신용/체크카드로 결제'),
                selected: selectedPaymentType == 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedPaymentType == 20
                        ? Colors.blue
                        : Colors.grey.shade300,
                  ),
                ),
                onTap: () {
                  setState(() {
                    selectedPaymentType = 20; // MOBILE_CARD
                  });
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.green),
                title: const Text('가상계좌'),
                subtitle: const Text('무통장 입금'),
                selected: selectedPaymentType == 22,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedPaymentType == 22
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
                ),
                onTap: () {
                  setState(() {
                    selectedPaymentType = 22; // MOBILE_VBANK
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: (selectedTestId != null && selectedPaymentType != null)
                  ? () => Navigator.pop(context, {
                        'testId': selectedTestId!,
                        'paymentType': selectedPaymentType!,
                      })
                  : null,
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildHeader(user),
          _buildStartTestSection(),
          _buildHistoryHeader(),
          _buildHistoryList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(UserInfo? user) {
    final name = (user?.displayName ?? '게스트').trim();

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 44,
      titleSpacing: 20,
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: ' 님 안녕하세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  SliverToBoxAdapter _buildStartTestSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.secondaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WPI 검사',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '약 10–15분 · 30문장 중 12개 선택',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textOnDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '현실과 이상을 함께 보면 ‘지금의 나’와 ‘바라는 변화 방향’을 한눈에 이해할 수 있어요.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDark.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.testNote,
                          arguments: const TestNoteArgs(
                            testId: 1,
                            testTitle: '현실 검사',
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.backgroundWhite,
                        foregroundColor: AppColors.secondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '검사 시작',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _handlePayment(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '결제',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_pendingIdeal) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final coordinator = TestFlowCoordinator();
                          await coordinator.startIdealOnly(context);
                          if (!mounted) return;
                          await _loadPendingIdeal();
                          await _loadAccounts();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textOnDark,
                          side: BorderSide(
                              color: AppColors.textOnDark.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('이상(변화 방향) 이어하기'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHistoryHeader() {
    final hasMore = _accounts.length >= _maxRecent;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최근 검사 기록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            hasMore
                ? TextButton(
                    onPressed: () {
                      MainShellTabController.index.value = 2;
                    },
                    child: const Text('더보기'),
                  )
                : Text(
                    '${_accounts.length}건',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      final loggedIn = _authService.isLoggedIn;
      return SliverToBoxAdapter(
        child: AppErrorView(
          title: loggedIn ? '불러오지 못했어요' : '로그인이 필요합니다',
          message: _error!,
          primaryActionLabel: loggedIn ? '다시 시도' : '로그인하기',
          primaryActionStyle: loggedIn
              ? AppErrorPrimaryActionStyle.outlined
              : AppErrorPrimaryActionStyle.filled,
          onPrimaryAction:
              loggedIn ? () => _loadAccounts() : () => _promptLoginAndReload(),
        ),
      );
    }
    if (_accounts.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _accounts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _AccountCard(
              item: item,
              onResumeComplete: _loadAccounts,
            ),
          );
        },
        childCount: _accounts.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '아직 검사 기록이 없어요.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 검사를 완료하면, 내 마음 구조 요약이 생깁니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.item,
    this.onResumeComplete,
  });

  final UserAccountItem item;
  final Future<void> Function()? onResumeComplete;

  bool get _canResumeOther {
    return item.status == '3' && item.resultId != null && item.testId != null;
  }

  WpiTestKind _kindForTest(int testId) {
    if (testId == 3) return WpiTestKind.ideal;
    return WpiTestKind.reality;
  }

  String _testTitleForFlow(int testId) {
    if (testId == 3) return 'WPI이상 검사';
    return 'WPI현실 검사';
  }

  Future<void> _resumeOther(BuildContext context) async {
    final testId = item.testId;
    final resultId = item.resultId;
    if (testId == null || resultId == null) return;

    await Navigator.of(context).pushNamed(
      AppRoutes.wpiSelectionFlow,
      arguments: WpiSelectionFlowArgs(
        testId: testId,
        testTitle: _testTitleForFlow(testId),
        kind: _kindForTest(testId),
        exitMode: FlowExitMode.openResultDetail,
        existingResultId: resultId,
        initialRole: EvaluationRole.other,
      ),
    );
    if (context.mounted) {
      await onResumeComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final date =
        _formatDateTime(item.createDate ?? item.paymentDate ?? item.modifyDate);
    final testName = _testName(item.testId);
    final tester = _tester(item);
    final selfType = _resultType(item, key: 'self') ?? _resultType(item);
    final rawOtherType = _resultType(item, key: 'other');
    final otherType =
        rawOtherType != null && rawOtherType != selfType ? rawOtherType : null;
    final statusText = _statusLabel(item.status);
    final statusColor = _statusColor(item.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _canResumeOther
            ? () => _resumeOther(context)
            : (item.resultId != null
                ? () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.userResultDetail,
                      arguments: UserResultDetailArgs(
                        resultId: item.resultId!,
                        testId: item.testId,
                      ),
                    );
                  }
                : null),
        borderRadius: BorderRadius.circular(18),
        mouseCursor: item.resultId != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (tester.isNotEmpty && tester != '미입력')
                          Flexible(
                            child: Text(
                              '검사자 $tester',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (tester.isNotEmpty && tester != '미입력') ...[
                          const SizedBox(width: 6),
                          Text(
                            '·',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          date,
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (selfType != null) _pill(selfType),
                        if (otherType != null) _pill(otherType),
                        if (statusText != null)
                          _statusPill(statusText, statusColor),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _testName(int? testId) {
    if (testId == 1) return 'WPI(현실)';
    if (testId == 3) return 'WPI(이상)';
    return 'WPI';
  }

  String _tester(UserAccountItem item) {
    final name = item.result?['TEST_TARGET_NAME'] ?? '';
    return name is String && name.isNotEmpty ? name : '미입력';
  }

  String? _resultType(UserAccountItem item, {String key = 'DESCRIPTION'}) {
    final byKey = item.result?[key];
    if (byKey is String && byKey.isNotEmpty) return byKey;
    final desc = item.result?['DESCRIPTION'] ?? item.result?['description'];
    if (desc is String && desc.isNotEmpty) return desc;
    final existence = item.result?['existence_type'] ?? item.result?['title'];
    if (existence is String && existence.isNotEmpty) return existence;
    return null;
  }

  String? _statusLabel(String? status) {
    if (status == '4') return '완료';
    if (status == '3') return '이어하기';
    return null;
  }

  Color _statusColor(String? status) {
    if (status == '4') return AppColors.success;
    if (status == '3') return AppColors.warning;
    return AppColors.textSecondary;
  }

  Widget _pill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        value,
        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
