import 'package:flutter/widgets.dart';

import '../domain/card.dart' show Tier;
import '../domain/logic.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'card_glyph.dart';
import 'card_status.dart';
import 'day_count.dart';
import 'halo.dart';
import 'rhythm_ring.dart';

/// Width of the day-count column on the right of every row. Fixed, so the
/// numbers of all rows line up in one right-aligned column, like figures in
/// a table.
const double _countColumn = 66;

/// One card as a full-width row — the list layout's counterpart of
/// [CardTile], with the same hierarchy laid out left to right:
/// the glyph in its rhythm ring · the name over its status line · the day
/// count, the only number.
class CardRowTile extends StatefulWidget {
  const CardRowTile({
    super.key,
    required this.card,
    required this.onTap,
    this.isDragging = false,
    this.celebrateNonce,
    required this.reduceMotion,
  });

  final DecoratedCard card;
  final VoidCallback onTap;
  final bool isDragging;

  /// Non-null while this card is celebrating a fresh record.
  final int? celebrateNonce;
  final bool reduceMotion;

  @override
  State<CardRowTile> createState() => _CardRowTileState();
}

class _CardRowTileState extends State<CardRowTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final stats = card.stats;
    final tier = stats.tier;
    final palette = tiers[tier]!;
    final ink = palette.ink;
    final status = CardStatus.of(card);
    final nonce = widget.celebrateNonce;
    final hasRecs = card.card.recs.isNotEmpty;

    return Semantics(
      button: true,
      label: '${card.name}, ${stats.days} gün önce'
          '${stats.isLate ? ', geç' : ''}. ${stats.ringHint}',
      hint: 'ayrıntılar için dokun, yer değiştirmek için basılı tutup sürükle',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : (widget.isDragging ? 1.02 : 1),
          duration: const Duration(milliseconds: 180),
          curve: Motion.emphasized,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.panel),
              boxShadow: widget.isDragging
                  ? Elevation.dragging
                  : tier == Tier.late
                      ? Elevation.cardLate
                      : Elevation.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.panel),
              child: Container(
                color: palette.bg,
                padding: const EdgeInsets.fromLTRB(Space.s14, Space.s14, Space.s18, Space.s14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (nonce != null && !widget.reduceMotion)
                      Positioned.fill(
                        child: Center(child: Halo(color: palette.ring, nonce: nonce)),
                      ),
                    Row(
                      children: [
                        RhythmRing(
                          pct: stats.pct,
                          ring: palette.ring,
                          track: palette.track,
                          ink: ink,
                          label: stats.ringLabel,
                          reduceMotion: widget.reduceMotion,
                          size: 46,
                          center: CardGlyph(iconKey: iconKeyOf(card.card), color: ink, size: 20),
                        ),
                        const SizedBox(width: Space.s14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                card.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ui(15, weight: FontWeight.w600, color: ink, height: 1.25),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                status.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ui(
                                  12.5,
                                  weight: status.urgent ? FontWeight.w700 : FontWeight.w500,
                                  color: status.color(tier, palette),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.s12),
                        SizedBox(
                          width: _countColumn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: hasRecs
                                    ? DayCount(
                                        value: stats.days,
                                        color: ink,
                                        reduceMotion: widget.reduceMotion,
                                        size: 36,
                                      )
                                    : Text(
                                        '—',
                                        maxLines: 1,
                                        style: dayCountStyle(36, ink.withValues(alpha: 0.4)),
                                      ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasRecs ? 'gün oldu' : 'kayıt yok',
                                maxLines: 1,
                                softWrap: false,
                                style: ui(11, weight: FontWeight.w600, color: ink.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
