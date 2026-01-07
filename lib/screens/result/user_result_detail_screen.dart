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
          const SizedBox(height: 12),
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
    final targetName = result.testTargetName?.isNotEmpty == true ? result.testTargetName! : '미입력';
    final desc = result.description ?? '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$testName · $date', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('검사자 $targetName · 유형 $desc', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
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
      startOffset: _LineChartAreaState._startOffset,
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
    this.startOffset = 0,
  });

  final List<double?> selfScores;
  final List<double?> otherScores;
  final List<String> selfLabels;
  final List<String> otherLabels;
  final double startOffset;

  @override
  State<_LineChartArea> createState() => _LineChartAreaState();
}

class _LineChartAreaState extends State<_LineChartArea> {
  int? _selected;

  static const _paddingLeft = 32.0;
  static const _paddingRight = 12.0;
  static const _paddingTop = 14.0;
  static const _paddingBottom = 32.0;
  static const _startOffset = 10.0;
  static const _chartHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final maxVal = _maxValue(widget.selfScores, widget.otherScores);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final chartWidth = width - _paddingLeft - _paddingRight - (_startOffset * 2);
            final positions = List.generate(widget.selfScores.length, (i) {
              return _paddingLeft + _startOffset + (chartWidth / (widget.selfScores.length - 1)) * i;
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
                        startOffset: widget.startOffset,
                        showPointLabels: true,
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

class _LabelInfo {
  const _LabelInfo({
    required this.index,
    required this.isSelf,
    required this.anchor,
    required this.textPainter,
    required this.color,
  });

  final int index;
  final bool isSelf;
  final Offset anchor;
  final TextPainter textPainter;
  final Color color;

  Size get size => textPainter.size;
}

class _LabelCandidate {
  const _LabelCandidate({
    required this.info,
    required this.rect,
    required this.collisionRect,
  });

  final _LabelInfo info;
  final Rect rect;
  final Rect collisionRect;
}

class _PairPlacement {
  const _PairPlacement({
    required this.selfCandidate,
    required this.otherCandidate,
  });

  final _LabelCandidate selfCandidate;
  final _LabelCandidate otherCandidate;
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
    this.startOffset = 0,
    required this.showPointLabels,
  });

  final List<double?> selfScores;
  final List<double?> otherScores;
  final double maxValue;
  final double paddingLeft;
  final double paddingRight;
  final double paddingTop;
  final double paddingBottom;
  final double startOffset;
  final bool showPointLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - paddingLeft - paddingRight - (startOffset * 2);
    final chartHeight = size.height - paddingTop - paddingBottom;
    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

    const stepValue = 20.0;
    final steps = max(1, (maxValue / stepValue).ceil());
    for (var i = 0; i <= steps; i++) {
      final ratio = i / steps;
      final y = paddingTop + chartHeight * (1 - ratio);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), paintGrid);

