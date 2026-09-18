import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The card's headline number.
const double dayCountSize = 58;

/// The day number's style — shared so the card can line "gün oldu" up with
/// the number's baseline.
TextStyle dayCountStyle(double size, Color color) => display(
      size,
      color: color,
      height: 0.86,
      letterSpacing: size * -0.02,
    );

/// The big day number.
///
/// On a record it counts down from the old value to the new one over 620ms
/// with a cubic ease-out, rounded each frame. The tween lives inside this
/// widget so a running record only repaints one number, never the grid.
///
/// Under reduce-motion it swaps to the new value with no tween at all.
class DayCount extends StatelessWidget {
  const DayCount({
    super.key,
    required this.value,
    required this.color,
    required this.reduceMotion,
    this.size = dayCountSize,
  });

  /// Point size; the grid uses [dayCountSize], the detail page goes bigger.
  final double size;

  final int value;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final style = dayCountStyle(size, color);

    // Reduce motion: swap the value outright. An AnimatedSwitcher would wrap
    // the number in a Stack, and a Stack reports no text baseline — which
    // silently breaks the baseline alignment "gün" sits on.
    if (reduceMotion) {
      return Text('$value', style: style, maxLines: 1, softWrap: false);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: Motion.countdown,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('${v.round()}', style: style, maxLines: 1, softWrap: false),
    );
  }
}
