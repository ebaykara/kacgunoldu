import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show HapticFeedback;

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/logic.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/card_tile.dart';
import '../widgets/confirm_destructive.dart';
import '../widgets/create_sheet.dart';
import '../widgets/draggable_card_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/fab.dart';
import '../widgets/header.dart';
import '../widgets/record_sheet.dart';
import '../widgets/timeline.dart';

/// Records shown per card in the timeline, and how far back it reaches.
const _timelineRecordsPerCard = 4;
const _timelineMaxAgeDays = 120;
const _timelineMaxGroups = 14;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final CardStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab _tab = AppTab.cards;

  /// The one remaining filter. It used to be a three-way chip row (Tümü /
  /// Gecikenler / Taze); that row is gone, and the overdue pill in the header
  /// is now the only way in or out of this view.
  bool _onlyLate = false;

  /// Both tabs keep their own scroll position.
  final _cardsScroll = ScrollController();
  final _timeScroll = ScrollController();

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _cardsScroll.dispose();
    _timeScroll.dispose();
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  List<TimelineGroup> _buildTimeline(List<Card> cards, DateKey today) {
    final byDay = <int, List<String>>{};
    for (final c in cards) {
      for (final key in c.recs.take(_timelineRecordsPerCard)) {
        final offset = daysSince(key, today);
        if (offset > _timelineMaxAgeDays || offset < 0) continue;
        byDay.putIfAbsent(offset, () => []).add(c.name);
      }
    }
    final offsets = byDay.keys.toList()..sort();
    return offsets.take(_timelineMaxGroups).map((offset) {
      final d = fromDateKey(shiftDays(today, -offset));
      return TimelineGroup(
        key: '$offset',
        dayOfMonth: d.day,
        month: monthsShort[d.month - 1],
        relative: relativeLabel(offset),
        items: byDay[offset] ?? const [],
      );
    }).toList();
  }

  Future<void> _openRecordSheet(String cardId) async {
    final store = widget.store;
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) {
        // Rebuilds with the store so the meta line stays right if the card
        // changes underneath (e.g. midnight ticks over while the sheet is up).
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final card = store.cards.where((c) => c.id == cardId).firstOrNull;
            if (card == null) return const SizedBox.shrink();
            return RecordSheet(
              card: decorate(card, store.today),
              today: store.today,
              onPick: (offset) {
                Navigator.of(sheetContext).pop();
                store.record(cardId, offset);
                if (!_reduceMotion) HapticFeedback.lightImpact();
              },
              onDelete: () => _confirmDelete(sheetContext, cardId, card.name),
            );
          },
        );
      },
    );
  }

  /// Deleting takes every record on the card with it and cannot be undone, so
  /// it always goes through a confirmation first. Reachable from the record
  /// sheet, not from the card itself — long-press on the card starts a drag.
  Future<void> _confirmDelete(BuildContext sheetContext, String cardId, String name) async {
    if (!_reduceMotion) HapticFeedback.mediumImpact();
    final confirmed = await confirmDestructive(
      sheetContext,
      title: '“$name” silinsin mi?',
      message: 'Bu kartın bütün kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.',
      confirmLabel: 'Sil',
      cancelLabel: 'Vazgeç',
    );
    if (!confirmed) return;
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    widget.store.deleteCard(cardId);
  }

  Future<void> _openCreateSheet() async {
    final store = widget.store;
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => CreateSheet(
        onAddAndPickDate: (name) {
          Navigator.of(sheetContext).pop();
          final id = store.addCard(name, null);
          // Hand straight over to the record sheet for the new card.
          if (id != null) _openRecordSheet(id);
        },
        onAddToday: (name) {
          Navigator.of(sheetContext).pop();
          store.addCard(name, 0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;

    final cards = store.cards;
    // `cards` already arrives in display order — either the saved drag
    // arrangement or, failing that, urgency. Decorating preserves that order.
    final decorated = cards.map((c) => decorate(c, store.today)).toList();
    final lateCount = decorated.where((c) => c.stats.isLate).length;
    final visible =
        _onlyLate ? decorated.where((c) => c.stats.isLate).toList() : decorated;

    final tabBarHeight = Layout.tabBarContentHeight + media.padding.bottom;
    // Two fixed columns, derived from the window.
    final columnWidth = (media.size.width - Space.s18 * 2 - Layout.cardGap) / 2;

    final scrollPadding = EdgeInsets.only(
      top: 2,
      left: Space.s18,
      right: Space.s18,
      bottom: Layout.gridBottomPadding + media.padding.bottom,
    );

    final pulse = store.recordPulse;
    final snack = store.snack;

    return ColoredBox(
      color: AppColor.surface,
      child: Stack(
        children: [
          Column(
            children: [
              Header(
                dateLabel: formatFullDate(store.today),
                lateCount: lateCount,
                topInset: media.padding.top + Space.s12,
                showingLate: _onlyLate,
                onToggleLate: () => setState(() {
                  _tab = AppTab.cards;
                  _onlyLate = !_onlyLate;
                }),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab == AppTab.cards ? 0 : 1,
                  sizing: StackFit.expand,
                  children: [
                    SingleChildScrollView(
                      controller: _cardsScroll,
                      padding: scrollPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_onlyLate)
                            // A temporary, filtered view — dragging here would
                            // have nowhere stable to persist, so it stays a
                            // plain, auto-sorted grid.
                            Wrap(
                              spacing: Layout.cardGap,
                              runSpacing: Layout.cardGap,
                              children: [
                                for (final card in visible)
                                  SizedBox(
                                    width: columnWidth,
                                    child: CardTile(
                                      card: card,
                                      onTap: () => _openRecordSheet(card.id),
                                      celebrateNonce:
                                          pulse?.id == card.id ? pulse?.nonce : null,
                                      reduceMotion: reduceMotion,
                                    ),
                                  ),
                              ],
                            )
                          else
                            DraggableCardGrid(
                              cards: visible,
                              columnWidth: columnWidth,
                              onTapCard: (card) => _openRecordSheet(card.id),
                              onReorder: store.reorder,
                              recordPulseId: pulse?.id,
                              recordPulseNonce: pulse?.nonce,
                              reduceMotion: reduceMotion,
                            ),
                          if (store.ready && visible.isEmpty)
                            EmptyState(onlyLate: _onlyLate, reduceMotion: reduceMotion),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      controller: _timeScroll,
                      padding: scrollPadding,
                      child: Timeline(groups: _buildTimeline(cards, store.today)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Fab(onTap: _openCreateSheet, bottom: tabBarHeight + Space.s20),
          BottomTabBar(
            value: _tab,
            onChange: (t) => setState(() => _tab = t),
            bottomInset: media.padding.bottom,
          ),
          if (snack != null)
            AppSnackbar(
              key: ValueKey(snack.message),
              message: snack.message,
              undoable: snack.undoable,
              onUndo: store.undo,
              bottom: tabBarHeight + Space.s12,
              reduceMotion: reduceMotion,
            ),
        ],
      ),
    );
  }
}
