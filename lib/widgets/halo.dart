import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

const _size = 200.0;

/// The celebration disc: a soft puff of the tier's ring colour that expands
/// out of the card centre and fades. Clipped by the card's rounded box.
///
/// `scale(.55) -> 1.9` with `opacity .55 -> 0` over 750ms, ease-out.
class Halo extends StatefulWidget {
  const Halo({super.key, required this.color, required this.nonce});

  final Color color;

  /// Changing this replays the animation.
  final int nonce;

  @override
  State<Halo> createState() => _HaloState();
}

class _HaloState extends State<Halo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.halo,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void didUpdateWidget(Halo old) {
    super.didUpdateWidget(old);
    if (old.nonce != widget.nonce) {
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final v = _t.value;
          return Opacity(
            opacity: (0.55 * (1 - v)).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.55 + (1.9 - 0.55) * v,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0)],
                    stops: const [0, 0.68],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
