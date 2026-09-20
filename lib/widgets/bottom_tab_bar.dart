import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../domain/card.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';

/// MD3 navigation bar / HIG tab bar, over a translucent blurred base.
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    super.key,
    required this.value,
    required this.onChange,
    required this.bottomInset,
  });

  final AppTab value;
  final ValueChanged<AppTab> onChange;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final height = Layout.tabBarContentHeight + bottomInset;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.tabBarBase,
              border: Border(
                top: BorderSide(color: AppColor.tabBarHairline, width: 0.5),
              ),
            ),
            padding: EdgeInsets.only(top: 9, bottom: bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TabItem(
                  label: S.tabCards,
                  active: value == AppTab.cards,
                  onTap: () => onChange(AppTab.cards),
                  builder: (color, active) => GridIcon(color: color, active: active),
                ),
                _TabItem(
                  label: S.tabTimeline,
                  active: value == AppTab.time,
                  onTap: () => onChange(AppTab.time),
                  builder: (color, active) => TimelineIcon(color: color, active: active),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
    required this.builder,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget Function(Color color, bool active) builder;

  @override
  Widget build(BuildContext context) {
    final tint = active ? AppColor.primary : AppColor.outline;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24, child: Center(child: builder(tint, active))),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: Motion.hover,
                style: ui(10.5, weight: FontWeight.w600, color: tint, letterSpacing: 10.5 * 0.01),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
