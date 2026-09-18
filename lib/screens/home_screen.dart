import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/logic.dart';
import '../domain/text.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/draggable_card_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/fab.dart';
import '../widgets/header.dart';
import '../widgets/timeline.dart';
import '../widgets/ui.dart';
import 'card_detail_screen.dart';
import 'card_form_screen.dart';
import 'late_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final CardStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab _tab = AppTab.cards;
  TimelineRange _range = TimelineRange.all;

  /// Both tabs keep their own scroll position.
  final _cardsScroll = ScrollController();
  final _timeScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    widget.store.openCardRequest.addListener(_openRequestedCard);
    // A notification may have launched the app before this screen existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequestedCard());
  }

  /// A tapped notification asks for its card: open it, once.
  void _openRequestedCard() {
    final id = widget.store.openCardRequest.value;
    if (id == null || !mounted) return;
    widget.store.openCardRequest.value = null;
    if (widget.store.byId(id) != null) _openCard(id);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    widget.store.openCardRequest.removeListener(_openRequestedCard);
    _cardsScroll.dispose();
    _timeScroll.dispose();
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  void _openCard(String cardId) {
    pushPage<void>(
      context,
      (_) => CardDetailScreen(store: widget.store, cardId: cardId),
    );
  }

  void _openCreate({Suggestion? from}) {
    pushPage<void>(
      context,
      (_) => CardFormScreen(
        store: widget.store,
        initialName: from?.name,
        initialIcon: from?.icon,
        initialEvery: from?.every,
      ),
    );
  }

  void _openLate() =>
      pushPage<void>(context, (_) => LateScreen(store: widget.store));

  void _openProfile() =>
      pushPage<void>(context, (_) => ProfileScreen(store: widget.store));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;

    final cards = store.cards;
    final tabBarHeight = Layout.tabBarContentHeight + media.padding.bottom;

    // First run or everything deleted: a guided start instead of an empty
    // grid, with nothing else competing for attention.
    if (store.ready && cards.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: EmptyState(
              reduceMotion: reduceMotion,
              onCreate: _openCreate,
              onSuggestion: (s) => _openCreate(from: s),
            ),
          ),
          Positioned(
            top: media.padding.top + Space.xs,
            right: Space.s8,
            child: Avatar(
              initials: initialsOf(store.profile.name),
              onTap: _openProfile,
            ),
          ),
          _snackbar(media.padding.bottom + Space.s16, reduceMotion),
        ],
      );
    }

    // `cards` already arrives in display order — either the saved drag
    // arrangement or, failing that, urgency. Decorating preserves that order.
    final decorated = cards.map((c) => decorate(c, store.today)).toList();
    final lateCount = decorated.where((c) => c.stats.isLate).length;

    // Two fixed columns, derived from the window.
    final isList = store.layout == CardLayout.list;
    final columnWidth = isList
        ? media.size.width - Space.s18 * 2
        : (media.size.width - Space.s18 * 2 - Layout.cardGap) / 2;
    final scrollBottom = Layout.gridBottomPadding + media.padding.bottom;
    final pulse = store.recordPulse;

    return ColoredBox(
      color: AppColor.surface,
      child: Stack(
        children: [
          IndexedStack(
            index: _tab == AppTab.cards ? 0 : 1,
            sizing: StackFit.expand,
            children: [
              Column(
                children: [
                  Header(
                    dateLabel: formatFullDate(store.today),
                    lateCount: lateCount,
                    topInset: media.padding.top + Space.s12,
                    onOpenLate: _openLate,
                    initials: initialsOf(store.profile.name),
                    onProfile: _openProfile,
                    layout: store.layout,
                    onToggleLayout: () => store.setLayout(
                      isList ? CardLayout.grid : CardLayout.list,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _cardsScroll,
                      padding: EdgeInsets.only(
                        top: Space.s8,
                        left: Space.s18,
                        right: Space.s18,
                        bottom: scrollBottom,
                      ),
                      child: DraggableCardGrid(
                        cards: decorated,
                        columnWidth: columnWidth,
                        list: isList,
                        onTapCard: (card) => _openCard(card.id),
                        onReorder: store.reorder,
                        recordPulseId: pulse?.id,
                        recordPulseNonce: pulse?.nonce,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ),
                ],
              ),
              _TimelineTab(
                store: store,
                range: _range,
                onRange: (r) => setState(() => _range = r),
                controller: _timeScroll,
                bottomPadding: scrollBottom - 60,
                onOpenCard: _openCard,
                onProfile: _openProfile,
              ),
            ],
          ),
          if (_tab == AppTab.cards)
            Fab(onTap: _openCreate, bottom: tabBarHeight + Space.s20),
          BottomTabBar(
            value: _tab,
            onChange: (t) => setState(() => _tab = t),
            bottomInset: media.padding.bottom,
          ),
          _snackbar(tabBarHeight + Space.s12, reduceMotion),
        ],
      ),
    );
  }

  Widget _snackbar(double bottom, bool reduceMotion) {
    final snack = widget.store.snack;
    if (snack == null) return const SizedBox.shrink();
    return AppSnackbar(
      key: ValueKey(snack.message),
      message: snack.message,
      undoable: snack.undoable,
      onUndo: widget.store.undo,
      bottom: bottom,
      reduceMotion: reduceMotion,
    );
  }
}

/// "Zaman tüneli" — every record, grouped by month.
class _TimelineTab extends StatelessWidget {
  const _TimelineTab({
    required this.store,
    required this.range,
    required this.onRange,
    required this.controller,
    required this.bottomPadding,
    required this.onOpenCard,
    required this.onProfile,
  });

  final CardStore store;
  final TimelineRange range;
  final ValueChanged<TimelineRange> onRange;
  final ScrollController controller;
  final double bottomPadding;
  final ValueChanged<String> onOpenCard;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final entries = buildTimeline(store.cards, store.today, range);

    // Flatten into month headers + rows so the list builds lazily.
    final items = <Object>[];
    String? month;
    for (final e in entries) {
      final d = fromDateKey(e.dateKey);
      final label = '${months[d.month - 1]} ${d.year}';
      if (label != month) {
        items.add(label);
        month = label;
      }
      items.add(e);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: media.padding.top + Space.s12,
            left: Space.s20,
            right: Space.s20,
            bottom: Space.s14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Zaman tüneli',
                    style: display(
                      37,
                      color: AppColor.onSurface,
                      height: 1.04,
                      letterSpacing: 37 * -0.012,
                    ),
                  ),
                ),
              ),
              Avatar(
                initials: initialsOf(store.profile.name),
                onTap: onProfile,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s18),
          child: RangeSelector(value: range, onChange: onRange),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.s22),
                    child: Text(
                      range == TimelineRange.all
                          ? 'Henüz hiç kayıt yok.'
                          : range == TimelineRange.week
                          ? 'Son bir haftada kayıt yok.'
                          : 'Son bir ayda kayıt yok.',
                      textAlign: TextAlign.center,
                      style: ui(13.5, color: AppColor.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                    Space.s18,
                    0,
                    Space.s18,
                    bottomPadding,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    if (item is String) return TimelineMonthHeader(label: item);
                    final entry = item as TimelineEntry;
                    return TimelineRow(
                      entry: entry,
                      onTap: () => onOpenCard(entry.card.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
