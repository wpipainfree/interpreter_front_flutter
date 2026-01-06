import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/psych_tests_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class UserResultDetailScreen extends StatefulWidget {
  const UserResultDetailScreen({
    super.key,
    required this.resultId,
    this.testId,
  });

  final int resultId;
  final int? testId;

  @override
  State<UserResultDetailScreen> createState() => _UserResultDetailScreenState();
}

class _UserResultDetailScreenState extends State<UserResultDetailScreen> {
  final PsychTestsService _service = PsychTestsService();

  bool _loading = true;
  String? _error;
  UserResultDetail? _detail;

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
      final res = await _service.fetchResultDetail(widget.resultId);
      if (!mounted) return;
      setState(() => _detail = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('검사 결과', style: AppTextStyles.h4),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final detail = _detail!;
    final result = detail.result;
    final testName = _testName(result.testId ?? widget.testId);
    final date = _formatDateTime(result.createdAt);

    // Extract five-point self/other scores in the order needed for the chart/table.
    final selfLabels = ['Realist', 'Romanticist', 'Humanist', 'Idealist', 'Agent'];
    final otherLabels = ['Relation', 'Trust', 'Manual', 'Self', 'Culture'];
    final selfScores = _extractScores(
      detail.classes,
      selfLabels,
      checklistNameContains: '자기',
    );
    final otherScores = _extractScores(
      detail.classes,
      otherLabels,
      checklistNameContains: '타인',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryCard(testName, result, date),
          const SizedBox(height: 16),
          _legend(),
          const SizedBox(height: 8),
          _interactiveLineChart(selfScores, otherScores, selfLabels, otherLabels),
          const SizedBox(height: 16),
          _ctaRow(selfLabels, selfScores, otherLabels, otherScores),
        ],
      ),
    );
  }

  Widget _summaryCard(String testName, UserResultRow result, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(testName, style: AppTextStyles.h4),
            ],
          ),
          const SizedBox(height: 6),
          Text(date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('검사자 ${result.testTargetName?.isNotEmpty == true ? result.testTargetName : '미입력'}'),
              _chip('결과 유형 ${result.description ?? '-'}'),
              if (result.worry != null && result.worry!.isNotEmpty) _chip('고민/걱정 ${result.worry}'),
            ],
          ),
          if (result.note != null && result.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('메모', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(result.note!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: Colors.red, label: '자기평가'),
        SizedBox(width: 16),
        _LegendDot(color: Colors.blue, label: '타인평가'),
      ],
    );
  }

  Widget _interactiveLineChart(
    List<double?> selfScores,
    List<double?> otherScores,
    List<String> selfLabels,
    List<String> otherLabels,
  ) {
    return _LineChartArea(
      selfScores: selfScores,
      otherScores: otherScores,
      selfLabels: selfLabels,
      otherLabels: otherLabels,
    );
  }

  Widget _scoreTable(
    List<String> selfLabels,
    List<double?> selfScores,
    List<String> otherLabels,
    List<double?> otherScores,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tableSection(
          title: '자기평가',
          titleColor: Colors.red,
          headerBg: const Color(0xFFFFEEF2),
          labels: selfLabels,
          scores: selfScores,
        ),
        const SizedBox(height: 12),
        _tableSection(
          title: '타인평가',
          titleColor: Colors.blue,
          headerBg: const Color(0xFFE8EDFF),
          labels: otherLabels,
          scores: otherScores,
        ),
      ],
    );
  }

  Widget _ctaRow(
    List<String> selfLabels,
    List<double?> selfScores,
    List<String> otherLabels,
    List<double?> otherScores,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: hook to interpretation card
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('해석 카드 열기'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: _scoreTable(selfLabels, selfScores, otherLabels, otherScores),
                    ),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('점수표 보기'),
          ),
        ),
      ],
    );
  }

  Widget _tableSection({
    required String title,
    required Color titleColor,
    required Color headerBg,
    required List<String> labels,
    required List<double?> scores,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(80),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: AppColors.border),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: headerBg),
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(title, style: AppTextStyles.bodyMedium.copyWith(color: titleColor, fontWeight: FontWeight.w700)),
              ),
              ...labels.map(
                (label) => Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(color: titleColor, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text('점수', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ),
              ...scores.map(
                (score) => Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    score != null ? score.toStringAsFixed(1).replaceAll(RegExp(r'\\.0\$'), '') : '-',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
    );
  }

  String _testName(int? testId) {
    if (testId == 1) return 'WPI(현실)';
    if (testId == 3) return 'WPI(이상)';
    return 'WPI';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<double?> _extractScores(
    List<ResultClassItem> items,
    List<String> labels, {
    String? checklistNameContains,
  }) {
    final map = <String, double?>{};
    for (final item in items) {
      final name = _normalize(item.name ?? item.checklistName ?? '');
      if (checklistNameContains != null) {
        final ckName = item.checklistName ?? '';
        if (!ckName.contains(checklistNameContains)) continue;
      }
      final value = item.point;
      if (labels.any((l) => _normalize(l) == name)) {
        map[name] = value;
      }
    }
    return labels
        .map((l) {
          final key = _normalize(l);
          return map[key];
        })
        .toList();
  }

  String _normalize(String raw) {
    final normalized = raw.toLowerCase().replaceAll(' ', '').split('/').first;
    if (normalized == 'romantist') return 'romanticist';
    return normalized;
  }

}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _LineChartArea extends StatefulWidget {
  const _LineChartArea({
    required this.selfScores,
    required this.otherScores,
    required this.selfLabels,
    required this.otherLabels,
  });

  final List<double?> selfScores;
  final List<double?> otherScores;
  final List<String> selfLabels;
  final List<String> otherLabels;

  @override
  State<_LineChartArea> createState() => _LineChartAreaState();
}

class _LineChartAreaState extends State<_LineChartArea> {
  int? _selected;

  static const _paddingLeft = 32.0;
  static const _paddingRight = 12.0;
  static const _paddingTop = 16.0;
  static const _paddingBottom = 28.0;
  static const _chartHeight = 260.0;

  @override
  Widget build(BuildContext context) {
    final maxVal = _maxValue(widget.selfScores, widget.otherScores);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final chartWidth = width - _paddingLeft - _paddingRight;
            final positions = List.generate(widget.selfScores.length, (i) {
              return _paddingLeft + (chartWidth / (widget.selfScores.length - 1)) * i;
            });

            return Stack(
              children: [
                SizedBox(
                  height: _chartHeight,
                  width: width,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final x = d.localPosition.dx;
                      int nearest = 0;
                      double minDist = double.infinity;
                      for (var i = 0; i < positions.length; i++) {
                        final dist = (positions[i] - x).abs();
                        if (dist < minDist) {
                          minDist = dist;
                          nearest = i;
                        }
                      }
                      setState(() => _selected = nearest);
                    },
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        selfScores: widget.selfScores,
                        otherScores: widget.otherScores,
                        maxValue: maxVal,
                        paddingLeft: _paddingLeft,
                        paddingRight: _paddingRight,
                        paddingTop: _paddingTop,
                        paddingBottom: _paddingBottom,
                        showPointLabels: false,
                      ),
                    ),
                  ),
                ),
                if (_selected != null)
                  Positioned(
                    left: () {
                      final raw = positions[_selected!] - 60;
                      final minX = 8.0;
                      final maxX = width - 140;
                      return raw.clamp(minX, maxX);
                    }(),
                    top: 12,
                    child: _TooltipBox(
                      selfScore: widget.selfScores[_selected!],
                      otherScore: widget.otherScores[_selected!],
                      selfLabel: widget.selfLabels[_selected!],
                      otherLabel: widget.otherLabels[_selected!],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _xLabels(widget.selfLabels, widget.otherLabels),
      ],
    );
  }

  Widget _xLabels(List<String> selfLabels, List<String> otherLabels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth / selfLabels.length).clamp(40.0, 120.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(selfLabels.length, (i) {
            return SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  Text(
                    selfLabels[i],
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    otherLabels[i],
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.w700, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  double _maxValue(List<double?> a, List<double?> b) {
    final vals = <double>[
      ...a.whereType<double>(),
      ...b.whereType<double>(),
    ];
    final double maxVal = vals.isEmpty ? 100 : vals.reduce(max);
    return max(maxVal, 100.0);
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.selfScores,
    required this.otherScores,
    required this.maxValue,
    required this.paddingLeft,
    required this.paddingRight,
    required this.paddingTop,
    required this.paddingBottom,
    required this.showPointLabels,
  });

  final List<double?> selfScores;
  final List<double?> otherScores;
  final double maxValue;
  final double paddingLeft;
  final double paddingRight;
  final double paddingTop;
  final double paddingBottom;
  final bool showPointLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const ySteps = 10;
    for (var i = 0; i <= ySteps; i++) {
      final ratio = i / ySteps;
      final y = paddingTop + chartHeight * (1 - ratio);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), paintGrid);

      final value = (maxValue / ySteps) * i;
      textPainter
        ..text = TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        )
        ..layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    final positions = List.generate(selfScores.length, (i) {
      final x = paddingLeft + (chartWidth / (selfScores.length - 1)) * i;
      return x;
    });

    void drawSeries(List<double?> data, Color color) {
      final path = Path();
      for (var i = 0; i < data.length; i++) {
        final v = (data[i] ?? 0).clamp(0, maxValue);
        final ratio = v / maxValue;
        final y = paddingTop + chartHeight * (1 - ratio);
        final x = positions[i];
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      for (var i = 0; i < data.length; i++) {
        final v = (data[i] ?? 0).clamp(0, maxValue);
        final ratio = v / maxValue;
        final y = paddingTop + chartHeight * (1 - ratio);
        final x = positions[i];
        canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = color);
        if (showPointLabels) {
          final label = data[i]?.toStringAsFixed(1).replaceAll(RegExp(r'\\.0\$'), '') ?? '0';
          textPainter
            ..text = TextSpan(
              text: label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
            )
            ..layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height - 6));
        }
      }
    }

    drawSeries(otherScores, Colors.blue);
    drawSeries(selfScores, Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TooltipBox extends StatelessWidget {
  const _TooltipBox({
    required this.selfScore,
    required this.otherScore,
    required this.selfLabel,
    required this.otherLabel,
  });

  final double? selfScore;
  final double? otherScore;
  final String selfLabel;
  final String otherLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$selfLabel: ${selfScore?.toStringAsFixed(1) ?? '-'}',
                style: AppTextStyles.caption.copyWith(color: Colors.red, fontWeight: FontWeight.w700)),
            Text('$otherLabel: ${otherScore?.toStringAsFixed(1) ?? '-'}',
                style: AppTextStyles.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
