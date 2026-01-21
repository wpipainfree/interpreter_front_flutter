import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/main_shell_tab_controller.dart';
import '../../utils/strings.dart';
import '../result/user_result_detail_screen.dart';
import 'interpretation_panel.dart';
import 'interpretation_record_panel.dart';

/// MyMind main page: results / saved / records / interpretation.
class MyMindPage extends StatefulWidget {
  const MyMindPage({super.key});

  @override
  State<MyMindPage> createState() => _MyMindPageState();
}

class _MyMindPageState extends State<MyMindPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('내 마음', style: AppTextStyles.h4),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSegments(),
          const SizedBox(height: 12),
          Expanded(child: _buildPanel()),
        ],
      ),
    );
  }

  Widget _buildSegments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _segButton('결과', 0),
            _segButton('보관함', 1),
            _segButton('기록', 2),
            _segButton('해석', 3),
          ],
        ),
      ),
    );
  }

  Widget _segButton(String label, int idx) {
    final selected = _tab == idx;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _tab = idx),
        style: TextButton.styleFrom(
          foregroundColor:
              selected ? AppColors.primary : AppColors.textSecondary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    switch (_tab) {
      case 0:
        return const _ResultPanel();
      case 1:
        return const _SavedPanel();
      case 2:
        return const _RecordPanel();
      default:
        return const InterpretationPanel();
    }
  }
}

class _ResultPanel extends StatefulWidget {
  const _ResultPanel();

  @override
  State<_ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<_ResultPanel> {
  final PsychTestsService _service = PsychTestsService();
  final AuthService _auth = AuthService();
  final ScrollController _scrollController = ScrollController();
  late final VoidCallback _authListener;
  late final VoidCallback _shellTabListener;
  bool _lastLoggedIn = false;
  String? _lastUserId;
  int _lastShellIndex = 0;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = true;
  int _page = 1;
  String? _error;
  final List<UserAccountItem> _items = [];

  @override
  void initState() {
    super.initState();
    _lastLoggedIn = _auth.isLoggedIn;
    _lastUserId = _auth.currentUser?.id;
    _authListener = _handleAuthChanged;
    _auth.addListener(_authListener);
    _lastShellIndex = MainShellTabController.index.value;
    _shellTabListener = _handleShellTabChanged;
    MainShellTabController.index.addListener(_shellTabListener);
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _auth.removeListener(_authListener);
    MainShellTabController.index.removeListener(_shellTabListener);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAuthChanged() {
    if (!mounted) return;
    final nowLoggedIn = _auth.isLoggedIn;
    final nowUserId = _auth.currentUser?.id;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (nowLoggedIn) {
      _loadPage(reset: true);
      return;
    }
    setState(() {
      _items.clear();
      _loading = false;
      _loadingMore = false;
      _hasNext = true;
      _page = 1;
      _error = AppStrings.loginRequired;
    });
  }

  Future<void> _promptLoginAndReload() async {
    final ok = await AuthUi.promptLogin(context: context);
    if (ok && mounted) {
      await _loadPage(reset: true);
    }
  }

  void _handleShellTabChanged() {
    if (!mounted) return;
    final idx = MainShellTabController.index.value;
    if (idx == _lastShellIndex) return;
    _lastShellIndex = idx;
    if (idx != 2) return;
    _loadPage(reset: true);
  }

  void _onScroll() {
    if (_loading || _loadingMore || !_hasNext) return;
    if (_scrollController.position.extentAfter < 200) {
      _loadPage(reset: false);
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _hasNext = true;
        _page = 1;
        _items.clear();
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }

    final userId = (_auth.currentUser?.id ?? '').trim();
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = '사용자 정보를 불러올 수 없습니다.';
        _loading = false;
        _loadingMore = false;
      });
      return;
    }

    try {
      final res = await _service.fetchUserAccounts(
        userId: userId,
        page: _page,
        pageSize: 20,
        fetchAll: false,
        testIds: const [1, 3],
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _hasNext = res.hasNext;
        _page += 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      } else {
        _loading = false;
        _loadingMore = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            if (!_auth.isLoggedIn) ...[
              ElevatedButton(
                onPressed: _promptLoginAndReload,
                child: const Text(AppStrings.login),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () => _loadPage(reset: true),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return _card(
        '아직 검사 결과가 없어요.',
        '검사를 완료하면 여기에 최근 결과가 표시됩니다.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (_hasNext) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: () => _loadPage(reset: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: const Text('더 불러오기'),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          return _ResultCard(item: _items[index]);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _items.length + 1,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});

  final UserAccountItem item;

  void _openDetail(BuildContext context) {
    if (item.resultId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserResultDetailScreen(
          resultId: item.resultId!,
          testId: item.testId,
        ),
      ),
    );
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

    return InkWell(
      onTap: () => _openDetail(context),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (tester.isNotEmpty && tester != '미지정')
                        Text(
                          '검사자 $tester',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textPrimary),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (selfType != null) _pill(selfType),
                if (otherType != null) _pill(otherType),
                if (statusText != null) _statusPill(statusText, statusColor),
              ],
            ),
          ],
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
    return name is String && name.isNotEmpty ? name : '미지정';
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

class _SavedPanel extends StatelessWidget {
  const _SavedPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('보관함', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _card(
          '보관한 결과가 없어요.',
          '결과 화면에서 보관하면 여기에서 확인할 수 있습니다.',
        ),
      ],
    );
  }
}

class _RecordPanel extends StatelessWidget {
  const _RecordPanel();

  @override
  Widget build(BuildContext context) {
    return const InterpretationRecordPanel();
  }
}

Widget _card(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(16),
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
        Text(title, style: AppTextStyles.h5),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );
}