      final value = stepValue * i;
      axisTextPainter
        ..text = TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        )
        ..layout();
      axisTextPainter.paint(
        canvas,
        Offset(paddingLeft - axisTextPainter.width - 6, y - axisTextPainter.height / 2),
      );
    }

    final positions = List.generate(selfScores.length, (i) {
      final x = paddingLeft + startOffset + (chartWidth / (selfScores.length - 1)) * i;
      return x;
    });

    double valueToY(double? value) {
      final v = (value ?? 0).clamp(0, maxValue);
      final ratio = v / maxValue;
      return paddingTop + chartHeight * (1 - ratio);
    }

    final selfPoints = List<Offset>.generate(
      selfScores.length,
      (i) => Offset(positions[i], valueToY(selfScores[i])),
    );
    final otherPoints = List<Offset>.generate(
      otherScores.length,
      (i) => Offset(positions[i], valueToY(otherScores[i])),
    );

    void drawSeries(List<Offset> points, Color color) {
      if (points.isEmpty) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      for (final point in points) {
        canvas.drawCircle(point, 5, Paint()..color = color);
      }
    }

    drawSeries(otherPoints, Colors.blue);
    drawSeries(selfPoints, Colors.red);

    if (!showPointLabels) return;

    // ---------------------------------------------------------------------
    // Label placement rules (no leader lines, point-outward, no skip):
    //
    // 1) Labels use LabelSafeRect (whole chart) so first/last never disappear.
    // 2) Each index is a pair; labels are placed together to avoid ambiguity.
    // 3) Labels must stay OUT of the pair corridor (the vertical band between
    //    the two points), or the eye will mis-assign the value.
    // 4) The upper point's label goes above, the lower point's label goes
    //    below (outward from the pair). Color does not decide direction.
    // 5) The label center must be closer to its own point than the other point.
    // 6) Only small moves are allowed: L1/L2 lanes and dx offsets 0, +8, -8, +16, -16.
    // 7) Never skip: if L1/L2 fail, shrink font once, then allow L3.
    // ---------------------------------------------------------------------
    const markerRadius = 5.0;
    const pointLabelGap = 8.0;
    const laneGap = 3.0;
    const labelGap = 4.0;
    const safeInset = 4.0;
    const corridorPad = 8.0;
    const corridorSidePad = 4.0;
    const fontSizePrimary = 11.0;
    const fontSizeFallback = 10.0;

    final labelSafeRect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(safeInset);

    String formatLabel(double? value) {
      return (value ?? 0).toStringAsFixed(1).replaceAll(RegExp(r'\.0\$'), '');
    }

    final selfTexts = selfScores.map(formatLabel).toList();
    final otherTexts = otherScores.map(formatLabel).toList();

    _LabelInfo buildLabelInfo({
      required int index,
      required bool isSelf,
      required double fontSize,
    }) {
      final anchor = isSelf ? selfPoints[index] : otherPoints[index];
      final text = isSelf ? selfTexts[index] : otherTexts[index];
      final style = TextStyle(
        fontSize: fontSize,
        color: isSelf ? Colors.red : Colors.blue,
        fontWeight: FontWeight.w700,
      );
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(text: text, style: style)
        ..layout();
      return _LabelInfo(
        index: index,
        isSelf: isSelf,
        anchor: anchor,
        textPainter: painter,
        color: style.color ?? Colors.black,
      );
    }

    int alignModeForIndex(int index, int lastIndex) {
      // -1 = left-align (text grows right), 0 = center, 1 = right-align (text grows left).
      if (index == 0) return -1;
      if (index == lastIndex) return 1;
      return 0;
    }

    double alignedLeft(double anchorX, double width, int alignMode, double dx) {
      if (alignMode < 0) return anchorX + dx;
      if (alignMode > 0) return anchorX - width + dx;
      return anchorX - width / 2 + dx;
    }

    List<List<int>> laneCombosForMax(int maxLane) {
      final combos = <List<int>>[];
      void add(int a, int b) => combos.add([a, b]);
      add(1, 1);
      if (maxLane >= 2) {
        add(2, 1);
        add(1, 2);
        add(2, 2);
      }
      if (maxLane >= 3) {
        add(3, 1);
        add(1, 3);
        add(3, 2);
        add(2, 3);
        add(3, 3);
      }
      return combos;
    }

    List<List<double>> dxPairsForAlign(int alignMode) {
      if (alignMode < 0) return const [
        [0, 0],
        [8, 8],
        [16, 16],
      ];
      if (alignMode > 0) return const [
        [0, 0],
        [-8, -8],
        [-16, -16],
      ];
      return const [
        [0, 0],
        [8, -8],
        [-8, 8],
        [16, -16],
        [-16, 16],
      ];
    }

    Rect clampToSafeRect(Rect rect) {
      var dx = 0.0;
      var dy = 0.0;

      if (rect.left < labelSafeRect.left) {
        dx = labelSafeRect.left - rect.left;
      }
      if (rect.right + dx > labelSafeRect.right) {
        dx = labelSafeRect.right - rect.right;
      }
      if (rect.top < labelSafeRect.top) {
        dy = labelSafeRect.top - rect.top;
      }
      if (rect.bottom + dy > labelSafeRect.bottom) {
        dy = labelSafeRect.bottom - rect.bottom;
      }

      return rect.shift(Offset(dx, dy));
    }

    bool rectFitsSafeRect(Rect rect) {
      return rect.left >= labelSafeRect.left &&
          rect.top >= labelSafeRect.top &&
          rect.right <= labelSafeRect.right &&
          rect.bottom <= labelSafeRect.bottom;
    }

    Rect pairCorridorRect(_LabelInfo a, _LabelInfo b) {
      final minY = min(a.anchor.dy, b.anchor.dy) - corridorPad;
      final maxY = max(a.anchor.dy, b.anchor.dy) + corridorPad;
      final halfWidth = max(a.size.width, b.size.width) / 2 + corridorSidePad;
      final centerX = a.anchor.dx;
      return Rect.fromLTRB(centerX - halfWidth, minY, centerX + halfWidth, maxY);
    }

    double dist2(Offset a, Offset b) {
      final dx = a.dx - b.dx;
      final dy = a.dy - b.dy;
      return (dx * dx) + (dy * dy);
    }

    bool closerToOwnPoint(_LabelInfo info, Offset otherAnchor, Rect rect) {
      final center = rect.center;
      final selfDist = dist2(center, info.anchor);
      final otherDist = dist2(center, otherAnchor);
      return selfDist < otherDist - 0.5;
    }

    Rect buildLabelRect({
      required _LabelInfo info,
      required bool isTop,
      required int lane,
      required double dx,
      required int alignMode,
    }) {
      final laneOffset = (info.size.height + laneGap) * (lane - 1);
      final top = isTop
          ? info.anchor.dy - pointLabelGap - info.size.height - laneOffset
          : info.anchor.dy + pointLabelGap + laneOffset;
      final left = alignedLeft(info.anchor.dx, info.size.width, alignMode, dx);
      return Rect.fromLTWH(left, top, info.size.width, info.size.height);
    }

    _LabelCandidate? buildCandidate({
      required _LabelInfo info,
      required bool isTop,
      required int lane,
      required double dx,
      required int alignMode,
    }) {
      final rawRect = buildLabelRect(
        info: info,
        isTop: isTop,
        lane: lane,
        dx: dx,
        alignMode: alignMode,
      );
      final rect = clampToSafeRect(rawRect);
      if (!rectFitsSafeRect(rect)) return null;

      // Do not allow a label to overlap its own marker.
      final markerRect = Rect.fromCircle(center: info.anchor, radius: markerRadius + 1);
      if (rect.overlaps(markerRect)) return null;

      return _LabelCandidate(
        info: info,
        rect: rect,
        collisionRect: rect.inflate(labelGap / 2),
      );
    }

    final placedCollisionRects = <Rect>[];
    final placements = <_LabelCandidate>[];

    bool overlapsPlaced(Rect collisionRect) {
      for (final placed in placedCollisionRects) {
        if (collisionRect.overlaps(placed)) return true;
      }
      return false;
    }

    _PairPlacement? tryPlacePair({
      required _LabelInfo selfInfo,
      required _LabelInfo otherInfo,
      required bool selfIsTopPoint,
      required int alignMode,
      required int maxLane,
      required bool allowPlacedOverlap,
    }) {
      final laneCombos = laneCombosForMax(maxLane);
      final dxPairs = dxPairsForAlign(alignMode);
      final corridor = pairCorridorRect(selfInfo, otherInfo);

      for (final dxPair in dxPairs) {
        final selfDx = dxPair[0];
        final otherDx = dxPair[1];

        for (final lanes in laneCombos) {
          final selfCandidate = buildCandidate(
            info: selfInfo,
            isTop: selfIsTopPoint,
            lane: lanes[0],
            dx: selfDx,
            alignMode: alignMode,
          );
          final otherCandidate = buildCandidate(
            info: otherInfo,
            isTop: !selfIsTopPoint,
            lane: lanes[1],
            dx: otherDx,
            alignMode: alignMode,
          );
          if (selfCandidate == null || otherCandidate == null) continue;

          // Reject if any label enters the corridor between the two points.
          if (selfCandidate.rect.overlaps(corridor)) continue;
          if (otherCandidate.rect.overlaps(corridor)) continue;

          // Reject if a label is closer to the other point (confusion risk).
          if (!closerToOwnPoint(selfInfo, otherInfo.anchor, selfCandidate.rect)) continue;
          if (!closerToOwnPoint(otherInfo, selfInfo.anchor, otherCandidate.rect)) continue;

          if (selfCandidate.collisionRect.overlaps(otherCandidate.collisionRect)) continue;
          if (!allowPlacedOverlap && overlapsPlaced(selfCandidate.collisionRect)) continue;
          if (!allowPlacedOverlap && overlapsPlaced(otherCandidate.collisionRect)) continue;

          return _PairPlacement(
            selfCandidate: selfCandidate,
            otherCandidate: otherCandidate,
          );
        }
      }
      return null;
    }

    for (var i = 0; i < selfPoints.length; i++) {
      final alignMode = alignModeForIndex(i, selfPoints.length - 1);
      final selfIsTopPoint = selfPoints[i].dy <= otherPoints[i].dy;

      final selfPrimary = buildLabelInfo(index: i, isSelf: true, fontSize: fontSizePrimary);
      final otherPrimary = buildLabelInfo(index: i, isSelf: false, fontSize: fontSizePrimary);

      // Primary: outward placement using L1/L2 and the base font size.
      var placement = tryPlacePair(
        selfInfo: selfPrimary,
        otherInfo: otherPrimary,
        selfIsTopPoint: selfIsTopPoint,
        alignMode: alignMode,
        maxLane: 2,
        allowPlacedOverlap: false,
      );

      // Fallback 1: shrink font one step and retry L1/L2.
      if (placement == null) {
        final selfSmall = buildLabelInfo(index: i, isSelf: true, fontSize: fontSizeFallback);
        final otherSmall = buildLabelInfo(index: i, isSelf: false, fontSize: fontSizeFallback);
        placement = tryPlacePair(
          selfInfo: selfSmall,
          otherInfo: otherSmall,
          selfIsTopPoint: selfIsTopPoint,
          alignMode: alignMode,
          maxLane: 2,
          allowPlacedOverlap: false,
        );

        // Fallback 2: allow L3 with the smaller font.
        placement ??= tryPlacePair(
          selfInfo: selfSmall,
          otherInfo: otherSmall,
          selfIsTopPoint: selfIsTopPoint,
          alignMode: alignMode,
          maxLane: 3,
          allowPlacedOverlap: false,
        );

        // Fallback 3 (no-skip): last resort allows overlap with other indices.
        placement ??= tryPlacePair(
          selfInfo: selfSmall,
          otherInfo: otherSmall,
          selfIsTopPoint: selfIsTopPoint,
          alignMode: alignMode,
          maxLane: 3,
          allowPlacedOverlap: true,
        );
      }

      if (placement == null) continue;

      final pairCandidates = [placement.selfCandidate, placement.otherCandidate];
      for (final candidate in pairCandidates) {
        placements.add(candidate);
        placedCollisionRects.add(candidate.collisionRect);
      }
    }

    for (final placement in placements) {
      placement.info.textPainter.paint(canvas, placement.rect.topLeft);
    }
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
