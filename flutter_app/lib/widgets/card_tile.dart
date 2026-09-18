import 'package:flutter/widgets.dart';

import '../domain/card.dart' show Tier;
import '../domain/logic.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'day_count.dart';
import 'halo.dart';
import 'rhythm_ring.dart';

/// The core component: one tracked thing.
///
/// The whole tile is a single button (MD3 filled/tonal card with a state
/// layer; HIG grouped card at 26pt radius). Colour is derived from the tier,
/// but the `8 gün geç` tag and the ring carry the same information in words
/// and numbers, so overdue is never signalled by colour alone.
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
  });

  final DecoratedCard card;
  final VoidCallback onTap;

  /// Long press starts a drag (reordering the grid). Omitted where dragging
  /// doesn't apply — the filtered overdue view keeps the automatic sort.
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
      tween: Tween(
        begin: 1.0,
        end: 1.045,
      ).chain(CurveTween(curve: Motion.emphasized)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.045,
        end: 0.985,
      ).chain(CurveTween(curve: Motion.emphasized)),
      weight: 32,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.985,
        end: 1.0,
      ).chain(CurveTween(curve: Motion.emphasized)),
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
    final palette = tiers[widget.card.stats.tier]!;
    final stats = widget.card.stats;
    final nonce = widget.celebrateNonce;

    final tagInk = stats.tier == Tier.late
        ? palette.ink
        : const Color(0xFFFFFFFF);

    return Semantics(
      button: true,
      label:
          '${widget.card.name}, ${stats.days} gün önce'
          '${stats.isLate ? ', geç' : ''}. ${stats.ringHint}',
      hint: widget.onLongPress != null
          ? 'işaretlemek için dokun, yer değiştirmek için basılı tutup sürükle'
          : 'işaretlemek için dokun',
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
                  : stats.tier == Tier.late
                  ? Elevation.cardLate
                  : Elevation.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.card),
              child: Container(
                color: palette.bg,
                constraints: const BoxConstraints(
                  minHeight: Layout.cardMinHeight,
                ),
                padding: const EdgeInsets.fromLTRB(
                  Space.s15,
                  Space.s15,
                  Space.s15,
                  Space.s14,
                ),
                child: Stack(
                  children: [
                    if (nonce != null && !widget.reduceMotion)
                      Positioned.fill(
                        child: Center(
                          child: Halo(color: palette.ring, nonce: nonce),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.card.name,
                                      style: ui(
                                        13.5,
                                        weight: FontWeight.w600,
                                        color: palette.ink,
                                        height: 1.3,
                                        letterSpacing: 13.5 * -0.008,
                                      ),
                                    ),
                                    const SizedBox(height: Space.s6),
                                    // One line, never wrapped: the interval and
                                    // the date belong together. Shrinks a touch
                                    // before truncating, since the "geç" tag can
                                    // crowd this line.
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        stats.meta,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: ui(
                                          10.5,
                                          weight: FontWeight.w500,
                                          color: palette.ink.withValues(
                                            alpha: 0.72,
                                          ),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (stats.isLate) ...[
                                const SizedBox(width: Space.s8),
                                // Never let the tag take more than its share —
                                // the card name has to stay readable beside it.
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        (constraints.maxWidth - Space.s8) * 0.5,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: Space.xs,
                                      horizontal: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.tag,
                                      borderRadius: BorderRadius.circular(
                                        Radii.pill,
                                      ),
                                    ),
                                    // Spells out *why* — "8 gün geç" reads on its
                                    // own, without a separate sentence elsewhere.
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${-(stats.remaining ?? 0)} gün geç',
                                        maxLines: 1,
                                        style: ui(
                                          9.5,
                                          weight: FontWeight.w700,
                                          color: tagInk,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    DayCount(
                                      value: stats.days,
                                      color: palette.ink,
                                      reduceMotion: widget.reduceMotion,
                                    ),
                                    const SizedBox(width: Space.xs),
                                    Text(
                                      'gün',
                                      style: ui(
                                        12,
                                        weight: FontWeight.w600,
                                        color: palette.ink.withValues(
                                          alpha: 0.66,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.showRing) ...[
                              const SizedBox(width: Space.s8),
                              RhythmRing(
                                pct: stats.pct,
                                ring: palette.ring,
                                track: palette.track,
                                ink: palette.ink,
                                label: stats.ringLabel,
                                reduceMotion: widget.reduceMotion,
                              ),
                            ],
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
