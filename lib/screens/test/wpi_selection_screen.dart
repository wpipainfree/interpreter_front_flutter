import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';
import 'wpi_review_screen.dart';

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
  PsychTestChecklist? _checklist;

  // questionId -> rank(1,2,3)
  final Map<int, int> _selectedRanks = {};
  int _roundIndex = 0; // 0: 1순위, 1: 2순위, 2: 3순위

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
      final checklist = await _service.fetchChecklist(widget.testId);
      if (!mounted) return;
      setState(() {
        _checklist = checklist;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이번 라운드는 ${target}개를 선택합니다. 위 칩에서 ✕로 빼고 다시 골라주세요.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedRanks[item.id] = currentRank;
    });
  }

  void _resetCurrentRound() {
    final rank = _roundIndex + 1;
    final ids = _selectedRanks.entries.where((e) => e.value == rank).map((e) => e.key).toList();
    if (ids.isEmpty) return;
    for (final id in ids) {
      _selectedRanks.remove(id);
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이번 라운드 선택을 초기화했어요.')),
    );
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
      rank1: _selectedRanks.entries.where((e) => e.value == 1).map((e) => e.key).toList(),
      rank2: _selectedRanks.entries.where((e) => e.value == 2).map((e) => e.key).toList(),
      rank3: _selectedRanks.entries.where((e) => e.value == 3).map((e) => e.key).toList(),
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WpiReviewScreen(
          testId: widget.testId,
          testTitle: widget.testTitle,
          items: checklist.questions,
          selections: selections,
        ),
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
          title: const Text('WPI 검사'),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('${widget.testTitle} - ${_roundLabel(currentRank, target)}'),
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
            roundLabel: _roundLabel(currentRank, target),
            countLabel: '선택 ${currentSelections.length}/$target',
            criteria: '지금의 나를 가장 잘 나타내는 문장',
            reassurance: '지금은 담고, 마지막 검토에서 1·2·3순위를 한 번 더 정리합니다.',
            chips: _buildChips(currentSelections, checklist),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: checklist.questions.length,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = checklist.questions[index];
                final rank = _selectedRanks[item.id];
                final selected = rank == currentRank;
                return _WpiItemCard(
                  brandRed: _brandRed,
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
            primaryLabel: _roundIndex == 2 ? '검토로' : '${_roundIndex + 2}순위로',
            onReset: currentSelections.isNotEmpty ? _resetCurrentRound : null,
            onNext: _goNext,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChips(List<int> ids, PsychTestChecklist checklist) {
    if (ids.isEmpty) {
      return [Text('이번 라운드 선택 없음', style: AppTextStyles.caption)];
    }
    return ids
        .map(
          (id) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InputChip(
              label: Text(
                _cleanText(checklist.questions.firstWhere((e) => e.id == id).text),
                overflow: TextOverflow.ellipsis,
              ),
              onDeleted: () => _removeFromCurrentRound(id),
            ),
          ),
        )
        .toList();
  }

  String _roundLabel(int rank, int target) {
    return '$rank순위 ($target개)';
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\\(.*?\\)'), '').trim();
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.brandRed,
    required this.roundLabel,
    required this.countLabel,
    required this.criteria,
    required this.reassurance,
    required this.chips,
  });

  final Color brandRed;
  final String roundLabel;
  final String countLabel;
  final String criteria;
  final String reassurance;
  final List<Widget> chips;

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
            const SizedBox(height: 4),
            Text(
              reassurance,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text('이번 라운드 선택', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ],
        ),
      ),
    );
  }
}

class _WpiItemCard extends StatelessWidget {
  const _WpiItemCard({
    required this.brandRed,
    required this.item,
    required this.lockedRank,
    required this.selected,
    required this.onTap,
  });

  final Color brandRed;
  final PsychTestItem item;
  final int? lockedRank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = lockedRank != null && lockedRank! < 3 && lockedRank! > 0 && !selected;
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lockedRank != null && lockedRank! < 3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${lockedRank}순위 선택됨',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  Text(
                    item.text.replaceAll(RegExp(r'\\(.*?\\)'), '').trim(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: locked ? AppColors.textHint : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: locked ? null : onTap,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? brandRed : Colors.white,
                  border: Border.all(
                    color: selected ? brandRed : AppColors.border,
                    width: selected ? 2 : 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.brandRed,
    required this.canProceed,
    required this.primaryLabel,
    required this.onNext,
    required this.onReset,
  });

  final Color brandRed;
  final bool canProceed;
  final String primaryLabel;
  final VoidCallback onNext;
  final VoidCallback? onReset;

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
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReset,
              child: const Text('이번 라운드 다시 고르기'),
            ),
          ],
        ),
      ),
    );
  }
}

