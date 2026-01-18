import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../test_flow/role_transition_screen.dart';
import '../../test_flow/test_flow_models.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';
import '../result/user_result_detail_screen.dart';

/// New free-order flow: users pick items up to target counts, then submit.
/// This runs through every checklist (e.g., self/other) sequentially.
class WpiSelectionFlowNew extends StatefulWidget {
  const WpiSelectionFlowNew({
    super.key,
    required this.testId,
    required this.testTitle,
    this.mindFocus,
    this.kind = WpiTestKind.reality,
    this.exitMode = FlowExitMode.openResultDetail,
  });

  final int testId;
  final String testTitle;
  final String? mindFocus;
  final WpiTestKind kind;
  final FlowExitMode exitMode;

  @override
  State<WpiSelectionFlowNew> createState() => _WpiSelectionFlowNewState();
}

class _WpiSelectionFlowNewState extends State<WpiSelectionFlowNew> {
  final AuthService _authService = AuthService();
  final PsychTestsService _service = PsychTestsService();
  final ScrollController _listController = ScrollController();
  final GlobalKey _selectedAnchorKey = GlobalKey();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final List<PsychTestChecklist> _checklists = [];
  int _stageIndex = 0;
  int? _resultId;
  final List<PsychTestItem> _allItems = [];
  final List<int> _selectedIds = [];
  final Map<int, int> _originalOrder = {};
  final Map<int, PsychTestItem> _itemById = {};
  bool _limitSnackVisible = false;
  bool _shownOtherTransition = false;

  PsychTestChecklist? get _checklist => _checklists.isEmpty ? null : _checklists[_stageIndex];

