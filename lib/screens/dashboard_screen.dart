import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/psych_tests_service.dart';
import '../test_flow/test_flow_coordinator.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'auth/login_screen.dart';
import 'test/test_intro_screen.dart';
import 'mymind/my_mind_page.dart';
import '../screens/result/user_result_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadPendingIdeal();
  }

  Future<void> _loadAccounts() async {
    final userId = int.tryParse(_authService.currentUser?.id ?? '');
    if (userId == null) {
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          _buildStartTestSection(),
          _buildHistoryHeader(),
          _buildHistoryList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(UserInfo? user) {
    const double expandedHeight = 200;
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double delta = expandedHeight - kToolbarHeight;
          final double t = ((constraints.maxHeight - kToolbarHeight) /
                  (delta <= 0 ? 1 : delta))
              .clamp(0.0, 1.0);
          final bool showTitle = t < 0.4;
          final bool showContent = t > 0.65;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                ),
                child: showContent
                    ? SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '오늘의 구조 상태',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textOnDark.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.displayName ?? '게스트',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '당신의 이야기를 더 선명하게 보기 위한 인사이트를 준비했어요.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textOnDark.withOpacity(0.9),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: showTitle ? 1 : 0,
                  child: const Text(
                    '홈',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
                      '약 10–15분 · 나를 표현하는 30문장 중 12개 선택',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textOnDark.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_authService.isLoggedIn) {
                          final ok =
                              await Navigator.of(context, rootNavigator: true)
                                  .push<bool>(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                          if (ok != true || !mounted) return;
                        }
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TestIntroScreen()),
                        );
                        if (!mounted) return;
                        await _loadPendingIdeal();
                        await _loadAccounts();
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
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
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
                          side: BorderSide(color: AppColors.textOnDark.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('이상 검사 이어하기'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.textOnDark.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: AppColors.textOnDark,
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
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const MyMindPage()));
                    },
                    style: TextButton.styleFrom(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: const Text('더보기'),
                  )
                : Text(
                    '${_accounts.length}건',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadAccounts,
                style: ElevatedButton.styleFrom(
                    splashFactory: NoSplash.splashFactory),
                child: const Text('다시 시도'),
              ),
            ],
          ),
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
            child: _AccountCard(item: item),
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
            '첫 검사를 완료하고 기록을 쌓아보세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.item});

  final UserAccountItem item;

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
        onTap: item.resultId != null
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserResultDetailScreen(
                      resultId: item.resultId!,
                      testId: item.testId,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.psychology_alt_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (tester.isNotEmpty && tester != '미입력') ...[
                          const SizedBox(width: 6),
                          Text('·',
                              style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          date,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
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
                color: AppColors.textSecondary,
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
    if (status == '3') return '진행중';
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
