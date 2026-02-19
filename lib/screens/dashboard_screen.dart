import 'package:flutter/material.dart';
import '../app/di/app_scope.dart';
import '../domain/model/dashboard_models.dart';
import '../test_flow/test_flow_coordinator.dart';
import '../test_flow/test_flow_models.dart';
import '../ui/dashboard/dashboard_view_model.dart';
import '../router/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/auth_ui.dart';
import '../utils/main_shell_tab_controller.dart';
import '../utils/strings.dart';
import '../widgets/app_error_view.dart';
import '../screens/payment/payment_webview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardViewModel _viewModel =
      DashboardViewModel(AppScope.instance.dashboardRepository);
  late final VoidCallback _tabListener;
  late final VoidCallback _refreshListener;
  int _lastShellIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_handleViewModelChanged);
    _lastShellIndex = MainShellTabController.index.value;
    _tabListener = _handleShellTabChanged;
    MainShellTabController.index.addListener(_tabListener);
    _refreshListener = _handleRefresh;
    MainShellTabController.refreshTick.addListener(_refreshListener);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    MainShellTabController.index.removeListener(_tabListener);
    MainShellTabController.refreshTick.removeListener(_refreshListener);
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleShellTabChanged() {
    if (!mounted) return;
    final idx = MainShellTabController.index.value;
    if (idx == _lastShellIndex) return;
    _lastShellIndex = idx;
    if (idx != 0) return;
    _viewModel.loadPendingIdeal();
    if (_viewModel.isLoggedIn) {
      _viewModel.loadAccounts();
      _viewModel.loadRecords();
    }
  }

  void _handleRefresh() {
    if (!mounted) return;
    if (MainShellTabController.index.value != 0) return;
    _viewModel.loadPendingIdeal();
    if (_viewModel.isLoggedIn) {
      _viewModel.loadAccounts();
      _viewModel.loadRecords();
    }
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _viewModel.reloadAfterLogin();
    }
  }

  /// 결제 처리
  Future<void> _handlePayment() async {
    // 1. 로그인 확인
    if (!_viewModel.isLoggedIn) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok || !mounted) return;
    }

    final user = _viewModel.currentUser;
    if (user == null) return;

    // 2. 결제 수단 및 검사 유형 선택 다이얼로그
    final paymentOptions = await _showPaymentMethodDialog();
    if (paymentOptions == null || !mounted) return;

    final paymentType = paymentOptions['paymentType'] as int;
    final testId = paymentOptions['testId'] as int;
    final testName = testId == 1 ? 'WPI 현실검사' : 'WPI 이상검사';

    // 3. 결제 생성
    try {
      // 로딩 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final payment = await _viewModel.createPayment(
        userId: int.tryParse(user.id) ?? 0,
        testId: testId,
        paymentType: paymentType,
        productName: testName,
        buyerName: user.displayName,
        buyerEmail: user.email.isNotEmpty ? user.email : 'user@wpiapp.com',
      );

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
      }

      // 4. 결제 WebView 열기
      if (!mounted) return;
      final paymentId = int.tryParse(payment.paymentId);
      if (paymentId == null) {
        throw FormatException('Invalid payment id format: ${payment.paymentId}');
      }
      final result = await PaymentWebViewScreen.open(
        context,
        webviewUrl: payment.webviewUrl,
        paymentId: paymentId,
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
        await _viewModel.loadAccounts();
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
    final user = _viewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildHeader(user),
          _buildTodayMindReadSection(),
          _buildStartTestSection(),
          _buildRecordHeader(),
          _buildRecordList(),
          _buildHistoryHeader(),
          _buildHistoryList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(DashboardUser? user) {
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
                    if (_viewModel.pendingIdeal) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final coordinator = TestFlowCoordinator();
                          await coordinator.startIdealOnly(context);
                          if (!mounted) return;
                          await _viewModel.loadPendingIdeal();
                          await _viewModel.loadAccounts();
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
                        child: const Text('WPI 이상 검사 이어하기'),
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

  SliverToBoxAdapter _buildTodayMindReadSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 내 마음 읽기',
                      style: AppTextStyles.h5.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '사연을 적고, 현실/이상 프로파일을 선택해 해석을 확인하세요.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.todayMindRead);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('시작하기'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHistoryHeader() {
    final hasMore = _viewModel.accounts.length >= DashboardViewModel.maxRecent;
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
                    '${_viewModel.accounts.length}건',
                    style: const TextStyle(
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
    if (_viewModel.accountsLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_viewModel.accountsError != null) {
      final loggedIn = _viewModel.isLoggedIn;
      return SliverToBoxAdapter(
        child: AppErrorView(
          title: loggedIn ? '불러오지 못했어요' : '로그인이 필요합니다',
          message: _viewModel.accountsError!,
          primaryActionLabel: loggedIn ? '다시 시도' : '로그인하기',
          primaryActionStyle: loggedIn
              ? AppErrorPrimaryActionStyle.outlined
              : AppErrorPrimaryActionStyle.filled,
          onPrimaryAction: loggedIn
              ? () => _viewModel.loadAccounts()
              : () => _promptLoginAndReload(),
        ),
      );
    }
    if (_viewModel.accounts.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _viewModel.accounts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _AccountCard(
              item: item,
              onResumeComplete: _viewModel.loadAccounts,
            ),
          );
        },
        childCount: _viewModel.accounts.length,
      ),
    );
  }

  SliverToBoxAdapter _buildRecordHeader() {
    final loggedIn = _viewModel.isLoggedIn;
    // 로그인이 안 된 상태에서는 이 섹션을 숨김 (최근 검사 기록에서 로그인 메시지 표시)
    if (!loggedIn) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final hasMore = _viewModel.recordsHasMore;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최근 질문 기록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (hasMore)
              TextButton(
                onPressed: () {
                  MainShellTabController.index.value = 2;
                },
                child: const Text(AppStrings.seeMore),
              )
            else
              Text(
                '${_viewModel.records.length}건',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    // 로그인이 안 된 상태에서는 이 섹션을 숨김
    if (!_viewModel.isLoggedIn) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (_viewModel.recordsLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_viewModel.recordsError != null) {
      return SliverToBoxAdapter(
        child: AppErrorView(
          title: '불러오지 못했어요',
          message: _viewModel.recordsError!,
          primaryActionLabel: AppStrings.retry,
          primaryActionStyle: AppErrorPrimaryActionStyle.outlined,
          onPrimaryAction: () => _viewModel.loadRecords(),
        ),
      );
    }
    if (_viewModel.records.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildRecordEmptyState(),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _viewModel.records[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _RecordCard(item: item),
          );
        },
        childCount: _viewModel.records.length,
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

  Widget _buildRecordEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.recordEmptyTitle, style: AppTextStyles.h5),
          const SizedBox(height: 6),
          Text(
            AppStrings.recordEmptySubtitle,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
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

  final DashboardAccount item;
  final Future<void> Function()? onResumeComplete;

  /// resultId를 가져옵니다. item.resultId가 null이면 result 객체에서 ID를 추출합니다.
  int? get _effectiveResultId {
    if (item.resultId != null) return item.resultId;
    // result 객체에서 ID 추출 시도
    final resultData = item.result;
    if (resultData == null) return null;
    final id = resultData['ID'] ?? resultData['id'] ?? resultData['result_id'];
    if (id is int && id > 0) return id;
    if (id is String) {
      final parsed = int.tryParse(id);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  bool get _canResumeOther {
    return item.status == '3' &&
        _effectiveResultId != null &&
        item.testId != null;
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
    final resultId = _effectiveResultId;
    if (testId == null || resultId == null) return;

    await Navigator.of(context).pushNamed(
      AppRoutes.wpiSelectionFlow,
      arguments: WpiSelectionFlowArgs(
        testId: testId,
        testTitle: _testTitleForFlow(testId),
        kind: _kindForTest(testId),
        exitMode: FlowExitMode.openResultDetail,
        existingResultId: resultId,
        initialRole: WpiEvaluationRole.other,
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
            : () {
                final resultId = _effectiveResultId;
                if (resultId != null) {
                  Navigator.of(context).pushNamed(
                    AppRoutes.userResultSingle,
                    arguments: UserResultDetailArgs(
                      resultId: resultId,
                      testId: item.testId,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('검사 결과가 아직 준비되지 않았습니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(18),
        mouseCursor: SystemMouseCursors.click,
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

  String _tester(DashboardAccount item) {
    final name = item.result?['TEST_TARGET_NAME'] ?? '';
    return name is String && name.isNotEmpty ? name : '미입력';
  }

  String? _resultType(DashboardAccount item, {String key = 'DESCRIPTION'}) {
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.item});

  final DashboardRecordSummary item;

  @override
  Widget build(BuildContext context) {
    final displayTitle = item.displayTitle;
    final rawTitle = item.title.trim();
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.interpretationRecordDetail,
          arguments: InterpretationRecordDetailArgs(
            conversationId: item.id,
            title: rawTitle,
          ),
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              item.dateRangeLabel,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '\uba54\uc2dc\uc9c0 ${item.totalMessages}\uac1c',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
