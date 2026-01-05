import 'package:flutter/material.dart';

import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../result/raw_result_screen.dart';

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
  PsychTestChecklist? _checklist;
  final List<PsychTestItem> _allItems = [];
  final List<int> _selectedIds = [];
  final Map<int, int> _originalOrder = {};
  bool _limitSnackVisible = false;

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
      final checklist = await _service.fetchChecklist(widget.testId);
      _allItems
        ..clear()
        ..addAll(checklist.questions);
      _originalOrder.clear();
      for (var i = 0; i < _allItems.length; i++) {
        _originalOrder[_allItems[i].id] = i;
      }
      setState(() {
        _checklist = checklist;
        _selectedIds.clear();
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
            SnackBar(
              content: const Text('이미 12개가 모여 있어요. 위에서 하나를 빼면 새로 담을 수 있어요.'),
              duration: const Duration(seconds: 2),
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
            content: const Text('내 선택에 추가됐어요'),
            action: SnackBarAction(
              label: '되돌리기',
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
    final rank2 =
        _selectedIds.skip(c.firstCount).take(c.secondCount).toList();
    final rank3 = _selectedIds.skip(c.firstCount + c.secondCount).toList();
    final selections = WpiSelections(
      checklistId: c.id,
      rank1: rank1,
      rank2: rank2,
      rank3: rank3,
    );
    try {
      final result =
          await _service.submitResults(testId: widget.testId, selections: selections);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RawResultScreen(
            title: '검사 결과',
            payload: result,
          ),
        ),
      );
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
                    Text('내 선택(순위)', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('닫기')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '끌어서 순서를 바꾸면 순위도 함께 바뀝니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _selectedIds.isEmpty
                      ? Center(
                          child: Text('아직 선택한 문장이 없어요.', style: AppTextStyles.bodySmall),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('[New] ${widget.testTitle}'),
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
            onOpen: _openSelectedPanel,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택한 문장은 위에 모이고, 모인 순서가 순위가 됩니다.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '1~${checklist.firstCount}개는 1순위, ${checklist.firstCount + 1}~${checklist.firstCount + checklist.secondCount}개는 2순위, 나머지는 3순위로 계산돼요.',
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
                return _SelectableTile(
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
                    : const Text('이 파트 확정'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanText(String text) => text.replaceAll(RegExp(r'\(.*?\)'), '').trim();
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.selectedCount,
    required this.totalTarget,
    required this.onOpen,
  });

  final int selectedCount;
  final int totalTarget;
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '내 선택 $selectedCount/$totalTarget',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('내 선택 보기')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '위에서부터 1~3이 1순위, 4~7이 2순위, 8~12가 3순위로 계산됩니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({required this.text, required this.onSelect});

  final String text;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(text, style: AppTextStyles.bodyMedium),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
          onPressed: onSelect,
        ),
      ),
    );
  }
}
