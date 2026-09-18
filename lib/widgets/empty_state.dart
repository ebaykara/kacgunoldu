import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Shown when there is nothing to display — no cards, or none are overdue.
/// Rises and fades in over .3s.
class EmptyState extends StatefulWidget {
  const EmptyState({super.key, required this.onlyLate, required this.reduceMotion});

  final bool onlyLate;
  final bool reduceMotion;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.reduceMotion ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.onlyLate
        ? 'Geciken hiçbir şey yok — nadir bir gün.'
        : 'Henüz bir kart yok. Aşağıdaki düğmeyle ilk kartını ekle.';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _controller.value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: Space.s14),
        child: Column(
          children: [
            Text(
              'Burada kimse yok.',
              textAlign: TextAlign.center,
              style: display(25, color: AppColor.onSurface, height: 1.16),
            ),
            const SizedBox(height: Space.s8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: ui(13, color: AppColor.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
