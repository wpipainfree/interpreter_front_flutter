import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';
import 'wpi_review_screen.dart';

/// Classic round-based flow. Now iterates through all checklists (self/other) sequentially.
class WpiSelectionScreen extends StatefulWidget {
  const WpiSelectionScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  final int testId;
  final String testTitle;

  @override
  State<WpiSelectionScreen> createState() => _WpiSelectionScreenState();
}

class _WpiSelectionScreenState extends State<WpiSelectionScreen> {
  static const Color _brandRed = Color(0xFFA5192B);

  final PsychTestsService _service = PsychTestsService();
  final AuthService _auth = AuthService();

  bool _loading = true;
  String? _error;
  final List<PsychTestChecklist> _checklists = [];
  int _stageIndex = 0;
  int? _resultId;
  PsychTestChecklist? get _checklist => _checklists.isEmpty ? null : _checklists[_stageIndex];

  // questionId -> rank(1,2,3)
  final Map<int, int> _selectedRanks = {};
  bool _limitSnackVisible = false;
  int _roundIndex = 0; // 0: 1st, 1: 2nd, 2: 3rd

  List<int> get _roundTargets {
    final c = _checklist;
    if (c == null) return [3, 4, 5];
    return [c.firstCount, c.secondCount, c.thirdCount];
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!_auth.isLoggedIn) {
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
    await _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await _service.fetchChecklists(widget.testId);
      if (!mounted) return;
      if (lists.isEmpty) {
        setState(() {
          _loading = false;
          _error = '체크리스트가 비어 있습니다.';
        });
        return;
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
    if (!mounted || index < 0 || index >= _checklists.length) return;
    setState(() {
      _stageIndex = index;
      _roundIndex = 0;
      _selectedRanks.clear();
      _limitSnackVisible = false;
      if (index == 0) _resultId = null;
      _loading = false;
      _error = null;
    });
  }

  void _toggleSelect(PsychTestItem item) {
    final currentRank = _roundIndex + 1;
    final locked = _selectedRanks[item.id] != null && _selectedRanks[item.id]! < currentRank;
    if (locked) return;

    final currentSelections =
        _selectedRanks.entries.where((e) => e.value == currentRank).map((e) => e.key).toList();
    final alreadySelected = _selectedRanks[item.id] == currentRank;

    if (alreadySelected) {
      setState(() => _selectedRanks.remove(item.id));
      return;
    }

    final target = _roundTargets[_roundIndex];
    if (currentSelections.length >= target) {
      if (_limitSnackVisible) return;
      final messenger = ScaffoldMessenger.of(context);
      _limitSnackVisible = true;
      messenger.hideCurrentSnackBar();
      messenger
          .showSnackBar(
            SnackBar(
              content: Text('최대 ${target}개까지 선택할 수 있습니다. 다른 항목을 해제해주세요.'),
              duration: const Duration(seconds: 2),
            ),
          )
          .closed
          .whenComplete(() {
        if (mounted) {
          setState(() => _limitSnackVisible = false);
        } else {
          _limitSnackVisible = false;
        }
      });
      return;
    }

    setState(() {
      _selectedRanks[item.id] = currentRank;
    });
  }

  void _removeFromCurrentRound(int id) {
    final rank = _roundIndex + 1;
    if (_selectedRanks[id] == rank) {
      setState(() => _selectedRanks.remove(id));
    }
  }

  Future<void> _goNext() async {
    final target = _roundTargets[_roundIndex];
    final count = _selectedRanks.values.where((v) => v == _roundIndex + 1).length;
    if (count != target) return;

    if (_roundIndex < 2) {
      setState(() => _roundIndex += 1);
      return;
    }

    final checklist = _checklist;
    if (checklist == null) return;

    final selections = WpiSelections(
      checklistId: checklist.id,
      rank1: _selectedRanks.entries.where((e) => e.value == 1).map((e) => e.key).toList(),
      rank2: _selectedRanks.entries.where((e) => e.value == 2).map((e) => e.key).toList(),
      rank3: _selectedRanks.entries.where((e) => e.value == 3).map((e) => e.key).toList(),
    );

    if (!mounted) return;
    final isLastStage = _stageIndex + 1 >= _checklists.length;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WpiReviewScreen(
          testId: widget.testId,
          testTitle: '${widget.testTitle} · ${checklist.name}',
          items: checklist.questions,
          selections: selections,
          processSequence: checklist.sequence == 0 ? _stageIndex + 1 : checklist.sequence,
          deferNavigation: !isLastStage,
          existingResultId: _resultId,
        ),
      ),
    );

