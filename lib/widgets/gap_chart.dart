import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/date.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The most recent gaps drawn; older ones would make each bar too thin.
const gapChartMax = 12;

/// Days between consecutive records, oldest first, the newest [gapChartMax].
List<int> recordGaps(Card card) {
  final gaps = <int>[
    for (var i = card.recs.length - 1; i > 0; i--)
      daysSince(card.recs[i], card.recs[i - 1]),
  ];
  return gaps.length > gapChartMax
      ? gaps.sublist(gaps.length - gapChartMax)
      : gaps;
}

/// "Aralıklar" — one bar per gap between records, oldest on the left, with the
/// card's rhythm ([typical]) as a dashed line. Shows at a glance whether the
/// thing is done on a steady beat or drifting.
class GapChart extends StatelessWidget {
  const GapChart({super.key, required this.gaps, required this.typical});

  final List<int> gaps;
  final int? typical;

  @override
  Widget build(BuildContext context) {
    final top = math.max(gaps.fold<int>(1, math.max), typical ?? 0);
    final t = typical;
    return Semantics(
      label: S.gapsSemantics(gaps, t),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: CustomPaint(
                painter: _GapPainter(
                  gaps: gaps,
                  top: top,
                  typical: t,
                  bar: AppColor.primaryDim,
                  lastBar: AppColor.primary,
                  over: AppColor.primary.withValues(alpha: 0.35),
                  line: AppColor.outline,
                  themeId: AppColor.current.id,
                ),
              ),
            ),
            const SizedBox(height: Space.s8),
            Row(
              children: [
                Text(
                  S.gapOldest,
                  style: ui(
                    11,
                    weight: FontWeight.w500,
                    color: AppColor.outline,
                  ),
                ),
                const Spacer(),
                if (t != null) ...[
                  Container(width: 14, height: 1.5, color: AppColor.outline),
                  const SizedBox(width: Space.xs),
                  Text(
                    S.gapRhythm(t),
                    style: ui(
                      11,
                      weight: FontWeight.w600,
                      color: AppColor.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                ],
                Text(
                  S.gapNewest,
                  style: ui(
                    11,
                    weight: FontWeight.w500,
                    color: AppColor.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GapPainter extends CustomPainter {
  _GapPainter({
    required this.gaps,
    required this.top,
    required this.typical,
    required this.bar,
    required this.lastBar,
    required this.over,
    required this.line,
    required this.themeId,
  });

  final List<int> gaps;
  final int top;
  final int? typical;
  final Color bar;
  final Color lastBar;
  final Color over;
  final Color line;
  final String themeId;

  @override
  void paint(Canvas canvas, Size size) {
    if (gaps.isEmpty) return;
    const labelSpace = 14.0;
    final chartH = size.height - labelSpace;
    final slot = size.width / gapChartMax;
    final w = math.min(22.0, slot * 0.62);
    // Bars sit at the right, so the newest gap is always in the same place.
    final start = size.width - slot * gaps.length;
    final t = typical;
    for (var i = 0; i < gaps.length; i++) {
      final g = gaps[i];
      final h = math.max(3.0, chartH * g / top);
      final x = start + slot * i + (slot - w) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, w, h),
        const Radius.circular(5),
      );
      final late = t != null && g > t * 1.25 + 1;
      canvas.drawRRect(
        rect,
        Paint()
          ..color = i == gaps.length - 1
              ? lastBar
              : late
              ? over
              : bar,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$g',
          style: ui(10, weight: FontWeight.w600, color: line),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + (w - tp.width) / 2, size.height - h - tp.height - 1),
      );
    }
    if (t != null) {
      final y = size.height - chartH * t / top;
      final paint = Paint()
        ..color = line
        ..strokeWidth = 1.5;
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 4, size.width), y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GapPainter old) =>
      old.themeId != themeId ||
      old.typical != typical ||
      old.top != top ||
      old.gaps.length != gaps.length ||
      !old.gaps.indexed.every((e) => gaps[e.$1] == e.$2);
}
