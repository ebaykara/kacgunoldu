import 'package:flutter/widgets.dart';

import '../domain/date.dart';
import '../domain/logic.dart';
import '../domain/text.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';

/// "Ne zaman yaptın?" — the record sheet.
///
/// Three quick picks plus the last fourteen days. Picking anything records
/// immediately and closes; there is no confirm step. Deleting the card lives
/// here too (the trash action), because long-press on the card itself now
/// starts a drag.
class RecordSheet extends StatelessWidget {
  const RecordSheet({
    super.key,
    required this.card,
    required this.today,
    required this.onPick,
    required this.onDelete,
  });

  final DecoratedCard card;
  final DateKey today;
  final ValueChanged<int> onPick;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final quick = [0, 1, 2].map((o) {
      return (
        offset: o,
        label: o == 0
            ? 'Bugün'
            : o == 1
                ? 'Dün'
                : '2 gün önce',
        sub: formatDayMonth(shiftDays(today, -o), today),
      );
    }).toList();

    // Offsets 3…16 — the two weeks behind the quick picks.
    final cells = List.generate(14, (i) {
      final offset = i + 3;
      final d = fromDateKey(shiftDays(today, -offset));
      return (offset: offset, dow: dow[d.weekday % 7], dom: d.day);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                upperTr('Ne zaman yaptın?'),
                style: overline(color: AppColor.outline),
              ),
            ),
            Semantics(
              button: true,
              label: 'Kartı sil',
              child: GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(Space.s8),
                  child: TrashIcon(color: AppColor.outline),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s6),
        Semantics(
          header: true,
          child: Text(
            card.name,
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          card.stats.meta,
          style: ui(12.5, color: AppColor.onSurfaceVariant),
        ),
        const SizedBox(height: Space.s15),
        Row(
          children: [
            for (var i = 0; i < quick.length; i++) ...[
              if (i > 0) const SizedBox(width: Space.s8),
              Expanded(
                child: _PressTile(
                  onTap: () => onPick(quick[i].offset),
                  pressedScale: 0.96,
                  semanticsLabel: '${quick[i].label}, ${quick[i].sub}',
                  color: AppColor.primaryContainer,
                  radius: Radii.tile,
                  minHeight: Layout.minTouchTarget + 14,
                  padding: const EdgeInsets.symmetric(
                    vertical: Space.s14,
                    horizontal: Space.s6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quick[i].label,
                        textAlign: TextAlign.center,
                        style: ui(14, weight: FontWeight.w700, color: AppColor.onPrimaryContainer),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        quick[i].sub,
                        textAlign: TextAlign.center,
                        style: ui(10.5, weight: FontWeight.w500, color: AppColor.onOverduePill),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.s18),
        Text(
          upperTr('Daha geriden seç'),
          style: overline(color: AppColor.outline),
        ),
        const SizedBox(height: 10),
        // A 7-column grid: measured, so the 6pt gutters land where the design
        // puts them regardless of screen width.
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - Space.s6 * 6) / 7;
            return Wrap(
              spacing: Space.s6,
              runSpacing: Space.s6,
              children: [
                for (final c in cells)
                  SizedBox(
                    width: cellWidth,
                    child: _PressTile(
                      onTap: () => onPick(c.offset),
                      pressedScale: 0.94,
                      semanticsLabel: '${c.offset} gün önce, ${c.dow} ${c.dom}',
                      color: AppColor.surfaceContainer,
                      radius: Radii.dayCell,
                      // Padded to the 44pt minimum touch target even though
                      // the mock draws the cell visually shorter.
                      minHeight: Layout.minTouchTarget,
                      padding: const EdgeInsets.symmetric(vertical: Space.s7),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            upperTr(c.dow),
                            style: ui(9.5, weight: FontWeight.w700, color: AppColor.outline),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c.dom}',
                            style: ui(14, weight: FontWeight.w600, color: AppColor.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A tile that dips on press, used by both the quick picks and the day grid.
class _PressTile extends StatefulWidget {
  const _PressTile({
    required this.onTap,
    required this.pressedScale,
    required this.semanticsLabel,
    required this.color,
    required this.radius,
    required this.minHeight,
    required this.padding,
    required this.child,
  });

  final VoidCallback onTap;
  final double pressedScale;
  final String semanticsLabel;
  final Color color;
  final double radius;
  final double minHeight;
  final EdgeInsets padding;
  final Widget child;

  @override
  State<_PressTile> createState() => _PressTileState();
}

class _PressTileState extends State<_PressTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
