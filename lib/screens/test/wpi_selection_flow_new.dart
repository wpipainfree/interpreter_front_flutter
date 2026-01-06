import 'package:flutter/material.dart';

import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../result/raw_result_screen.dart';

/// New free-order flow: users pick items up to target counts, then submit.
/// This now runs through every checklist (e.g., self/other) sequentially.
class WpiSelectionFlowNew extends StatefulWidget {
  const WpiSelectionFlowNew({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  final int testId;
  final String testTitle;

  @override
  State<WpiSelectionFlowNew> createState() => _WpiSelectionFlowNewState();
}

class _WpiSelectionFlowNewState extends State<WpiSelectionFlowNew> {
  final PsychTestsService _service = PsychTestsService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final List<PsychTestChecklist> _checklists = [];
  int _stageIndex = 0;
  int? _resultId;
  final List<PsychTestItem> _allItems = [];
  final List<int> _selectedIds = [];
  final Map<int, int> _originalOrder = {};
  bool _limitSnackVisible = false;

  PsychTestChecklist? get _checklist => _checklists.isEmpty ? null : _checklists[_stageIndex];

  int get _totalTarget {
    final c = _checklist;
    if (c == null) return 0;
    return c.firstCount + c.secondCount + c.thirdCount;
  }

  @override
  void initState() {
    super.initState();
    _load();
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
      _checklists
        ..clear()
        ..addAll(lists);
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
    for (var i = 0; i < _allItems.length; i++) {
      _originalOrder[_allItems[i].id] = i;
    }
    setState(() {
      _stageIndex = index;
      if (index == 0) _resultId = null;
      _selectedIds.clear();
      _loading = false;
      _error = null;
      _submitting = false;
    });
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
      if (_limitSnackVisible) return;
      _limitSnackVisible = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(
              content: Text('선택 가능 개수를 모두 선택했습니다. 다른 항목을 제거한 뒤 추가해주세요.'),
              duration: Duration(seconds: 2),
            ),
          )
          .closed
          .whenComplete(() => _limitSnackVisible = false);
      return;
    }
    setState(() {
      _selectedIds.add(item.id);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('선택되었습니다'),
            action: SnackBarAction(
              label: '취소',
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _selectedIds.remove(item.id);
                  });
                }
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        )
        .closed
        .whenComplete(() {});
  }

  void _removeSelected(int id) {
    setState(() => _selectedIds.remove(id));
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final id = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(newIndex, id);
    });
  }

  Future<void> _submit() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('단계가 완료되었습니다. 이어서 다음 단계를 진행합니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        _prepareStage(_stageIndex + 1);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RawResultScreen(
              title: '검사 결과',
              payload: result,
            ),
          ),
        );
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

  void _openSelectedPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('선택한 항목', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('닫기')),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _selectedIds.isEmpty
                      ? Center(
                          child: Text('선택된 항목이 없습니다.', style: AppTextStyles.bodySmall),
                        )
                      : ReorderableListView.builder(
                          itemCount: _selectedIds.length,
                          onReorder: _reorderSelected,
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final id = _selectedIds[index];
                            final item = _allItems.firstWhere((e) => e.id == id);
                            final div = _rankDivider(index);
                            return Column(
                              key: ValueKey(id),
                              children: [
                                if (div != null) div,
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                  title: Text(_cleanText(item.text)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _removeSelected(id),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _rankDivider(int index) {
    final c = _checklist;
    if (c == null) return null;
    if (index == 0) {
      return _dividerLabel('1순위 (${c.firstCount})');
    } else if (index == c.firstCount) {
      return _dividerLabel('2순위 (${c.secondCount})');
    } else if (index == c.firstCount + c.secondCount) {
      return _dividerLabel('3순위 (${c.thirdCount})');
    }
    return null;
  }

  Widget _dividerLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      ),
    );
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
              ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final checklist = _checklist!;
    final available = _availableItems;
    final total = _totalTarget;
    final canSubmit = _selectedIds.length == total && !_submitting;
    final stageLabel = '${_stageIndex + 1}/${_checklists.length} ${checklist.name}';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('[New] ${widget.testTitle} · $stageLabel'),
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
            onOpen: _openSelectedPanel,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checklist.question.isNotEmpty
                      ? checklist.question
                      : '각 순위별로 정해진 개수만큼 선택해주세요.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '1~${checklist.firstCount}번까지 1순위, 다음 ${checklist.secondCount}개 2순위, 나머지 3순위입니다.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: available.length,
              itemBuilder: (context, index) {
                final item = available[index];
                final number = (_originalOrder[item.id] ?? index) + 1;
                return _SelectableTile(
                  number: number,
                  text: _cleanText(item.text),
                  onSelect: () => _toggleSelect(item),
                );
              },
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

  String _cleanText(String text) => text.replaceAll(RegExp(r'\(.*?\)'), '').trim();

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
    required this.onOpen,
  });

  final int selectedCount;
  final int totalTarget;
  final String stageLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stageLabel, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '선택 $selectedCount/$totalTarget',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('선택 보기')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '순서를 드래그해 순위를 조정할 수 있습니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({required this.number, required this.text, required this.onSelect});

  final int number;
  final String text;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withOpacity(0.12),
          foregroundColor: AppColors.secondary,
          child: Text('$number', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        ),
        title: Text(text, style: AppTextStyles.bodyMedium),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
          onPressed: onSelect,
        ),
      ),
    );
  }
}
