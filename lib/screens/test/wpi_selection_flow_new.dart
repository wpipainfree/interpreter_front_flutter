import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/psych_test_models.dart';
import '../../router/app_routes.dart';
import '../../test_flow/role_transition_screen.dart';
import '../../test_flow/test_flow_models.dart';
import '../../ui/test/wpi_selection_flow_view_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';
import '../../widgets/app_error_view.dart';

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
    this.existingResultId,
    this.initialRole,
  });

  final int testId;
  final String testTitle;
  final String? mindFocus;
  final WpiTestKind kind;
  final FlowExitMode exitMode;
  final int? existingResultId;
  final EvaluationRole? initialRole;

  @override
  State<WpiSelectionFlowNew> createState() => _WpiSelectionFlowNewState();
}

class _WpiSelectionFlowNewState extends State<WpiSelectionFlowNew> {
  late final WpiSelectionFlowViewModel _viewModel;
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
  bool _limitSnackArmed = true;
  bool _shownOtherTransition = false;

  PsychTestChecklist? get _checklist =>
      _checklists.isEmpty ? null : _checklists[_stageIndex];

  int get _totalTarget {
    final c = _checklist;
    if (c == null) return 0;
    return c.firstCount + c.secondCount + c.thirdCount;
  }

  @override
  void initState() {
    super.initState();
    _viewModel =
        WpiSelectionFlowViewModel(AppScope.instance.psychTestRepository);
    _resultId = widget.existingResultId;
    _init();
  }

  Future<void> _init() async {
    if (!_viewModel.isLoggedIn) {
      final ok = await AuthUi.promptLogin(context: context);
      if (!ok && mounted) {
        _exitTestFlow();
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
      final lists = await AuthUi.withLoginRetry(
        context: context,
        action: () => _viewModel.loadChecklists(widget.testId),
      );
      if (lists == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Login is required.';
        });
        return;
      }
      if (lists.isEmpty) {
        throw const PsychTestException('No checklist data.');
      }
      _checklists
        ..clear()
        ..addAll(lists);
      _prepareStage(_viewModel.resolveInitialIndex(
        checklists: lists,
        initialRole: widget.initialRole,
      ));
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
    _originalOrder..clear();
    _itemById..clear();
    for (var i = 0; i < _allItems.length; i++) {
      final item = _allItems[i];
      _originalOrder[item.id] = i;
      _itemById[item.id] = item;
    }
    setState(() {
      _stageIndex = index;
      if (index == 0 && widget.existingResultId == null) _resultId = null;
      if (index == 0) _shownOtherTransition = false;
      _selectedIds.clear();
      _limitSnackArmed = true;
      _loading = false;
      _error = null;
      _submitting = false;
    });
    _resetScrollPosition();
  }

