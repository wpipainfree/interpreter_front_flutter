import 'package:flutter/material.dart';

import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../result/raw_result_screen.dart';

class WpiReviewScreen extends StatefulWidget {
  const WpiReviewScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.items,
    required this.selections,
  });

  final int testId;
  final String testTitle;
  final List<PsychTestItem> items;
  final WpiSelections selections;

  @override
  State<WpiReviewScreen> createState() => _WpiReviewScreenState();
}

class _WpiReviewScreenState extends State<WpiReviewScreen> {
  final PsychTestsService _service = PsychTestsService();
  bool _submitting = false;
  DragSnapshot? _lastSwap;

  late Map<int, List<PsychTestItem>> _buckets;

  @override
  void initState() {
    super.initState();
    _buckets = {
      1: widget.items.where((e) => widget.selections.rank1.contains(e.id)).toList(),
      2: widget.items.where((e) => widget.selections.rank2.contains(e.id)).toList(),
      3: widget.items.where((e) => widget.selections.rank3.contains(e.id)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('검토/정리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _ReviewHeader(testTitle: widget.testTitle),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  _buildBucket(1, '1순위 (3/3)'),
                  _buildBucket(2, '2순위 (4/4)'),
                  _buildBucket(3, '3순위 (5/5)'),
                ],
              ),
            ),
          ),
          _BottomBar(
            submitting: _submitting,
            onConfirm: _submit,
            onBack: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBucket(int rank, String title) {
    final list = _buckets[rank] ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...list.map((item) => _DraggableTile(
                    item: item,
                    rank: rank,
                    onSwap: _handleSwap,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSwap(DragData drag, int targetRank, int targetId) {
    final sourceList = _buckets[drag.rank] ?? [];
    final targetList = _buckets[targetRank] ?? [];
    final sourceIndex = sourceList.indexWhere((e) => e.id == drag.itemId);
    final targetIndex = targetList.indexWhere((e) => e.id == targetId);
    if (sourceIndex == -1 || targetIndex == -1) return;
    final sourceItem = sourceList[sourceIndex];
    final targetItem = targetList[targetIndex];

    setState(() {
      sourceList[sourceIndex] = targetItem;
      targetList[targetIndex] = sourceItem;
      _lastSwap = DragSnapshot(
        fromRank: drag.rank,
        toRank: targetRank,
        fromId: sourceItem.id,
        toId: targetItem.id,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('순위가 바뀌었습니다.'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: _undoSwap,
        ),
      ),
    );
  }

  void _undoSwap() {
    final snap = _lastSwap;
    if (snap == null) return;
    _handleSwap(DragData(itemId: snap.toId, rank: snap.toRank), snap.fromRank, snap.fromId);
    _lastSwap = null;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final selections = WpiSelections(
      checklistId: widget.selections.checklistId,
      rank1: _buckets[1]?.map((e) => e.id).toList() ?? [],
      rank2: _buckets[2]?.map((e) => e.id).toList() ?? [],
      rank3: _buckets[3]?.map((e) => e.id).toList() ?? [],
    );
    try {
      final result = await _service.submitResults(testId: widget.testId, selections: selections);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RawResultScreen(
            title: '검사 제출 완료',
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
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.testTitle});

  final String testTitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지금까지 담은 12개를 마지막으로 정리합니다.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '문장을 길게 눌러 끌어 바꾸고 싶은 문장 위에 놓으면 순위가 바뀝니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              testTitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableTile extends StatelessWidget {
  const _DraggableTile({
    required this.item,
    required this.rank,
    required this.onSwap,
  });

  final PsychTestItem item;
  final int rank;
  final void Function(DragData drag, int targetRank, int targetId) onSwap;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) => details.data.itemId != item.id,
      onAcceptWithDetails: (details) => onSwap(details.data, rank, item.id),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return LongPressDraggable<DragData>(
          data: DragData(itemId: item.id, rank: rank),
          feedback: _dragFeedback(item.text),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _tile(context, dragging: true, highlight: highlight),
          ),
          child: _tile(context, highlight: highlight),
        );
      },
    );
  }

  Widget _tile(BuildContext context, {bool dragging = false, bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppColors.secondary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: Text(item.text, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: 12),
          const Icon(Icons.drag_indicator_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _dragFeedback(String text) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: AppColors.secondary),
        ),
        child: Text(text, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.submitting,
    required this.onConfirm,
    required this.onBack,
  });

  final bool submitting;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: submitting ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('이 파트 확정'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: submitting ? null : onBack,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('라운드로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

class DragData {
  final int itemId;
  final int rank;
  DragData({required this.itemId, required this.rank});
}

class DragSnapshot {
  final int fromRank;
  final int toRank;
  final int fromId;
  final int toId;

  DragSnapshot({
    required this.fromRank,
    required this.toRank,
    required this.fromId,
    required this.toId,
  });
}
