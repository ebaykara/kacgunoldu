import 'package:flutter/widgets.dart';

import '../domain/text.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

class TimelineGroup {
  const TimelineGroup({
    required this.key,
    required this.dayOfMonth,
    required this.month,
    required this.relative,
    required this.items,
  });

  final String key;

  /// Day of month, e.g. `18`.
  final int dayOfMonth;

  /// Abbreviated month, e.g. `Eyl` (rendered uppercase).
  final String month;

  /// `bugün` / `3 gün önce` / …
  final String relative;

  final List<String> items;
}

/// "Zaman tüneli" — what actually happened, newest first.
///
/// A rail with punched-through nodes; the gutter carries the date.
class Timeline extends StatelessWidget {
  const Timeline({super.key, required this.groups});

  final List<TimelineGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 58,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${g.dayOfMonth}',
                              style: display(22, color: AppColor.onSurface, height: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              upperTr(g.month),
                              style: ui(
                                10,
                                weight: FontWeight.w700,
                                color: AppColor.outline,
                                letterSpacing: 10 * 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.s14),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: AppColor.outlineTimeline, width: 1.5),
                              ),
                            ),
                            padding: const EdgeInsets.only(
                              left: Space.s16,
                              bottom: Space.s22,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.relative,
                                  style: ui(11, weight: FontWeight.w600, color: AppColor.outline),
                                ),
                                const SizedBox(height: Space.s8),
                                for (var i = 0; i < g.items.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(top: i == 0 ? 0 : Space.s7),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: Space.s12,
                                        horizontal: Space.s14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.surfaceBright,
                                        borderRadius: BorderRadius.circular(Radii.item),
                                        boxShadow: Elevation.timelineItem,
                                      ),
                                      child: Text(
                                        g.items[i],
                                        style: ui(
                                          13,
                                          weight: FontWeight.w600,
                                          color: AppColor.onSurface,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // 9pt dot with a 3pt ring of page colour, so it reads
                          // as punched through the rail.
                          Positioned(
                            left: -7.75,
                            top: 3,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: AppColor.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColor.surface, width: 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