  void _resetScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_listController.hasClients) return;
      _listController.jumpTo(_listController.position.minScrollExtent);
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
    available.sort((a, b) =>
        (_originalOrder[a.id] ?? 0).compareTo(_originalOrder[b.id] ?? 0));
    return available;
  }

  void _toggleSelect(PsychTestItem item) {
    if (_selectedIds.contains(item.id)) return;
    if (_selectedIds.length >= _totalTarget) {
      final messenger = ScaffoldMessenger.of(context);
      if (!_limitSnackVisible && _limitSnackArmed) {
        _limitSnackVisible = true;
        _limitSnackArmed = false;
        messenger.clearSnackBars();
        messenger
            .showSnackBar(
              const SnackBar(
                content: Text('선택 가능 개수를 모두 선택했습니다. 다른 항목을 제거한 뒤 추가해주세요.'),
                duration: Duration(milliseconds: 1200),
              ),
            )
            .closed
            .whenComplete(() => _limitSnackVisible = false);
      }
      return;
    }

    setState(() {
      _selectedIds.add(item.id);
    });
  }

  void _deselect(PsychTestItem item) {
    setState(() {
      _selectedIds.remove(item.id);
      _limitSnackArmed = true;
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
      final result = await AuthUi.withLoginRetry(
        context: context,
        action: () => _viewModel.submitSelection(
          testId: widget.testId,
          selections: selections,
          mindFocus: widget.mindFocus,
          processSequence: c.sequence == 0 ? _stageIndex + 1 : c.sequence,
          resultId: _resultId,
        ),
      );
      if (result == null) return;
      _resultId ??= _viewModel.extractResultId(result);
      if (!mounted) return;
      final hasNext = _stageIndex + 1 < _checklists.length;
      if (hasNext) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('다음 단계로 이동합니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        final nextIndex = _stageIndex + 1;
        await _maybeShowOtherTransition(
            _checklists[_stageIndex], _checklists[nextIndex]);
        _prepareStage(nextIndex);
      } else {
        final rid = _resultId ?? _viewModel.extractResultId(result);
        if (rid != null) {
          if (widget.exitMode == FlowExitMode.popWithResult) {
            Navigator.of(context).pop(
              FlowCompletion(kind: widget.kind, resultId: rid.toString()),
            );
          } else {
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.userResultDetail,
              arguments:
                  UserResultDetailArgs(resultId: rid, testId: widget.testId),
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

  Future<void> _maybeShowOtherTransition(
    PsychTestChecklist current,
    PsychTestChecklist next,
  ) async {
    if (_shownOtherTransition) return;
    if (current.role != EvaluationRole.self ||
        next.role != EvaluationRole.other) return;
    _shownOtherTransition = true;
    if (!mounted) return;
    await RoleTransitionScreen.show(context);
  }

  void _exitTestFlow() {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == null) return route.isFirst;
      return !name.startsWith('/test/');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.testTitle),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitTestFlow,
              ),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      final loggedIn = _viewModel.isLoggedIn;
      return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('WPI'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitTestFlow,
              ),
            ],
          ),
          body: AppErrorView(
            title: loggedIn ? '불러오지 못했어요' : '로그인이 필요합니다',
            message: _error!,
            primaryActionLabel: loggedIn ? '다시 시도' : '로그인하기',
            primaryActionStyle: loggedIn
                ? AppErrorPrimaryActionStyle.outlined
                : AppErrorPrimaryActionStyle.filled,
            onPrimaryAction: loggedIn ? () => _load() : () => _init(),
          ),
        ),
      );
    }

    final checklist = _checklist!;
    final total = _totalTarget;
    final canSubmit = _selectedIds.length == total && !_submitting;
    final stageLabel =
        '${_stageIndex + 1}/${_checklists.length} ${checklist.name}';
    final selectedItems = _selectedItems;
    final availableItems = _availableItems;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('${widget.testTitle} / $stageLabel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitTestFlow,
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
                    checklist.question.isNotEmpty
                        ? checklist.question
                        : '순서대로 선택 후 제출해주세요.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1~${checklist.firstCount}개 1순위, 그 다음 ${checklist.secondCount}개 2순위, 나머지 3순위로 선택합니다.',
                    style: AppTextStyles.bodySmall,
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
                        if (index < 0 || index >= selectedItems.length)
                          return child;
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
                          children.add(
                              SizedBox(key: _selectedAnchorKey, height: 0));
                          children.add(_rankLabel(
                              '1순위 (${_checklist?.firstCount ?? 0})'));
                        } else if (index == (_checklist?.firstCount ?? 0) &&
                            index < _selectedIds.length) {
                          children.add(_rankLabel(
                              '2순위 (${_checklist?.secondCount ?? 0})'));
                        } else if (index ==
                                ((_checklist?.firstCount ?? 0) +
                                    (_checklist?.secondCount ?? 0)) &&
                            index < _selectedIds.length) {
                          children.add(_rankLabel(
                              '3순위 (${_checklist?.thirdCount ?? 0})'));
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
                    backgroundColor:
                        canSubmit ? AppColors.secondary : AppColors.disabled,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('제출'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    final cleaned = trimmed.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    return cleaned.isEmpty ? trimmed : cleaned;
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
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary),
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
                  style: AppTextStyles.bodySmall,
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
          child: Text('$number',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
        title: Text(
          text,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        trailing: selected
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.secondary),
                onPressed: onDeselect,
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.secondary),
                onPressed: onSelect,
              ),
      ),
    );

    return tile;
  }
}