    if (!mounted) return;
    if (!isLastStage) {
      if (result == null) return;
      _resultId ??= _extractResultId(result);
      _prepareStage(_stageIndex + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다음 체크리스트로 이동합니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          title: const Text('WPI 오류'),
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadChecklist,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final currentRank = _roundIndex + 1;
    final target = _roundTargets[_roundIndex];
    final checklist = _checklist!;
    final currentSelections =
        _selectedRanks.entries.where((e) => e.value == currentRank).map((e) => e.key).toList();
    final canProceed = currentSelections.length == target;
    final stageLabel = '${_stageIndex + 1}/${_checklists.length} ${checklist.name}';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('${widget.testTitle} · $stageLabel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _StickyHeader(
            brandRed: _brandRed,
            roundLabel: _roundLabel(currentRank),
            countLabel: '${currentSelections.length}/$target 선택',
            criteria: '순서대로 ${target}개를 선택해주세요.',
            reassurance: '',
            slotCount: target,
            selectedIds: currentSelections,
            checklist: checklist,
            onRemove: _removeFromCurrentRound,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: checklist.questions.length,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = checklist.questions[index];
                final rank = _selectedRanks[item.id];
                final selected = rank == currentRank;
                return _WpiItemCard(
                  brandRed: _brandRed,
                  number: index + 1,
                  item: item,
                  lockedRank: rank,
                  selected: selected,
                  onTap: () => _toggleSelect(item),
                );
              },
            ),
          ),
          _BottomCta(
            brandRed: _brandRed,
            canProceed: canProceed,
            primaryLabel: _roundIndex == 2 ? '확인하기' : '${_roundIndex + 2}순위로',
            onNext: _goNext,
          ),
        ],
      ),
    );
  }

  String _roundLabel(int rank) => '$rank순위';

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

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.brandRed,
    required this.roundLabel,
    required this.countLabel,
    required this.criteria,
    required this.reassurance,
    required this.slotCount,
    required this.selectedIds,
    required this.checklist,
    required this.onRemove,
  });

  final Color brandRed;
  final String roundLabel;
  final String countLabel;
  final String criteria;
  final String reassurance;
  final int slotCount;
  final List<int> selectedIds;
  final PsychTestChecklist checklist;
  final void Function(int id) onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  roundLabel,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  countLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택 기준: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(
                    criteria,
                    style: AppTextStyles.bodySmall.copyWith(color: brandRed, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (reassurance.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reassurance,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            Text('현재 선택', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              height: 60,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(slotCount, (index) {
                    final hasValue = index < selectedIds.length;
                    final padding = EdgeInsets.only(right: index == slotCount - 1 ? 0 : 8);
                    if (hasValue) {
                      final id = selectedIds[index];
                      final questionIndex = checklist.questions.indexWhere((e) => e.id == id);
                      final label = questionIndex >= 0 ? '${questionIndex + 1}' : '${index + 1}';
                      final text = questionIndex >= 0 ? _cleanText(checklist.questions[questionIndex].text) : '';
                      return Padding(
                        padding: padding,
                        child: InputChip(
                          label: SizedBox(
                            width: 160,
                            child: Text(
                              '$label. $text',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onDeleted: () => onRemove(id),
                          backgroundColor: brandRed.withOpacity(0.08),
                          deleteIconColor: brandRed,
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: brandRed,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(color: brandRed),
                        ),
                      );
                    }
                    return Padding(
                      padding: padding,
                      child: Container(
                        height: 36,
                        width: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300, width: 1.2),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanText(String text) => text.replaceAll(RegExp(r'\(.*?\)'), '').trim();
}

class _WpiItemCard extends StatefulWidget {
  const _WpiItemCard({
    required this.brandRed,
    required this.number,
    required this.item,
    required this.lockedRank,
    required this.selected,
    required this.onTap,
  });

  final Color brandRed;
  final int number;
  final PsychTestItem item;
  final int? lockedRank;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_WpiItemCard> createState() => _WpiItemCardState();
}

class _WpiItemCardState extends State<_WpiItemCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    final locked =
        widget.lockedRank != null && widget.lockedRank! < 3 && widget.lockedRank! > 0 && !widget.selected;
    if (locked) return;
    if (!widget.selected && !kIsWeb) {
      HapticFeedback.lightImpact();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final locked =
        widget.lockedRank != null && widget.lockedRank! < 3 && widget.lockedRank! > 0 && !widget.selected;
    return MouseRegion(
      cursor: locked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: locked ? null : () {},
          onTapDown: locked ? null : (_) => _setPressed(true),
          onTapCancel: locked ? null : () => _setPressed(false),
          onTapUp: locked ? null : (_) => _setPressed(false),
          mouseCursor: locked ? SystemMouseCursors.basic : SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '${widget.number}. ${_cleanText(widget.item.text)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: locked ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: locked ? null : _handleTap,
                  child: AnimatedScale(
                    scale: _isPressed ? 0.94 : 1,
                    duration:
                        _isPressed ? const Duration(milliseconds: 90) : const Duration(milliseconds: 240),
                    curve: _isPressed ? Curves.easeOutQuad : Curves.elasticOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.selected
                            ? widget.brandRed
                            : (_isPressed ? Colors.grey.shade100 : Colors.white),
                        border: Border.all(
                          color: widget.selected ? widget.brandRed : AppColors.border,
                          width: widget.selected ? 2 : 1.5,
                        ),
                        boxShadow: widget.selected
                            ? [
                                BoxShadow(
                                  color: widget.brandRed.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedOpacity(
                        opacity: widget.selected ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: AnimatedScale(
                          scale: widget.selected ? 1 : 0.6,
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutBack,
                          child: const Icon(Icons.check, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cleanText(String text) => text.replaceAll(RegExp(r'\(.*?\)'), '').trim();
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.brandRed,
    required this.canProceed,
    required this.primaryLabel,
    required this.onNext,
  });

  final Color brandRed;
  final bool canProceed;
  final String primaryLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: canProceed ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? brandRed : AppColors.disabled,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text(primaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
