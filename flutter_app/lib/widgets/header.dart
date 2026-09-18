import 'package:flutter/widgets.dart';

import '../domain/text.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';

/// Pinned header block — MD3 large top app bar / HIG large title.
///
/// It does not scroll: the date and the overdue count stay readable at all
/// times. With overdue cards the pill is the shortcut to them; with none there
/// is nothing to show, so it stays a plain status label.
class Header extends StatefulWidget {
  const Header({
    super.key,
    required this.dateLabel,
    required this.lateCount,
    required this.topInset,
    required this.showingLate,
    required this.onToggleLate,
  });

  /// `18 Eylül 2026`
  final String dateLabel;
  final int lateCount;
  final double topInset;

  /// True while the overdue filter is the active one.
  final bool showingLate;

  /// Tapping the pill jumps to the overdue cards, and back again.
  final VoidCallback onToggleLate;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasLate = widget.lateCount > 0;
    final on = widget.showingLate;
    final label = hasLate ? '${widget.lateCount} kart gecikti' : 'her şey yerinde';

    final pill = Container(
      padding: const EdgeInsets.only(
        top: 5,
        bottom: 5,
        left: Space.s8,
        right: 11,
      ),
      decoration: BoxDecoration(
        color: on ? AppColor.primary : AppColor.primaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: on ? AppColor.onPrimary : AppColor.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Space.s6),
          Text(
            label,
            style: ui(
              11,
              weight: FontWeight.w700,
              color: on ? AppColor.onPrimary : AppColor.onOverduePill,
            ),
          ),
          if (hasLate) ...[
            const SizedBox(width: Space.s6),
            ChevronIcon(
              color: on ? AppColor.onPrimary : AppColor.onOverduePill,
              open: on,
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
              const SizedBox(width: Space.s12),
              if (hasLate)
                Semantics(
                  button: true,
                  selected: on,
                  label: label,
                  hint: on ? 'bütün kartlara dönmek için dokun' : 'gecikenleri görmek için dokun',
                  child: GestureDetector(
                    onTap: widget.onToggleLate,
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
              else
                Semantics(label: label, child: pill),
            ],
          ),
          const SizedBox(height: Space.s12),
          Semantics(
            header: true,
            child: Text(
              'En son ne zaman?',
              style: display(
                37,
                color: AppColor.onSurface,
                height: 1.04,
                letterSpacing: 37 * -0.012,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
