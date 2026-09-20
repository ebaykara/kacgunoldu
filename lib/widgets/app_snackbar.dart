import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// MD3 snackbar with action / HIG toast with Undo.
///
/// Enters over 260ms from `translateY(14) scale(.96)`, matching the mock.
class AppSnackbar extends StatefulWidget {
  const AppSnackbar({
    super.key,
    required this.message,
    required this.undoable,
    required this.onUndo,
    required this.bottom,
    required this.reduceMotion,
  });

  final String message;

  /// `Geri al` is only offered for records, never for card creation or delete.
  final bool undoable;
  final VoidCallback onUndo;
  final double bottom;
  final bool reduceMotion;

  @override
  State<AppSnackbar> createState() => _AppSnackbarState();
}

class _AppSnackbarState extends State<AppSnackbar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.snackbar,
    value: widget.reduceMotion ? 1 : 0,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Motion.decelerate,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _controller.forward();
  }

  @override
  void didUpdateWidget(AppSnackbar old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message && !widget.reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: Space.s14,
      right: Space.s14,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => Opacity(
          opacity: _t.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - _t.value)),
            child: Transform.scale(scale: 0.96 + 0.04 * _t.value, child: child),
          ),
        ),
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.only(
              top: 13,
              bottom: 13,
              left: Space.s18,
              right: 10,
            ),
            decoration: BoxDecoration(
              color: AppColor.inverseSurface,
              borderRadius: BorderRadius.circular(Radii.item),
              boxShadow: Elevation.snackbar,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ui(
                      13,
                      weight: FontWeight.w500,
                      color: AppColor.inverseOnSurface,
                      height: 1.3,
                    ),
                  ),
                ),
                if (widget.undoable) ...[
                  const SizedBox(width: Space.s12),
                  Semantics(
                    button: true,
                    label: S.undo,
                    child: GestureDetector(
                      onTap: widget.onUndo,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Space.s8,
                          horizontal: Space.s14,
                        ),
                        child: Text(
                          S.undo,
                          style: ui(13, weight: FontWeight.w700, color: AppColor.inverseAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
