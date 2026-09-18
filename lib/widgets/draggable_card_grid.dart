import 'package:flutter/widgets.dart';

import '../domain/logic.dart';
import '../theme/tokens.dart';
import 'card_row_tile.dart';
import 'card_tile.dart';

/// A two-column card grid whose cards can be picked up and moved.
///
/// Press and hold a card for ~350ms; it lifts under the finger and the rest of
/// the grid shifts live to show where it will land. Releasing commits the new
/// order, which the caller persists.
///
/// Built directly on [LongPressDraggable] + [DragTarget] rather than a
/// reordering package: the grid is two fixed columns of one widget type, and
/// keeping it first-party means the drag can't fight the tap and long-press
/// gestures the card already owns.
class DraggableCardGrid extends StatefulWidget {
  const DraggableCardGrid({
    super.key,
    required this.cards,
    required this.columnWidth,
    this.list = false,
    required this.onTapCard,
    required this.onReorder,
    required this.recordPulseId,
    required this.recordPulseNonce,
    required this.reduceMotion,
  });

  final List<DecoratedCard> cards;
  final double columnWidth;

  /// One full-width row per card ([CardRowTile]) instead of two columns.
  final bool list;
  final ValueChanged<DecoratedCard> onTapCard;

  /// Called once on drop, with the full id list in its new order.
  final ValueChanged<List<String>> onReorder;

  final String? recordPulseId;
  final int? recordPulseNonce;
  final bool reduceMotion;

  @override
  State<DraggableCardGrid> createState() => _DraggableCardGridState();
}

class _DraggableCardGridState extends State<DraggableCardGrid> {
  /// The live preview order while a drag is in flight. `null` when idle, so
  /// the widget renders straight from `widget.cards` the rest of the time.
  List<DecoratedCard>? _preview;
  String? _draggingId;

  List<DecoratedCard> get _items => _preview ?? widget.cards;

  void _startDrag(String id) {
    setState(() {
      _draggingId = id;
      _preview = [...widget.cards];
    });
  }

  /// Moves the dragged card to sit where [targetId] currently is. Called as
  /// the finger passes over each card, so the grid reflows under it.
  void _hoverOver(String targetId) {
    final items = _preview;
    final dragging = _draggingId;
    if (items == null || dragging == null || dragging == targetId) return;

    final from = items.indexWhere((c) => c.id == dragging);
    final to = items.indexWhere((c) => c.id == targetId);
    if (from == -1 || to == -1) return;

    setState(() {
      final next = [...items];
      next.insert(to, next.removeAt(from));
      _preview = next;
    });
  }

  void _endDrag({required bool commit}) {
    final items = _preview;
    setState(() {
      _preview = null;
      _draggingId = null;
    });
    if (commit && items != null) {
      widget.onReorder(items.map((c) => c.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    Widget cell(DecoratedCard card) => _DraggableCard(
          card: card,
          columnWidth: widget.columnWidth,
          list: widget.list,
          isDragging: _draggingId == card.id,
          onTap: () => widget.onTapCard(card),
          onDragStarted: () => _startDrag(card.id),
          onHovered: _hoverOver,
          onDragEnd: _endDrag,
          celebrateNonce: widget.recordPulseId == card.id ? widget.recordPulseNonce : null,
          reduceMotion: widget.reduceMotion,
        );

    // Row by row rather than a Wrap: the two cards of a grid row share one
    // height (IntrinsicHeight + stretch), so their names, day counts and
    // status lines sit on the same levels whatever their titles' lengths.
    // It also bounds the cells' height, which CardTile's spaceBetween column
    // needs to push the count down to the bottom edge.
    final perRow = widget.list ? 1 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i += perRow) ...[
          if (i > 0) const SizedBox(height: Layout.cardGap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < perRow; j++) ...[
                  if (j > 0) const SizedBox(width: Layout.cardGap),
                  Expanded(
                    child: i + j < items.length ? cell(items[i + j]) : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.card,
    required this.columnWidth,
    required this.list,
    required this.isDragging,
    required this.onTap,
    required this.onDragStarted,
    required this.onHovered,
    required this.onDragEnd,
    required this.celebrateNonce,
    required this.reduceMotion,
  });

  final DecoratedCard card;
  final double columnWidth;
  final bool list;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final ValueChanged<String> onHovered;
  final void Function({required bool commit}) onDragEnd;
  final int? celebrateNonce;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final tile = list
        ? CardRowTile(
            card: card,
            onTap: onTap,
            celebrateNonce: celebrateNonce,
            reduceMotion: reduceMotion,
          )
        : CardTile(
            card: card,
            width: columnWidth,
            onTap: onTap,
            celebrateNonce: celebrateNonce,
            reduceMotion: reduceMotion,
          );

    return DragTarget<String>(
      // Accept nothing on drop — the order is already live from the hover, so
      // the drop only needs to end the gesture.
      onWillAcceptWithDetails: (details) {
        if (details.data != card.id) onHovered(card.id);
        return false;
      },
      builder: (context, candidate, rejected) {
        return LongPressDraggable<String>(
          data: card.id,
          delay: const Duration(milliseconds: 350),
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnd(commit: true),
          onDraggableCanceled: (velocity, offset) => onDragEnd(commit: true),
          // The lifted copy is drawn in the overlay, outside the page's
          // Material — without a plain text style of its own, Flutter paints
          // its debug style there (yellow double underlines).
          feedback: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: IntrinsicHeight(
              child: SizedBox(
                width: columnWidth,
                child: list
                    ? CardRowTile(
                        card: card,
                        onTap: () {},
                        isDragging: true,
                        reduceMotion: reduceMotion,
                      )
                    : CardTile(
                        card: card,
                        width: columnWidth,
                        onTap: () {},
                        isDragging: true,
                        reduceMotion: reduceMotion,
                      ),
              ),
            ),
          ),
          // The gap left behind keeps the grid's shape while the card is up.
          childWhenDragging: Opacity(opacity: 0.25, child: tile),
          child: isDragging ? Opacity(opacity: 0.25, child: tile) : tile,
        );
      },
    );
  }
}
