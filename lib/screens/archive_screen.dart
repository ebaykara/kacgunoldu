import 'package:flutter/material.dart' hide Card;

import '../domain/logic.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/card_row_tile.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';
import 'card_detail_screen.dart';

/// "Arşiv" — cards put away for now (seasonal, or no longer done). Off the
/// grid, never late, never reminded; tap one to open it and bring it back.
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.store});

  final CardStore store;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final cards = store.archivedCards;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(title: 'Arşiv'),
                Expanded(
                  child: cards.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(Space.s22),
                            child: Text(
                              'Arşivde kart yok. Bir kartı kartın ⋯ '
                              'menüsünden arşivleyebilirsin.',
                              textAlign: TextAlign.center,
                              style: ui(
                                13.5,
                                color: AppColor.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            Space.s18,
                            Space.s8,
                            Space.s18,
                            media.padding.bottom + 96,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: Space.xs,
                                bottom: Space.s14,
                              ),
                              child: Text(
                                'Arşivdeki kartlar kart listende görünmez, gecikme '
                                'sayılmaz ve hatırlatılmaz. Kayıtları olduğu gibi durur.',
                                style: ui(
                                  13,
                                  color: AppColor.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            for (final card in cards)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Layout.cardGap,
                                ),
                                child: CardRowTile(
                                  card: decorate(card, store.today),
                                  reduceMotion: media.disableAnimations,
                                  onTap: () => pushPage<void>(
                                    context,
                                    (_) => CardDetailScreen(
                                      store: store,
                                      cardId: card.id,
                                    ),
                                  ),
                                ),
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
