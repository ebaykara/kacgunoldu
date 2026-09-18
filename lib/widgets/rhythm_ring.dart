import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

const _size = Layout.ringSize;
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
  });

  /// Fill percentage, 3–100.
  final int pct;
  final Color ring;
  final Color track;
  final Color ink;
  final String label;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: pct / 100),
              duration: reduceMotion ? Duration.zero : Motion.ring,
              curve: Curves.easeInOut,
              builder: (context, value, _) => CustomPaint(
                size: const Size.square(_size),
                painter: _RingPainter(progress: value, ring: ring, track: track),
              ),
            ),
            // Sits inside the hole, never on top of the arc.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _stroke + 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: ui(9, weight: FontWeight.w700, color: ink.withValues(alpha: 0.85)),
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
  _RingPainter({required this.progress, required this.ring, required this.track});

  final double progress;
  final Color ring;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      size.height - _stroke,
    );

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;
    // -pi/2 starts the sweep at 12 o'clock instead of 3 o'clock.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, ringPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ring != ring || old.track != track;
}
