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

/// The day count's size on a grid card. One size for every card — a
/// three-digit count fits beside "gün oldu" at this size, so numbers never
/// shrink card by card and a row of cards reads on one level.
const double tileCountSize = 52;

/// The core component: one tracked thing, as a grid card.
///
/// One hierarchy, top to bottom:
///  * the glyph, ringed by the rhythm ring — progress as a shape, no text;
///  * the name, full width, up to two lines;
///  * the day count — the only number on the card — with "gün oldu" on its
///    baseline;
///  * one status line: "3 gün kaldı", "Bugün sırası", "8 gün geçti".
///
/// Colour comes from the tier, so overdue still reads at a glance. The whole
/// tile is a single button.
class CardTile extends StatefulWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.onTap,
    this.onLongPress,
    this.isDragging = false,
    this.celebrateNonce,
    this.showRing = true,
    required this.reduceMotion,
    this.width,
  });

  /// The tile's width in the grid (kept for callers; the layout no longer
  /// depends on it).
  final double? width;

  final DecoratedCard card;
  final VoidCallback onTap;

  /// Long press starts a drag (reordering the grid).
  final VoidCallback? onLongPress;

  /// True while this card is the one being dragged — it lifts off the grid.
  final bool isDragging;

  /// Non-null while this card is celebrating a fresh record.
  final int? celebrateNonce;

  final bool showRing;
  final bool reduceMotion;

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Motion.pop,
  );

  /// scale(1) -> 1.045 -> 0.985 -> 1, matching the CSS keyframes.
  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.045).chain(CurveTween(curve: Motion.emphasized)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.045, end: 0.985).chain(CurveTween(curve: Motion.emphasized)),
      weight: 32,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.985, end: 1.0).chain(CurveTween(curve: Motion.emphasized)),
      weight: 38,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(CardTile old) {
    super.didUpdateWidget(old);
    final nonce = widget.celebrateNonce;
    if (nonce != null && nonce != old.celebrateNonce && !widget.reduceMotion) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final stats = card.stats;
    final tier = stats.tier;
    final palette = tiers[tier]!;
    final ink = palette.ink;
    final status = CardStatus.of(card);
    final nonce = widget.celebrateNonce;
    final glyph = CardGlyph(iconKey: iconKeyOf(card.card), color: ink, size: 18);

    return Semantics(
      button: true,
      label: '${card.name}, ${stats.days} gün önce'
          '${stats.isLate ? ', geç' : ''}. ${stats.ringHint}',
      hint: widget.onLongPress != null
          ? 'ayrıntılar için dokun, yer değiştirmek için basılı tutup sürükle'
          : 'ayrıntılar için dokun',
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _popScale,
          builder: (context, child) => AnimatedScale(
            scale: _pressed ? 0.975 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Motion.emphasized,
            child: Transform.scale(
              scale: _popScale.value * (widget.isDragging ? 1.04 : 1),
              child: child,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.card),
              boxShadow: widget.isDragging
                  ? Elevation.dragging
                  : tier == Tier.late
                      ? Elevation.cardLate
                      : Elevation.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: Container(
                color: palette.bg,
                constraints: const BoxConstraints(minHeight: Layout.cardMinHeight),
                padding: const EdgeInsets.fromLTRB(Space.s16, Space.s16, Space.s16, Space.s15),
                child: Stack(
                  children: [
                    if (nonce != null && !widget.reduceMotion)
                      Positioned.fill(
                        child: Center(child: Halo(color: palette.ring, nonce: nonce)),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showRing)
                              RhythmRing(
                                pct: stats.pct,
                                ring: palette.ring,
                                track: palette.track,
                                ink: ink,
                                label: stats.ringLabel,
                                reduceMotion: widget.reduceMotion,
                                size: 40,
                                center: glyph,
                              )
                            else
                              glyph,
                            const SizedBox(height: Space.s12),
                            Text(
                              card.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ui(
                                14.5,
                                weight: FontWeight.w600,
                                color: ink,
                                height: 1.25,
                                letterSpacing: 14.5 * -0.008,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.s14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DayCountLine(
                              card: card,
                              size: tileCountSize,
                              color: ink,
                              reduceMotion: widget.reduceMotion,
                            ),
                            const SizedBox(height: 6),
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

/// "46 gün oldu": the day count with its unit on the number's baseline.
/// A card with no record yet shows a dash instead of a zero.
///
/// Never wraps (a three-digit number once split across lines); in the rare
/// case it can't fit — four digits, a very large text size — it scales down
/// as a whole rather than breaking.
class DayCountLine extends StatelessWidget {
  const DayCountLine({
    super.key,
    required this.card,
    required this.size,
    required this.color,
    required this.reduceMotion,
  });

  final DecoratedCard card;
  final double size;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final hasRecs = card.card.recs.isNotEmpty;
    final scaler = MediaQuery.textScalerOf(context);
    final numberStyle = dayCountStyle(size, hasRecs ? color : color.withValues(alpha: 0.4));
    // An explicit line height: left unset it inherits the surrounding
    // DefaultTextStyle's (Material's is 1.43), and the measured descent below
    // would not match the drawn one.
    final unitStyle = ui(
      size * 0.24,
      weight: FontWeight.w600,
      color: color.withValues(alpha: 0.6),
      height: 1.2,
    );

    // The unit sits on the number's baseline. Aligned by measured padding
    // (the difference between the two line boxes' descents) rather than
    // CrossAxisAlignment.baseline: a baseline row's height isn't reported to
    // IntrinsicHeight, which the grid relies on, and the card overflowed.
    final gap = _descentOf(numberStyle, scaler) - _descentOf(unitStyle, scaler);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: gap < 0 ? -gap : 0),
            child: hasRecs
                ? DayCount(value: card.stats.days, color: color, reduceMotion: reduceMotion, size: size)
                : Text('—', maxLines: 1, style: numberStyle),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(bottom: gap > 0 ? gap : 0),
            child: Text(
              hasRecs ? 'gün oldu' : 'kayıt yok',
              maxLines: 1,
              softWrap: false,
              style: unitStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// How far a single line's box extends below its alphabetic baseline.
double _descentOf(TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: '0', style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final descent = painter.height - painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  painter.dispose();
  return descent;
}
