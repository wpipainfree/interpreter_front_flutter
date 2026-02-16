import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../domain/model/psych_test_models.dart';
import '../../router/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/auth_ui.dart';

class WpiReviewScreen extends StatefulWidget {
  const WpiReviewScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.items,
    required this.selections,
    this.processSequence,
    this.deferNavigation = false,
    this.existingResultId,
  });

  final int testId;
  final String testTitle;
  final List<PsychTestItem> items;
  final WpiSelections selections;
  final int? processSequence;
  final bool deferNavigation;
  final int? existingResultId;

  @override
  State<WpiReviewScreen> createState() => _WpiReviewScreenState();
}

class _WpiReviewScreenState extends State<WpiReviewScreen> {
  final _repository = AppScope.instance.psychTestRepository;
  bool _submitting = false;
  DragSnapshot? _lastSwap;

  late Map<int, List<PsychTestItem>> _buckets;

  @override
  void initState() {
    super.initState();
    _buckets = {
      1: widget.items
          .where((e) => widget.selections.rank1.contains(e.id))
          .toList(),
      2: widget.items
          .where((e) => widget.selections.rank2.contains(e.id))
          .toList(),
      3: widget.items
          .where((e) => widget.selections.rank3.contains(e.id))
          .toList(),
    };
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('선택 검토'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitTestFlow,
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
                    _buildBucket(1, '1순위'),
                    _buildBucket(2, '2순위'),
                    _buildBucket(3, '3순위'),
                  ],
                ),
              ),
            ),
            _BottomBar(
              submitting: _submitting,
              onConfirm: _submit,
            ),
          ],
        ),
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
              Text(title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...list.map((item) => _DraggableTile(
                    item: item,
                    rank: rank,
                    onSwap: _handleSwap,
                    onDragUpdate: _handleAutoScroll,
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
        content: const Text('순위를 교체했습니다.'),
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
    _handleSwap(DragData(itemId: snap.toId, rank: snap.toRank), snap.fromRank,
        snap.fromId);
    _lastSwap = null;
  }

  void _handleAutoScroll(DragUpdateDetails details) {
    final scrollableState = Scrollable.maybeOf(context);
    final position = scrollableState?.position;
    final box = scrollableState?.context.findRenderObject() as RenderBox?;
    if (position == null || box == null) return;

    const edgeDragWidth = 60.0;
    const scrollStep = 16.0;
    final localOffset = box.globalToLocal(details.globalPosition);
    final dy = localOffset.dy;

    if (dy < edgeDragWidth && position.pixels > position.minScrollExtent) {
      position.jumpTo((position.pixels - scrollStep)
          .clamp(position.minScrollExtent, position.maxScrollExtent));
    } else if (dy > box.size.height - edgeDragWidth &&
        position.pixels < position.maxScrollExtent) {
      position.jumpTo((position.pixels + scrollStep)
          .clamp(position.minScrollExtent, position.maxScrollExtent));
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final selections = WpiSelections(
      checklistId: widget.selections.checklistId,
      rank1: _buckets[1]?.map((e) => e.id).toList() ?? [],
      rank2: _buckets[2]?.map((e) => e.id).toList() ?? [],
      rank3: _buckets[3]?.map((e) => e.id).toList() ?? [],
    );

    Future<Map<String, dynamic>> send() {
      return widget.existingResultId == null
          ? _repository.submitResults(
              testId: widget.testId,
              selections: selections,
              processSequence: widget.processSequence ?? 99,
            )
          : _repository.updateResults(
              resultId: widget.existingResultId!,
              selections: selections,
              processSequence: widget.processSequence ?? 99,
            );
    }

    try {
      final result = await AuthUi.withLoginRetry<Map<String, dynamic>>(
        context: context,
        action: send,
      );
      if (!mounted || result == null) return;
      if (widget.deferNavigation) {
        Navigator.of(context).pop(result);
      } else {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.rawResult,
          arguments: RawResultArgs(title: '검사 결과', payload: result),
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
            Text('총 3개 순위를 다시 확인해주세요.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '필요하면 드래그로 순서를 바꿀 수 있습니다.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              testTitle,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
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
    required this.onDragUpdate,
  });

  final PsychTestItem item;
  final int rank;
  final void Function(DragData drag, int targetRank, int targetId) onSwap;
  final void Function(DragUpdateDetails details) onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
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
          onDragUpdate: (details) {
            onDragUpdate(details);
            if (scrollable != null) {
              _autoScroll(scrollable, details);
            }
          },
          child: _tile(context, highlight: highlight),
        );
      },
    );
  }

  Widget _tile(BuildContext context,
      {bool dragging = false, bool highlight = false}) {
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
          Expanded(
            child: Text(
              item.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.drag_indicator_rounded,
              color: AppColors.textSecondary),
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
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _autoScroll(ScrollableState scrollable, DragUpdateDetails details) {
    final position = scrollable.position;
    if (!position.haveDimensions) return;
    const edge = 60.0;
    const step = 16.0;
    final box = scrollable.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);

    if (local.dy < edge && position.pixels > position.minScrollExtent) {
      final newOffset = (position.pixels - step)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      position.jumpTo(newOffset);
    } else if (local.dy > box.size.height - edge &&
        position.pixels < position.maxScrollExtent) {
      final newOffset = (position.pixels + step)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      position.jumpTo(newOffset);
    }
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.submitting,
    required this.onConfirm,
  });

  final bool submitting;
  final VoidCallback onConfirm;

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
                  : const Text('제출'),
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

  const DragData({required this.itemId, required this.rank});
}

class DragSnapshot {
  final int fromRank;
  final int toRank;
  final int fromId;
  final int toId;

  const DragSnapshot({
    required this.fromRank,
    required this.toRank,
    required this.fromId,
    required this.toId,
  });
}