  int get _totalTarget {
    final c = _checklist;
    if (c == null) return 0;
    return c.firstCount + c.secondCount + c.thirdCount;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!_authService.isLoggedIn) {
      final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const LoginScreen(),
        ),
      );
      if (ok != true && mounted) {
        Navigator.of(context).pop();
        return;
      }
    }
    await _load();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await _service.fetchChecklists(widget.testId);
      if (lists.isEmpty) {
        throw const PsychTestException('No checklist data.');
      }
      final sorted = _sortChecklists(lists);
      _checklists
        ..clear()
        ..addAll(sorted);
      _prepareStage(0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _prepareStage(int index) {
    if (index < 0 || index >= _checklists.length) return;
    final checklist = _checklists[index];
    _allItems
      ..clear()
      ..addAll(checklist.questions);
    _originalOrder
      ..clear();
    _itemById
      ..clear();
    for (var i = 0; i < _allItems.length; i++) {
      final item = _allItems[i];
      _originalOrder[item.id] = i;
      _itemById[item.id] = item;
    }
    setState(() {
      _stageIndex = index;
      if (index == 0) _resultId = null;
      if (index == 0) _shownOtherTransition = false;
      _selectedIds.clear();
      _loading = false;
      _error = null;
      _submitting = false;
    });
  }

  List<PsychTestItem> get _selectedItems {
    final items = <PsychTestItem>[];
    for (final id in _selectedIds) {
      final item = _itemById[id];
      if (item != null) items.add(item);
    }
    return items;
  }

  List<PsychTestItem> get _availableItems {
    final ids = _selectedIds.toSet();
    final available = _allItems.where((e) => !ids.contains(e.id)).toList();
    available.sort((a, b) => (_originalOrder[a.id] ?? 0).compareTo(_originalOrder[b.id] ?? 0));
    return available;
  }

  void _toggleSelect(PsychTestItem item) {
    if (_selectedIds.contains(item.id)) return;
    if (_selectedIds.length >= _totalTarget) {
      final messenger = ScaffoldMessenger.of(context);
      if (_limitSnackVisible) return;
      _limitSnackVisible = true;
      messenger.hideCurrentSnackBar();
      messenger
          .showSnackBar(
            const SnackBar(
              content: Text('선택 가능 개수를 모두 선택했습니다. 다른 항목을 제거한 뒤 추가해주세요.'),
              duration: Duration(milliseconds: 1200),
            ),
          )
          .closed
          .whenComplete(() => _limitSnackVisible = false);
      return;
    }

    setState(() {
      _selectedIds.add(item.id);
    });
  }

  void _deselect(PsychTestItem item) {
    setState(() {
      _selectedIds.remove(item.id);
    });
  }

  void _scrollToSelected() {
    if (_selectedIds.isEmpty) return;
    final context = _selectedAnchorKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0,
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    final selectedCount = _selectedIds.length;
    if (selectedCount <= 1) return;

    int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (target < 0) target = 0;
    if (target >= selectedCount) target = selectedCount - 1;
    if (target == oldIndex) return;

    setState(() {
      final movedId = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(target, movedId);
    });
  }

  Widget _rankLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_checklist == null || _selectedIds.length != _totalTarget) return;
    setState(() => _submitting = true);
    final c = _checklist!;
    final rank1 = _selectedIds.take(c.firstCount).toList();
    final rank2 = _selectedIds.skip(c.firstCount).take(c.secondCount).toList();
    final rank3 = _selectedIds.skip(c.firstCount + c.secondCount).toList();
    final selections = WpiSelections(
      checklistId: c.id,
      rank1: rank1,
      rank2: rank2,
      rank3: rank3,
    );
    try {
      final result = _resultId == null
          ? await _service.submitResults(
              testId: widget.testId,
              selections: selections,
              processSequence: c.sequence == 0 ? _stageIndex + 1 : c.sequence,
            )
          : await _service.updateResults(
              resultId: _resultId!,
              selections: selections,
              processSequence: c.sequence == 0 ? _stageIndex + 1 : c.sequence,
            );
      _resultId ??= _extractResultId(result);
      if (!mounted) return;
      final hasNext = _stageIndex + 1 < _checklists.length;
      if (hasNext) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('다음 단계로 이동합니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        final nextIndex = _stageIndex + 1;
        await _maybeShowOtherTransition(_checklists[_stageIndex], _checklists[nextIndex]);
        _prepareStage(nextIndex);
      } else {
        final rid = _resultId ?? _extractResultId(result);
        if (rid != null) {
          if (widget.exitMode == FlowExitMode.popWithResult) {
            Navigator.of(context).pop(
              FlowCompletion(kind: widget.kind, resultId: rid.toString()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => UserResultDetailScreen(resultId: rid, testId: widget.testId),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('결과 ID를 확인할 수 없습니다.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<PsychTestChecklist> _sortChecklists(List<PsychTestChecklist> source) {
    final indexed = List.generate(source.length, (i) => MapEntry(i, source[i]));
    indexed.sort((a, b) {
      final priorityA = _rolePriority(a.value.role);
      final priorityB = _rolePriority(b.value.role);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  int _rolePriority(EvaluationRole role) {
    switch (role) {
      case EvaluationRole.self:
        return 0;
      case EvaluationRole.other:
        return 1;
      case EvaluationRole.unknown:
        return 2;
    }
  }

  Future<void> _maybeShowOtherTransition(
    PsychTestChecklist current,
    PsychTestChecklist next,
  ) async {
    if (_shownOtherTransition) return;
    if (current.role != EvaluationRole.self || next.role != EvaluationRole.other) return;
    _shownOtherTransition = true;
    if (!mounted) return;
    await RoleTransitionScreen.show(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WPI'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              if (!_authService.isLoggedIn) ...[
                ElevatedButton(
                  onPressed: _init,
                  child: const Text('로그인하기'),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final checklist = _checklist!;
    final total = _totalTarget;
    final canSubmit = _selectedIds.length == total && !_submitting;
    final stageLabel = '${_stageIndex + 1}/${_checklists.length} ${checklist.name}';
    final selectedItems = _selectedItems;
    final availableItems = _availableItems;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('[New] ${widget.testTitle} \u00B7 $stageLabel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryBar(
            selectedCount: _selectedIds.length,
            totalTarget: total,
            stageLabel: stageLabel,
            onTap: _scrollToSelected,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checklist.question.isNotEmpty ? checklist.question : '순서대로 선택 후 제출해주세요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1~${checklist.firstCount}개 1순위, 그 다음 ${checklist.secondCount}개 2순위, 나머지 3순위로 선택합니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomScrollView(
              controller: _listController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  sliver: SliverReorderableList(
                    itemCount: selectedItems.length,
                    onReorder: _handleReorder,
                    proxyDecorator: (child, index, animation) {
                      if (index < 0 || index >= selectedItems.length) return child;
                      final item = selectedItems[index];
                      final number = (_originalOrder[item.id] ?? index) + 1;
                      return Material(
                        elevation: 6,
                        color: Colors.transparent,
                        child: _SelectableTile(
                          number: number,
                          text: _cleanText(item.text),
                          onSelect: () {},
                          onDeselect: () => _deselect(item),
                          selected: true,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      final number = (_originalOrder[item.id] ?? index) + 1;
                      final List<Widget> children = [];
                      if (index == 0 && _selectedIds.isNotEmpty) {
                        children.add(SizedBox(key: _selectedAnchorKey, height: 0));
                        children.add(_rankLabel('1순위 (${_checklist?.firstCount ?? 0})'));
                      } else if (index == (_checklist?.firstCount ?? 0) && index < _selectedIds.length) {
                        children.add(_rankLabel('2순위 (${_checklist?.secondCount ?? 0})'));
                      } else if (index == ((_checklist?.firstCount ?? 0) + (_checklist?.secondCount ?? 0)) &&
                          index < _selectedIds.length) {
                        children.add(_rankLabel('3순위 (${_checklist?.thirdCount ?? 0})'));
                      }

                      Widget tile = _SelectableTile(
                        number: number,
                        text: _cleanText(item.text),
                        onSelect: () {},
                        onDeselect: () => _deselect(item),
                        selected: true,
                      );
                      tile = ReorderableDelayedDragStartListener(
                        index: index,
                        child: tile,
                      );
                      children.add(tile);

                      return Column(
                        key: ValueKey(item.id),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = availableItems[index];
                        final number = (_originalOrder[item.id] ?? index) + 1;
                        return _SelectableTile(
                          key: ValueKey(item.id),
                          number: number,
                          text: _cleanText(item.text),
                          onSelect: () => _toggleSelect(item),
                          onDeselect: () => _deselect(item),
                          selected: false,
                        );
                      },
                      childCount: availableItems.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: canSubmit ? AppColors.secondary : AppColors.disabled,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('제출'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanText(String text) => text.replaceAll(RegExp(r'\\(.*?\\)'), '').trim();

  int? _extractResultId(dynamic res) {
    if (res == null) return null;
    if (res is int) return res;
    if (res is String) return int.tryParse(res);
    if (res is Map<String, dynamic>) {
      int? fromKey(String key) {
        final v = res[key];
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
        return null;
      }

      return fromKey('result_id') ?? fromKey('RESULT_ID') ?? fromKey('resultId');
    }
    return null;
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.selectedCount,
    required this.totalTarget,
    required this.stageLabel,
    this.onTap,
  });

  final int selectedCount;
  final int totalTarget;
  final String stageLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageLabel,
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '선택 ${selectedCount}/$totalTarget',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '목록에서 바로 선택/취소할 수 있습니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.number,
    required this.text,
    required this.onSelect,
    required this.onDeselect,
    this.selected = false,
    Key? key,
  });

  final int number;
  final String text;
  final VoidCallback onSelect;
  final VoidCallback? onDeselect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tile = Card(
      color: selected ? AppColors.secondary.withOpacity(0.08) : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withOpacity(0.12),
          foregroundColor: AppColors.secondary,
          child: Text('$number', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        ),
        title: Text(text, style: AppTextStyles.bodyLarge.copyWith(height: 1.45)),
        trailing: selected
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.secondary),
                onPressed: onDeselect,
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                onPressed: onSelect,
              ),
      ),
    );

    return tile;
  }
}

