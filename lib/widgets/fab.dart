import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';

/// "Yeni kart" — MD3 extended FAB / HIG prominent bottom-trailing button.
class Fab extends StatefulWidget {
  const Fab({super.key, required this.onTap, required this.bottom});

  final VoidCallback onTap;
  final double bottom;

  @override
  State<Fab> createState() => _FabState();
}

class _FabState extends State<Fab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: Space.s18,
      bottom: widget.bottom,
      child: Semantics(
        button: true,
        label: 'Yeni kart',
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: Motion.press,
            curve: Motion.emphasized,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: Space.s16,
                horizontal: Space.s20,
              ),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(Radii.fab),
                boxShadow: Elevation.fab,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PlusIcon(color: AppColor.onPrimary),
                  const SizedBox(width: Space.s8),
                  Text(
                    'Yeni kart',
                    style: ui(14, weight: FontWeight.w600, color: AppColor.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
