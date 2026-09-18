import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show HapticFeedback;

import '../domain/logic.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/card_glyph.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';
import 'card_detail_screen.dart';

/// "Gecikenler" — every overdue card, most neglected first.
///
/// Tap opens the card; swiping a row to the right records it as done today
/// (and it leaves the list, since it is no longer late).
class LateScreen extends StatelessWidget {
  const LateScreen({super.key, required this.store});

  final CardStore store;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final late = orderCards(
              store.cards
                  .map((c) => decorate(c, store.today))
                  .where((c) => c.stats.isLate)
                  .toList(),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(title: 'Gecikenler'),
                Expanded(
                  child: late.isEmpty
                      ? const _AllClear()
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            Space.s18,
                            Space.s8,
                            Space.s18,
                            media.padding.bottom + 96,
                          ),
                          children: [
                            _Banner(count: late.length),
                            const SizedBox(height: Space.s16),
                            for (final card in late)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Space.s12,
                                ),
                                child: _LateRow(
                                  card: card,
                                  onOpen: () => pushPage<void>(
                                    context,
                                    (_) => CardDetailScreen(
                                      store: store,
                                      cardId: card.id,
                                    ),
                                  ),
                                  onDone: () {
                                    store.record(card.id, 0);
                                    if (!media.disableAnimations) {
                                      HapticFeedback.mediumImpact();
                                    }
                                  },
                                ),
                              ),
                            const SizedBox(height: Space.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swipe_right_alt_rounded,
                                  size: 18,
                                  color: AppColor.outline,
                                ),
                                const SizedBox(width: Space.s6),
                                Text(
                                  'Yaptıysan sağa kaydır',
                                  style: ui(
                                    12,
                                    weight: FontWeight.w500,
                                    color: AppColor.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
        StoreSnackLayer(store: store, bottom: media.padding.bottom + Space.s16),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.s16),
      decoration: BoxDecoration(
        color: AppColor.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(Radii.panel),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 22,
            color: AppColor.primary,
          ),
          const SizedBox(width: Space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count kartın zamanı geçti',
                  style: ui(
                    15,
                    weight: FontWeight.w700,
                    color: AppColor.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hemen kontrol et, tekrarını planla.',
                  style: ui(12.5, color: AppColor.onOverduePill),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LateRow extends StatelessWidget {
  const _LateRow({
    required this.card,
    required this.onOpen,
    required this.onDone,
  });

  final DecoratedCard card;
  final VoidCallback onOpen;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final stats = card.stats;
    return Dismissible(
      key: ValueKey('late-${card.id}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => onDone(),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColor.tertiary,
          borderRadius: BorderRadius.circular(Radii.panel),
        ),
        child: Row(
          children: [
            Icon(Icons.check_rounded, color: AppColor.onPrimary),
            const SizedBox(width: Space.s8),
            Text(
              'Bugün yaptım',
              style: ui(14, weight: FontWeight.w700, color: AppColor.onPrimary),
            ),
          ],
        ),
      ),
      child: PressScale(
        onTap: onOpen,
        scale: 0.98,
        semanticsLabel: '${card.name}, ${stats.ringHint}',
        child: Panel(
          padding: const EdgeInsets.fromLTRB(
            Space.s14,
            Space.s14,
            Space.s8,
            Space.s14,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                GlyphBadge(
                  iconKey: iconKeyOf(card.card),
                  bg: AppColor.primaryContainer,
                  fg: AppColor.primary,
                ),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ui(
                          14.5,
                          weight: FontWeight.w700,
                          color: AppColor.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stats.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ui(12, color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s8),
                Text(
                  stats.ringLabel,
                  style: ui(
                    15,
                    weight: FontWeight.w800,
                    color: AppColor.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColor.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColor.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 34,
                color: AppColor.tertiary,
              ),
            ),
            const SizedBox(height: Space.s16),
            Text(
              'Her şey yerinde.',
              textAlign: TextAlign.center,
              style: display(26, color: AppColor.onSurface, height: 1.16),
            ),
            const SizedBox(height: Space.s8),
            Text(
              'Geciken hiçbir şey yok — nadir bir gün.',
              textAlign: TextAlign.center,
              style: ui(13, color: AppColor.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
