import 'package:flutter/material.dart';
import '../../app/di/app_scope.dart';
import '../../domain/model/result_models.dart';
import '../../router/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../utils/strings.dart';
import '../../widgets/app_error_view.dart';

class TodayMindReadFlowScreen extends StatefulWidget {
  const TodayMindReadFlowScreen({super.key});

  @override
  State<TodayMindReadFlowScreen> createState() =>
      _TodayMindReadFlowScreenState();
}

class _TodayMindReadFlowScreenState extends State<TodayMindReadFlowScreen> {
  final _resultRepository = AppScope.instance.resultRepository;
  final TextEditingController _storyController = TextEditingController();
  final ScrollController _listController = ScrollController();

  bool _loading = true;
  bool _submitting = false;
  bool _openingTest = false;
  String? _error;
  int _stepIndex = 0;

  final List<ResultAccount> _realityItems = [];
  final List<ResultAccount> _idealItems = [];
  ResultAccount? _selectedReality;
  ResultAccount? _selectedIdeal;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _storyController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (!_resultRepository.isLoggedIn) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok && mounted) {
        Navigator.of(context).pop();
        return;
      }
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = (_resultRepository.currentUserId ?? '').trim();
      if (userId.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }
      final reality = await _fetchAllAccounts(userId: userId, testId: 1);
      final ideal = await _fetchAllAccounts(userId: userId, testId: 3);
      reality.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));
      ideal.sort((a, b) => _itemDate(b).compareTo(_itemDate(a)));

      if (!mounted) return;
      setState(() {
        _realityItems
          ..clear()
          ..addAll(reality);
        _idealItems
          ..clear()
          ..addAll(ideal);
        _selectedReality = null;
        _selectedIdeal = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<ResultAccount>> _fetchAllAccounts({
    required String userId,
    required int testId,
  }) async {
    final items = <ResultAccount>[];
    var page = 1;
    var hasNext = true;
    var safety = 0;
    while (hasNext && safety < 50) {
      safety += 1;
      final res = await _resultRepository.fetchUserAccounts(
        userId: userId,
        page: page,
        pageSize: 30,
        fetchAll: false,
        testIds: [testId],
      );
      items.addAll(res.items.where((e) => e.resultId != null));
      hasNext = res.hasNext;
      page += 1;
    }
    return items;
  }

  DateTime _itemDate(ResultAccount item) {
    final raw = item.createDate ?? item.paymentDate ?? item.modifyDate;
    final parsed = raw != null ? DateTime.tryParse(raw) : null;
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _nextStep() async {
    if (_stepIndex == 0) {
      final text = _storyController.text.trim();
      if (text.isEmpty) {
        _showMessage('사연을 1~2줄로 입력해 주세요.');
        return;
      }
    }
    _goToStep((_stepIndex + 1).clamp(0, 2));
  }

  void _prevStep() {
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    _goToStep((_stepIndex - 1).clamp(0, 2));
  }

  void _goToStep(int step) {
    setState(() => _stepIndex = step);
    _resetListScroll();
  }

  void _resetListScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_listController.hasClients) return;
      _listController.jumpTo(_listController.position.minScrollExtent);
    });
  }

  Future<void> _submitPhase2() async {
    if (_submitting) return;
    final story = _storyController.text.trim();
    if (story.isEmpty) {
      _showMessage('사연을 입력해 주세요.');
      return;
    }
    final realityId = _selectedReality?.resultId;
    final idealId = _selectedIdeal?.resultId;
    if (realityId == null) {
      _showMessage('현실 검사 결과를 선택해 주세요.');
      return;
    }
    if (idealId == null) {
      _showMessage('이상 검사 결과를 선택해 주세요.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final realityDetail =
          await _resultRepository.fetchResultDetail(realityId);
      final idealDetail = await _resultRepository.fetchResultDetail(idealId);
      final response = await _resultRepository.fetchInitialInterpretation(
        reality: realityDetail,
        ideal: idealDetail,
        story: story,
        force: true,
      );
      final sessionId = response.session?.sessionId ?? '';
      if (!mounted) return;
      if (sessionId.trim().isEmpty) {
        _showMessage('해석 세션을 만들지 못했습니다.');
        setState(() => _submitting = false);
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.interpretationRecordDetail,
        arguments: InterpretationRecordDetailArgs(
          conversationId: sessionId,
          title: _truncateTitle(story),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(e.toString());
    }
  }

  Future<void> _openTestNote(int testId) async {
    if (_openingTest) return;
    setState(() => _openingTest = true);
    try {
      await Navigator.of(context).pushNamed(
        AppRoutes.testNote,
        arguments: TestNoteArgs(
          testId: testId,
          testTitle: _defaultTestTitle(testId),
        ),
      );
      if (!mounted) return;
      await _load();
    } finally {
      if (mounted) {
        setState(() => _openingTest = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _truncateTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 22) return trimmed;
    return '${trimmed.substring(0, 22)}...';
  }

  String _formatDate(ResultAccount item) {
    final raw = item.createDate ?? item.paymentDate ?? item.modifyDate;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.${parsed.day.toString().padLeft(2, '0')}';
  }

  String _testLabel(int? testId) {
    if (testId == 1) return 'WPI 현실 검사';
    if (testId == 3) return 'WPI 이상 검사';
    return 'WPI 검사';
  }

  String _defaultTestTitle(int testId) {
    if (testId == 3) return 'WPI 이상 검사';
    return 'WPI 현실 검사';
  }

  String? _resultType(ResultAccount item) {
    final byKey = item.result?['DESCRIPTION'];
    if (byKey is String && byKey.isNotEmpty) return byKey;
    final desc = item.result?['description'];
    if (desc is String && desc.isNotEmpty) return desc;
    final existence = item.result?['existence_type'] ?? item.result?['title'];
    if (existence is String && existence.isNotEmpty) return existence;
    return null;
  }

  String? _targetName(ResultAccount item) {
    final raw = item.result?['TEST_TARGET_NAME'] ??
        item.result?['test_target_name'] ??
        item.result?['testTargetName'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // didPop이 true면 이미 pop이 진행 중이므로 중복 호출 방지
        if (didPop) return;
        _prevStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _prevStep,
          ),
          title: const Text('오늘 내 마음 읽기'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? AppErrorView(
                    title: '불러오지 못했어요',
                    message: _error!,
                    primaryActionLabel: AppStrings.retry,
                    primaryActionStyle: AppErrorPrimaryActionStyle.outlined,
                    onPrimaryAction: _load,
                  )
                : SafeArea(
                    child: _buildStepBody(),
                  ),
      ),
    );
  }

  Widget _buildStepBody() {
    final stepTitle = _stepIndex == 0
        ? '사연 입력'
        : _stepIndex == 1
            ? '현실 검사 선택'
            : '이상 검사 선택';
    final stepLabel = 'STEP ${_stepIndex + 1}/3';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stepLabel, style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Text(stepTitle, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          if (_stepIndex != 0) _buildStorySummary(),
          if (_stepIndex != 0) const SizedBox(height: 12),
          Expanded(child: _buildStepContent()),
          const SizedBox(height: 12),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildStorySummary() {
    final story = _storyController.text.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('사연', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Text(story, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _stepIndex = 0),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_stepIndex == 0) {
      return _buildStoryInput();
    }
    if (_stepIndex == 1) {
      return _buildResultList(
        title: '선택 가능한 현실 검사 결과',
        items: _realityItems,
        selected: _selectedReality,
        emptyMessage: '현실 검사 결과가 없습니다.',
        onSelect: (item) => setState(() => _selectedReality = item),
      );
    }
    return _buildResultList(
      title: '선택 가능한 이상 검사 결과',
      items: _idealItems,
      selected: _selectedIdeal,
      emptyMessage: '이상 검사 결과가 없습니다.',
      onSelect: (item) => setState(() => _selectedIdeal = item),
    );
  }

  Widget _buildStoryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '지금 어떤 마음을 알고 싶나요?',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '1~2줄로 간단히 적어주세요.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storyController,
          minLines: 2,
          maxLines: 4,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '예) 요즘 쉽게 예민해져요. 왜 그런지 알고 싶어요.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultList({
    required String title,
    required List<ResultAccount> items,
    required ResultAccount? selected,
    required String emptyMessage,
    required ValueChanged<ResultAccount> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              emptyMessage,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              controller: _listController,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selected?.resultId == item.resultId;
                final dateText = _formatDate(item);
                final typeLabel = _resultType(item);
                final targetName = _targetName(item);
                final title = (typeLabel ?? '').trim().isNotEmpty
                    ? typeLabel!
                    : _testLabel(item.testId);
                final testLabel = (typeLabel ?? '').trim().isNotEmpty
                    ? _testLabel(item.testId)
                    : null;
                return _ResultSelectCard(
                  title: title,
                  dateText: dateText,
                  testLabel: testLabel,
                  targetName: targetName,
                  isSelected: isSelected,
                  isRecent: index == 0,
                  onTap: () => onSelect(item),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton() {
    if (_stepIndex == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('다음'),
        ),
      );
    }
    if (_stepIndex == 1) {
      if (_realityItems.isEmpty) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _openingTest ? null : () => _openTestNote(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: _openingTest
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('현실 검사 진행하기'),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedReality == null ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('다음'),
        ),
      );
    }
    if (_idealItems.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _openingTest ? null : () => _openTestNote(3),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          child: _openingTest
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('이상 검사 진행하기'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            (_selectedIdeal == null || _submitting) ? null : _submitPhase2,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('해석 만들기'),
      ),
    );
  }
}

class _ResultSelectCard extends StatelessWidget {
  const _ResultSelectCard({
    required this.title,
    required this.dateText,
    required this.testLabel,
    required this.targetName,
    required this.isSelected,
    required this.isRecent,
    required this.onTap,
  });

  final String title;
  final String dateText;
  final String? testLabel;
  final String? targetName;
  final bool isSelected;
  final bool isRecent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border;
    final background = isSelected
        ? AppColors.primary.withValues(alpha: 0.06)
        : AppColors.cardBackground;
    final hasTarget = (targetName ?? '').trim().isNotEmpty;
    final hasTestLabel = (testLabel ?? '').trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          dateText,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        if (isRecent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '최근',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasTarget) ...[
                      const SizedBox(height: 6),
                      Text(
                        '피검사자: $targetName',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    if (hasTestLabel) ...[
                      const SizedBox(height: 6),
                      Text(
                        testLabel!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
