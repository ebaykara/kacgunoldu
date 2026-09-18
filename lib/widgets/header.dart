import 'package:flutter/material.dart';

import '../domain/card.dart' show CardLayout;
import '../domain/text.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';
import 'ui.dart';

/// Pinned header block — MD3 large top app bar / HIG large title.
///
/// It does not scroll: the date and the overdue count stay readable at all
/// times. With overdue cards the pill opens the "Gecikenler" page; with none
/// there is nothing to show, so it stays a plain status label. The avatar on
/// the title row opens the profile.
class Header extends StatefulWidget {
  const Header({
    super.key,
    required this.dateLabel,
    required this.lateCount,
    required this.topInset,
    required this.onOpenLate,
    required this.initials,
    required this.onProfile,
    required this.layout,
    required this.onToggleLayout,
    this.title = 'Kaç gün oldu?',
  });

  final String title;

  /// `18 Eylül 2026`
  final String dateLabel;
  final int lateCount;
  final double topInset;

  /// Tapping the pill opens the overdue cards.
  final VoidCallback onOpenLate;

  /// Avatar letters; empty shows a person glyph instead.
  final String initials;
  final VoidCallback onProfile;

  /// The current card layout; the button next to the avatar switches it.
  final CardLayout layout;
  final VoidCallback onToggleLayout;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasLate = widget.lateCount > 0;
    final label = '${widget.lateCount} kart gecikti';

    final pill = Container(
      padding: const EdgeInsets.only(
        top: 5,
        bottom: 5,
        left: Space.s8,
        right: 11,
      ),
      decoration: BoxDecoration(
        color: AppColor.primaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColor.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Space.s6),
          Text(
            label,
            style: ui(
              11,
              weight: FontWeight.w700,
              color: AppColor.onOverduePill,
            ),
          ),
          if (hasLate) ...[
            const SizedBox(width: Space.s6),
            ChevronIcon(
              color: AppColor.onOverduePill,
              open: false,
            ),
          ],
        ],
      ),
    );

    return Container(
      color: AppColor.surface,
      padding: EdgeInsets.only(
        top: widget.topInset,
        left: Space.s20,
        right: Space.s20,
        bottom: Space.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  upperTr(widget.dateLabel),
                  style: overline(color: AppColor.outline),
                ),
              ),
              if (hasLate) ...[
                const SizedBox(width: Space.s12),
                Semantics(
                  button: true,
                  label: label,
                  hint: 'gecikenleri görmek için dokun',
                  child: GestureDetector(
                    onTap: widget.onOpenLate,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    child: AnimatedScale(
                      scale: _pressed ? 0.95 : 1,
                      duration: const Duration(milliseconds: 140),
                      curve: Motion.emphasized,
                      child: pill,
                    ),
                  ),
                )
              ],
            ],
          ),
          const SizedBox(height: Space.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    style: display(
                      37,
                      color: AppColor.onSurface,
                      height: 1.04,
                      letterSpacing: 37 * -0.012,
                    ),
                  ),
                ),
              ),
              LayoutToggle(layout: widget.layout, onTap: widget.onToggleLayout),
              Avatar(initials: widget.initials, onTap: widget.onProfile),
            ],
          ),
        ],
      ),
    );
  }
}

/// The round profile button: initials on terracotta, or a person glyph.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, required this.onTap, this.size = 38});

  final String initials;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.92,
      semanticsLabel: 'Profil',
      child: Container(
        width: Layout.minTouchTarget,
        height: Layout.minTouchTarget,
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.surfaceBright, width: 2),
            boxShadow: Elevation.timelineItem,
          ),
          child: initials.isEmpty
              ? PersonIcon(color: AppColor.primary, size: 18)
              : Text(
                  initials,
                  style: ui(size * 0.36, weight: FontWeight.w700, color: AppColor.primary),
                ),
        ),
      ),
    );
  }
}

/// The button left of the avatar: switches between the grid and the list.
/// It shows the layout you would switch *to*.
class LayoutToggle extends StatelessWidget {
  const LayoutToggle({super.key, required this.layout, required this.onTap});

  final CardLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toList = layout == CardLayout.grid;
    return PressScale(
      onTap: onTap,
      scale: 0.92,
      haptic: true,
      semanticsLabel: toList ? 'Liste görünümü' : 'Izgara görünümü',
      child: Container(
        width: Layout.minTouchTarget,
        height: Layout.minTouchTarget,
        alignment: Alignment.center,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.surfaceBright, width: 2),
          ),
          child: Icon(
            toList ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
            size: 18,
            color: AppColor.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
