import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/order.dart';
import '../domain/text.dart';
import '../storage/repository.dart';
import '../theme/tokens.dart';

class Snack {
  const Snack({required this.message, required this.undoable});

  final String message;

  /// Only records can be undone — creating or deleting a card offers no undo.
  final bool undoable;
}

/// Bumped on every record so the screen can replay the celebration.
class RecordPulse {
  const RecordPulse(this.id, this.nonce);

  final String id;
  final int nonce;
}

/// Newest-first insert that treats a day as recorded at most once.
List<DateKey> _insertRecord(List<DateKey> recs, DateKey key) {
  final next = recs.where((r) => r != key).toList();
  final at = next.indexWhere((r) => r.compareTo(key) < 0);
  if (at == -1) {
    next.add(key);
  } else {
    next.insert(at, key);
  }
  return next;
}

/// Everything the app knows, and every way it can change.
///
/// A [ChangeNotifier] rather than a heavier state package: the whole app is one
/// screen over one list, and this keeps the data flow readable end to end.
class CardStore extends ChangeNotifier with WidgetsBindingObserver {
  CardStore({CardRepository? repository}) : _repository = repository ?? CardRepository();

  final CardRepository _repository;

  List<Card> _cards = const [];
  List<String>? _manualOrder;
  bool _ready = false;
  DateKey _today = todayKey();
  Snack? _snack;
  RecordPulse? _recordPulse;

  ({String id, List<DateKey> recs})? _undoData;
  Timer? _snackTimer;
  Timer? _midnightTimer;

  bool get ready => _ready;
  DateKey get today => _today;
  Snack? get snack => _snack;
  RecordPulse? get recordPulse => _recordPulse;

  /// The grid's display order: the saved drag arrangement if there is one,
  /// otherwise urgency (overdue first, then soonest-due).
  List<Card> get cards => applyOrder(_cards, _manualOrder, _today);

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    final results = await Future.wait([
      _repository.loadCards(),
      _repository.loadManualOrder(),
    ]);
    _cards = results[0] as List<Card>;
    _manualOrder = results[1] as List<String>?;
    _ready = true;
    _scheduleMidnight();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _snackTimer?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Day counts are calendar-based, so "today" has to be re-read whenever the
    // app comes back to the foreground as well as at local midnight.
    if (state == AppLifecycleState.resumed) {
      _refreshToday();
      _scheduleMidnight();
    }
  }

  void _refreshToday() {
    final next = todayKey();
    if (next != _today) {
      _today = next;
      notifyListeners();
    }
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    _midnightTimer = Timer(untilMidnight(), () {
      _refreshToday();
      _scheduleMidnight();
    });
  }

  void _commit(List<Card> next) {
    _cards = next;
    unawaited(_repository.saveCards(next));
    notifyListeners();
  }

  void _showSnack(Snack next) {
    _snackTimer?.cancel();
    _snack = next;
    _snackTimer = Timer(
      next.undoable ? SnackbarTimeout.record : SnackbarTimeout.create,
      () {
        _snack = null;
        _undoData = null;
        notifyListeners();
      },
    );
  }

  void dismissSnack() {
    _snackTimer?.cancel();
    _snack = null;
    _undoData = null;
    notifyListeners();
  }

  /// Record a card as done [offset] days ago.
  void record(String cardId, int offset) {
    final card = _cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;
    final key = shiftDays(_today, -offset);
    _undoData = (id: card.id, recs: card.recs);
    _recordPulse = RecordPulse(card.id, DateTime.now().microsecondsSinceEpoch);
    _showSnack(Snack(message: '${card.name} · ${relativeLabel(offset)}', undoable: true));
    _commit([
      for (final c in _cards)
        if (c.id == card.id) c.copyWith(recs: _insertRecord(c.recs, key)) else c,
    ]);
  }

  /// Restore the card's previous record list exactly.
  void undo() {
    final u = _undoData;
    if (u == null) return;
    _undoData = null;
    _recordPulse = null;
    _snackTimer?.cancel();
    _snack = null;
    _commit([
      for (final c in _cards)
        if (c.id == u.id) c.copyWith(recs: u.recs) else c,
    ]);
  }

  /// Create a card and return its id.
  ///
  /// [offset] of `null` leaves the card without a first record — the create
  /// sheet then opens the record sheet so the date can be picked.
  String? addCard(String rawName, int? offset) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return null;
    // The field invites a lowercase, first-person sentence ("çamaşır
    // yıkadım"); the grid reads better as a list, so the stored name gets a
    // capital first letter while the field itself stays untouched.
    final name = capitalizeTr(trimmed);
    final card = Card(
      id: '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_cards.length}',
      name: name,
      recs: offset == null ? const [] : [shiftDays(_today, -offset)],
    );
    _undoData = null;
    if (offset != null) {
      _showSnack(Snack(message: '“$name” eklendi', undoable: false));
    }
    _commit([card, ..._cards]);
    return card.id;
  }

  /// Delete a card and everything recorded on it.
  ///
  /// Destructive and not undoable, so the caller confirms first — see the
  /// trash action in the record sheet.
  void deleteCard(String cardId) {
    final card = _cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;
    _undoData = null;
    _recordPulse = null;
    final order = _manualOrder;
    if (order != null) {
      final next = order.where((id) => id != cardId).toList();
      _manualOrder = next;
      unawaited(_repository.saveManualOrder(next));
    }
    _showSnack(Snack(message: '“${card.name}” silindi', undoable: false));
    _commit(_cards.where((c) => c.id != cardId).toList());
  }

  /// Persist a drag-and-drop rearrangement as the new permanent order.
  void reorder(List<String> newOrderIds) {
    _manualOrder = newOrderIds;
    unawaited(_repository.saveManualOrder(newOrderIds));
    notifyListeners();
  }

  void clearPulse() {
    _recordPulse = null;
  }
}
