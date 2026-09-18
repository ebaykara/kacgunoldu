import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/logic.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'card_glyph.dart';
import 'ui.dart';

/// `Tümü` / `Hafta` / `Ay` — how far back the timeline reaches.
enum TimelineRange { all, week, month }

/// One record on the timeline.
class TimelineEntry {
  const TimelineEntry({
    required this.card,
    required this.dateKey,
    required this.offset,
    required this.status,
    required this.statusTone,
  });

  final DecoratedCard card;
  final DateKey dateKey;

  /// Days ago.
  final int offset;

  /// `Yeni` / `+8 gün` / `4 gün kaldı` for a card's latest record,
  /// `36 gün arayla` / `ilk kayıt` for older ones.
  final String status;
  final Tier? statusTone;
}

/// Every record, newest first, optionally limited to the last week / month.
List<TimelineEntry> buildTimeline(
  List<Card> cards,
  DateKey today,
  TimelineRange range,
) {
  final limit = switch (range) {
    TimelineRange.all => null,
    TimelineRange.week => 6,
    TimelineRange.month => 29,
  };
  final entries = <TimelineEntry>[];
  for (final c in cards) {
    final d = decorate(c, today);
    for (var i = 0; i < c.recs.length; i++) {
      final key = c.recs[i];
      final offset = daysSince(key, today);
      if (offset < 0 || (limit != null && offset > limit)) continue;
      String status;
      Tier? tone;
      if (i == 0) {
        final r = d.stats.remaining;
        if (r == null) {
          status = 'Yeni';
          tone = Tier.fresh;
        } else if (r < 0) {
          status = '+${-r} gün';
          tone = d.stats.isLate ? Tier.late : Tier.soon;
        } else if (r == 0) {
          status = 'sırası bugün';
          tone = Tier.soon;
        } else {
          status = '$r gün kaldı';
          tone = null;
        }
      } else {
        status = i + 1 < c.recs.length
            ? '${daysSince(c.recs[i + 1], key)} gün arayla'
            : 'ilk kayıt';
        tone = null;
      }
      entries.add(
        TimelineEntry(
          card: d,
          dateKey: key,
          offset: offset,
          status: status,
          statusTone: tone,
        ),
      );
    }
  }
  entries.sort((a, b) {
    final c = b.dateKey.compareTo(a.dateKey);
    return c != 0 ? c : a.card.name.compareTo(b.card.name);
  });
  return entries;
}

/// `bugün` / `dün` / `3 gün` — the timeline's compact "how long ago".
String timelineAgo(int offset) => switch (offset) {
  0 => 'bugün',
  1 => 'dün',
  _ => '$offset gün',
};

/// The segmented `Tümü | Hafta | Ay` control.
class RangeSelector extends StatelessWidget {
  const RangeSelector({super.key, required this.value, required this.onChange});

  final TimelineRange value;
  final ValueChanged<TimelineRange> onChange;

  @override
  Widget build(BuildContext context) {
    const labels = {
      TimelineRange.all: 'Tümü',
      TimelineRange.week: 'Hafta',
      TimelineRange.month: 'Ay',
    };
    return Row(
      children: [
        for (final r in TimelineRange.values) ...[
          if (r != TimelineRange.all) const SizedBox(width: Space.s8),
          Expanded(
            child: PressScale(
              onTap: () => onChange(r),
              scale: 0.96,
              haptic: true,
              selected: value == r,
              semanticsLabel: labels[r],
              child: AnimatedContainer(
                duration: Motion.hover,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == r
                      ? AppColor.primary
                      : AppColor.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.item),
                  boxShadow: value == r ? Elevation.button : null,
                ),
                child: Text(
                  labels[r]!,
                  style: ui(
                    13,
                    weight: FontWeight.w700,
                    color: value == r
                        ? AppColor.onPrimary
                        : AppColor.onSurfaceMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A month heading: `Eylül 2026`.
class TimelineMonthHeader extends StatelessWidget {
  const TimelineMonthHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Space.s18,
        bottom: Space.s12,
        left: 2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: ui(17, weight: FontWeight.w700, color: AppColor.onSurface),
        ),
      ),
    );
  }
}

/// One record: date bubble, glyph, name, how long ago and its status.
class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.entry, required this.onTap});

  final TimelineEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = fromDateKey(entry.dateKey);
    final badge = badgeColors(entry.card.stats.tier);
    final toneColor = switch (entry.statusTone) {
      Tier.fresh => AppColor.tertiary,
      Tier.late || Tier.soon => AppColor.primary,
      _ => AppColor.onSurfaceVariant,
    };
    final ago = timelineAgo(entry.offset);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s12),
      child: PressScale(
        onTap: onTap,
        scale: 0.985,
        semanticsLabel:
            '${d.day} ${months[d.month - 1]}, ${entry.card.name}, $ago, ${entry.status}',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColor.surfaceBright,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.outlineVariant),
                ),
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${d.day}',
                        style: display(
                          21,
                          color: AppColor.onSurface,
                          height: 1,
                        ),
                      ),
                      Text(
                        months[d.month - 1],
                        style: ui(
                          8.5,
                          weight: FontWeight.w600,
                          color: AppColor.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Space.s12),
              Expanded(
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(
                    Space.s12,
                    Space.s12,
                    Space.s6,
                    Space.s12,
                  ),
                  radius: Radii.tile,
                  child: Row(
                    children: [
                      GlyphBadge(
                        iconKey: iconKeyOf(entry.card.card),
                        bg: badge.bg,
                        fg: badge.fg,
                        size: 40,
                      ),
                      const SizedBox(width: Space.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ui(
                                13.5,
                                weight: FontWeight.w700,
                                color: AppColor.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  ago,
                                  style: ui(
                                    12,
                                    color: AppColor.onSurfaceVariant,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: AppColor.outline,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    entry.status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ui(
                                      12,
                                      weight: entry.statusTone == null
                                          ? FontWeight.w400
                                          : FontWeight.w700,
                                      color: toneColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColor.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
