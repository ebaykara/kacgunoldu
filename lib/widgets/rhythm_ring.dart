import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

const _stroke = (Layout.ringSize - Layout.ringHoleSize) / 2;

/// The rhythm ring: how far through its typical interval this card is.
///
/// The mock draws a conic gradient; the native equivalent is a trimmed arc,
/// starting at 12 o'clock and sweeping clockwise. It animates to a new
/// percentage over 500ms.
class RhythmRing extends StatelessWidget {
  const RhythmRing({
    super.key,
    required this.pct,
    required this.ring,
    required this.track,
    required this.ink,
    required this.label,
    required this.reduceMotion,
    this.size = Layout.ringSize,
    this.center,
  });

  /// Drawn in the hole instead of [label] — the cards put their glyph here,
  /// so the ring is a pure progress mark and the tile has one number only.
  final Widget? center;

  /// Outer diameter. The stroke and label scale with it, so the detail
  /// page's big ring is the grid ring enlarged, not a different drawing.
  final double size;

  /// Fill percentage, 3–100.
  final int pct;
  final Color ring;
  final Color track;
  final Color ink;
  final String label;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final k = size / Layout.ringSize;
    final stroke = _stroke * k;
    // `+8 gün` reads as a number with its unit under it; `yeni` and
    // `bugün` stay a single word.
    final split = label.endsWith(' gün');
    final valueText = split ? label.substring(0, label.length - 4) : label;
    // Past the usual interval it reads as a sentence: `+8 gün geçti`.
    final overdue = split && valueText.startsWith('+');
    final inkColor = ink.withValues(alpha: 0.9);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: pct / 100),
              duration: reduceMotion ? Duration.zero : Motion.ring,
              curve: Curves.easeInOut,
              builder: (context, value, _) => CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(progress: value, ring: ring, track: track, stroke: stroke),
              ),
            ),
            if (center != null)
              center!
            else
            // Sits inside the hole, never on top of the arc.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: stroke + 2 * k),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: split
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            valueText,
                            maxLines: 1,
                            style: ui(
                              10.5 * k,
                              weight: FontWeight.w800,
                              color: inkColor,
                              height: 1.05,
                            ),
                          ),
                          Text(
                            'gün',
                            maxLines: 1,
                            style: ui(
                              7.5 * k,
                              weight: FontWeight.w600,
                              color: inkColor,
                              height: 1.0,
                            ),
                          ),
                          // `+8 gün geçti` past the interval, `4 gün kaldı`
                          // before it.
                          Text(
                            overdue ? 'geçti' : 'kaldı',
                              maxLines: 1,
                              style: ui(7.5 * k, weight: FontWeight.w600, color: inkColor, height: 1.0),
                            ),
                        ],
                      )
                    : Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: ui(9.5 * k, weight: FontWeight.w700, color: inkColor),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.ring,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final double stroke;
  final Color ring;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // -pi/2 starts the sweep at 12 o'clock instead of 3 o'clock.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, ringPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ring != ring ||
      old.track != track ||
      old.stroke != stroke;
}
