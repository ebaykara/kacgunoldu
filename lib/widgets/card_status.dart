import 'package:flutter/widgets.dart';

import '../domain/card.dart' show Tier;
import '../domain/logic.dart';

/// The one line under a card's day count: where it stands against its
/// rhythm, in words. It replaces the ring's tiny label and the date stamp —
/// the day count already says when, the ring already shows how far along.
class CardStatus {
  const CardStatus(this.text, {this.urgent = false});

  final String text;

  /// Due today or past due: drawn in the tier's accent, bold.
  final bool urgent;

  factory CardStatus.of(DecoratedCard card) {
    if (card.card.recs.isEmpty) return const CardStatus('Henüz işaretlenmedi');
    final r = card.stats.remaining;
    if (r == null) return const CardStatus('Ritim öğreniliyor');
    if (r > 0) return CardStatus('$r gün kaldı');
    if (r == 0) return const CardStatus('Bugün sırası', urgent: true);
    return CardStatus('${-r} gün geçti', urgent: true);
  }

  /// Colour against the tier's background: the accent when urgent (on the
  /// solid overdue card the ink itself, which is the contrasting one),
  /// otherwise the ink, quietened.
  Color color(Tier tier, TierPalette palette) {
    if (!urgent) return palette.ink.withValues(alpha: 0.6);
    return tier == Tier.late ? palette.ink : palette.ring;
  }
}
