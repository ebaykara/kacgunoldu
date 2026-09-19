import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/order.dart';
import '../domain/reminder_copy.dart';
import '../domain/reminders.dart';
import '../domain/share.dart';
import '../domain/text.dart';
import '../services/home_widgets.dart';
import '../services/launch_theme.dart';
import '../services/reminders.dart';
import '../storage/repository.dart';
import '../storage/seed.dart';
import '../theme/system_bars.dart';
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
  CardStore({CardRepository? repository, Reminders? reminders, HomeWidgets? homeWidgets})
      : _repository = repository ?? CardRepository(),
        _reminders = reminders ?? NoopReminders(),
        _homeWidgets = homeWidgets ?? NoopHomeWidgets();

  final CardRepository _repository;
  final Reminders _reminders;
  final HomeWidgets _homeWidgets;
  String? _publishedSnapshot;
  bool _widgetDoneButton = true;
  bool _canPinWidget = false;

  CardLayout _layout = CardLayout.grid;
  int _reminderHour = defaultReminderHour;
  int _reminderMinute = defaultReminderMinute;
  Future<void> _syncChain = Future.value();
  StreamSubscription<String>? _tapSub;
  StreamSubscription<void>? _pinnedSub;
  bool _disposed = false;

  /// A card the person asked to open from a notification or a home screen
  /// widget. The home screen consumes it (opens the card, then clears it).
  final openCardRequest = ValueNotifier<String?>(null);

  /// Grid or list on the Kartlar tab.
  CardLayout get layout => _layout;

  void setLayout(CardLayout next) {
    if (next == _layout) return;
    _layout = next;
    unawaited(_repository.saveLayout(next));
    notifyListeners();
  }

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  /// How many cards are marked for reminders.
  int get reminderCount => _cards.where((c) => c.notify && !c.archived).length;

  List<Card> _cards = const [];
  List<String>? _manualOrder;
  Profile _profile = const Profile();
  bool _ready = false;
  DateKey _today = todayKey();
  Snack? _snack;
  RecordPulse? _recordPulse;

  /// The card as it was before the last undoable change (records and their
  /// notes).
  Card? _undoData;
  Timer? _snackTimer;
  Timer? _midnightTimer;

  bool get ready => _ready;
  DateKey get today => _today;
  Snack? get snack => _snack;
  RecordPulse? get recordPulse => _recordPulse;
  Profile get profile => _profile;

  /// True once someone has dragged a card and the urgency sort is off.
  bool get hasManualOrder => _manualOrder != null && _manualOrder!.isNotEmpty;

  Card? byId(String id) => _cards.where((c) => c.id == id).firstOrNull;

  /// The grid's display order: the saved drag arrangement if there is one,
  /// otherwise urgency (overdue first, then soonest-due). Archived cards are
  /// left out here — and so everywhere that reads this list.
  List<Card> get cards =>
      applyOrder(_cards.where((c) => !c.archived).toList(), _manualOrder, _today);

  /// Put-away cards, most recently done first.
  List<Card> get archivedCards => _cards.where((c) => c.archived).toList()
    ..sort((a, b) => (b.recs.firstOrNull ?? '').compareTo(a.recs.firstOrNull ?? ''));

  /// Any card at all, archived or not.
  bool get hasAnyCards => _cards.isNotEmpty;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    final results = await Future.wait([
      _repository.loadCards(),
      _repository.loadManualOrder(),
      _repository.loadProfile(),
      _repository.loadThemeId(),
      _repository.loadReminderTime(),
      _repository.loadLayout(),
      _repository.loadWidgetDoneButton(),
    ]);
    _cards = results[0] as List<Card>;
    _manualOrder = results[1] as List<String>?;
    _profile = results[2] as Profile;
    AppColor.current = paletteById(results[3] as String?);
    unawaited(applyLaunchTheme(AppColor.current.id));
    _layout = results[5] as CardLayout;
    _widgetDoneButton = results[6] as bool;
    final time = results[4] as (int, int)?;
    if (time != null) {
      _reminderHour = time.$1;
      _reminderMinute = time.$2;
    }

    _ready = true;
    _scheduleMidnight();
    // Days marked on a widget while the app was closed, before the widgets
    // are handed a snapshot that doesn't have them yet.
    await _takeWidgetMarks();
    _syncWidgets();
    _pinnedSub = _homeWidgets.pinned.listen((_) => toast('Widget ana ekrana eklendi'));
    unawaited(_homeWidgets.canPin().then((can) {
      if (_disposed || can == _canPinWidget) return;
      _canPinWidget = can;
      notifyListeners();
    }));
    // Opened by tapping a card on a home screen widget, from a closed state.
    final launchLink = Uri.tryParse(WidgetsBinding.instance.platformDispatcher.defaultRouteName);
    final launchCard = launchLink == null ? null : cardIdFromLink(launchLink);
    if (launchCard != null) openCardRequest.value = launchCard;
    final launchShared = parseSharedCard(WidgetsBinding.instance.platformDispatcher.defaultRouteName);
    if (launchShared != null) _importFromLink(launchShared);
    notifyListeners();
    // Not awaited: the notification plugin and the timezone database are
    // slow to start, and nothing on screen needs them — the app should draw
    // its first frame first.
    unawaited(_initReminders());
  }

  Future<void> _initReminders() async {
    await _reminders.init();
    if (_disposed) return;
    _tapSub = _reminders.taps.listen((id) => openCardRequest.value = id);
    final launched = await _reminders.launchCardId();
    if (_disposed) return;
    if (launched != null) openCardRequest.value = launched;
    _syncReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _snackTimer?.cancel();
    _midnightTimer?.cancel();
    _disposed = true;
    _tapSub?.cancel();
    _pinnedSub?.cancel();
    openCardRequest.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Day counts are calendar-based, so "today" has to be re-read whenever the
    // app comes back to the foreground as well as at local midnight.
    if (state == AppLifecycleState.resumed) {
      _refreshToday();
      _scheduleMidnight();
      unawaited(_takeWidgetMarks());
    }
  }

  /// A home screen widget tapped while the app is running (the widgets link
  /// to `kacgunoldu://app/card/<id>`). Claimed here so the navigator never
  /// tries it as a route.
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    final shared = parseSharedCard(uri.toString());
    if (shared != null) {
      _importFromLink(shared);
      return true;
    }
    final id = cardIdFromLink(uri);
    if (id != null) openCardRequest.value = id;
    // Any link of ours is claimed, even one naming no card: as a route it
    // would have nowhere to go.
    return id != null || uri.scheme == appLinkScheme;
  }

  void _refreshToday() {
    final next = todayKey();
    if (next != _today) {
      _today = next;
      _syncReminders();
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
    _syncReminders();
    _syncWidgets();
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

  /// A plain, non-undoable message (copy/paste feedback and the like).
  void toast(String message) {
    _undoData = null;
    _showSnack(Snack(message: message, undoable: false));
    notifyListeners();
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
    _undoData = card;
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
        if (c.id == u.id) c.copyWith(recs: u.recs, notes: u.notes) else c,
    ]);
  }

  /// Create a card and return its id.
  ///
  /// [offset] of `null` leaves the card without a first record ("Henüz
  /// yapmadım" in the card form).
  String? addCard(
    String rawName,
    int? offset, {
    String? icon,
    int? every,
    bool notify = false,
    int? remindAt,
  }) {
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
      icon: icon,
      every: every,
      created: _today,
      notify: notify,
      remindAt: remindAt,
    );
    _undoData = null;
    _showSnack(Snack(message: '“$name” eklendi', undoable: false));
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

  /// Take one record off a card. Undoable, like a record.
  void removeRecord(String cardId, DateKey key) {
    final card = byId(cardId);
    if (card == null || !card.recs.contains(key)) return;
    _undoData = card;
    _recordPulse = null;
    _showSnack(Snack(message: '${formatDayMonth(key, _today)} kaydı silindi', undoable: true));
    _commit([
      for (final c in _cards)
        if (c.id == card.id)
          c.copyWith(
            recs: c.recs.where((r) => r != key).toList(),
            notes: {...c.notes}..remove(key),
          )
        else
          c,
    ]);
  }

  /// Move one record to another day. Undoable.
  void moveRecord(String cardId, DateKey from, DateKey to) {
    final card = byId(cardId);
    if (card == null || from == to || !card.recs.contains(from)) return;
    _undoData = card;
    _recordPulse = null;
    _showSnack(Snack(message: 'Kayıt ${formatDayMonth(to, _today)} olarak güncellendi', undoable: true));
    // The note travels with its record; a day that already had its own note
    // keeps that one.
    final notes = {...card.notes}..remove(from);
    final moved = card.notes[from];
    if (moved != null) notes.putIfAbsent(to, () => moved);
    _commit([
      for (final c in _cards)
        if (c.id == card.id)
          c.copyWith(
            recs: _insertRecord(c.recs.where((r) => r != from).toList(), to),
            notes: notes,
          )
        else
          c,
    ]);
  }

  /// Write, change or (with an empty [text]) remove the note on one record.
  void setNote(String cardId, DateKey key, String text) {
    final card = byId(cardId);
    if (card == null || !card.recs.contains(key)) return;
    final trimmed = text.trim();
    if ((card.notes[key] ?? '') == trimmed) return;
    _undoData = null;
    _showSnack(Snack(message: trimmed.isEmpty ? 'Not silindi' : 'Not kaydedildi', undoable: false));
    final notes = {...card.notes};
    if (trimmed.isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = trimmed;
    }
    _commit([
      for (final c in _cards)
        if (c.id == cardId) c.copyWith(notes: notes) else c,
    ]);
  }

  /// Put a card away, or bring it back. Its records stay; while archived it
  /// is off the grid, never late and never reminded.
  void setArchived(String cardId, bool archived) {
    final card = byId(cardId);
    if (card == null || card.archived == archived) return;
    _undoData = null;
    _recordPulse = null;
    _showSnack(Snack(
      message: archived ? '“${card.name}” arşivlendi' : '“${card.name}” arşivden çıktı',
      undoable: false,
    ));
    _commit([
      for (final c in _cards)
        if (c.id == cardId) c.copyWith(archived: archived) else c,
    ]);
  }

  /// A card someone shared (see `domain/share.dart`), added as this person's
  /// own copy. Returns its new id, or `null` if the same card — same name,
  /// same records — is already here.
  String? importSharedCard(Card shared) {
    final exists = _cards.any((c) =>
        lowerTr(c.name) == lowerTr(shared.name) &&
        c.recs.length == shared.recs.length &&
        c.recs.indexed.every((e) => shared.recs[e.$1] == e.$2));
    if (exists) {
      toast('“${shared.name}” zaten kartların arasında');
      return null;
    }
    final card = shared.copyWith(
      id: '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_cards.length}',
      name: capitalizeTr(shared.name),
      created: _today,
      notify: false,
      archived: false,
      clearRemindAt: true,
    );
    _undoData = null;
    _showSnack(Snack(message: '“${card.name}” eklendi', undoable: false));
    _commit([card, ..._cards]);
    return card.id;
  }

  /// A share link opened from outside: add the card and show it.
  void _importFromLink(Card shared) {
    final id = importSharedCard(shared);
    if (id != null) openCardRequest.value = id;
  }

  /// Every record as CSV (see [cardsCsv]); archived cards included.
  String exportCsv() => cardsCsv(_cards);

  /// Rename a card, change its glyph or its declared rhythm. [every] of
  /// `null` hands the rhythm back to the learned median.
  ///
  /// [remindAt] (minutes after midnight) of `null` follows the global time.
  void updateCard(
    String cardId, {
    required String name,
    String? icon,
    int? every,
    bool? notify,
    int? remindAt,
  }) {
    final card = byId(cardId);
    final trimmed = name.trim();
    if (card == null || trimmed.isEmpty) return;
    _undoData = null;
    _showSnack(const Snack(message: 'Kart güncellendi', undoable: false));
    _commit([
      for (final c in _cards)
        if (c.id == cardId)
          c.copyWith(
            name: capitalizeTr(trimmed),
            icon: icon,
            clearIcon: icon == null,
            every: every,
            clearEvery: every == null,
            notify: notify,
            remindAt: remindAt,
            clearRemindAt: remindAt == null,
          )
        else
          c,
    ]);
  }

  /// Forget the dragged arrangement; the grid sorts by urgency again.
  void resetOrder() {
    _manualOrder = null;
    unawaited(_repository.clearManualOrder());
    _showSnack(const Snack(message: 'Kartlar aciliyete göre sıralandı', undoable: false));
    notifyListeners();
  }

  /// The active colour theme's id.
  String get themeId => AppColor.current.id;

  /// Switch the colour theme everywhere, at once, and remember it.
  void setTheme(String id) {
    final next = paletteById(id);
    if (next.id == AppColor.current.id) return;
    AppColor.current = next;
    unawaited(_repository.saveThemeId(next.id));
    unawaited(applyLaunchTheme(next.id));
    applySystemBars();
    _syncWidgets();
    notifyListeners();
    // Colours are read straight from [AppColor], not inherited, so nothing
    // rebuilds by itself — including pages further down the navigator stack.
    // Mark every element dirty once; the next frame repaints in the new
    // theme.
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }

  void updateProfile(Profile next) {
    _profile = Profile(name: next.name.trim(), handle: next.handle.trim().replaceAll('@', ''));
    unawaited(_repository.saveProfile(_profile));
    notifyListeners();
  }

  /// Delete every card. Not undoable — the caller confirms first.
  void clearAll() {
    _undoData = null;
    _recordPulse = null;
    _manualOrder = null;
    unawaited(_repository.clearManualOrder());
    _showSnack(const Snack(message: 'Bütün kartlar silindi', undoable: false));
    _commit(const []);
  }

  /// Add the example cards back, skipping any that are already here.
  int loadSamples() {
    final have = _cards.map((c) => c.id).toSet();
    final missing = seedCards(_today).where((c) => !have.contains(c.id)).toList();
    if (missing.isEmpty) return 0;
    _undoData = null;
    _showSnack(Snack(message: '${missing.length} örnek kart eklendi', undoable: false));
    _commit([..._cards, ...missing]);
    return missing.length;
  }

  /// Everything, as the JSON backup the settings screen copies out.
  String exportJson() => jsonEncode({
        'app': 'kac_gun_oldu',
        'version': 1,
        'cards': _cards.map((c) => c.toJson()).toList(),
        'order': _manualOrder,
        'profile': _profile.toJson(),
      });

  /// Replace everything from a backup. Returns the number of cards restored,
  /// or `null` if [raw] is not a backup this app wrote (nothing changes then).
  int? importJson(String raw) {
    Object? parsed;
    try {
      parsed = jsonDecode(raw.trim());
    } catch (_) {
      return null;
    }
    final list = parsed is Map ? parsed['cards'] : parsed;
    if (list is! List) return null;
    final cards = <Card>[];
    for (final entry in list) {
      final card = Card.tryFromJson(entry);
      if (card == null) return null;
      cards.add(card.copyWith(recs: [...card.recs]..sort((a, b) => b.compareTo(a))));
    }
    final order = parsed is Map ? parsed['order'] : null;
    _manualOrder = order is List && order.every((e) => e is String) ? order.cast<String>() : null;
    if (_manualOrder == null) {
      unawaited(_repository.clearManualOrder());
    } else {
      unawaited(_repository.saveManualOrder(_manualOrder!));
    }
    final profile = parsed is Map ? parsed['profile'] : null;
    if (profile is Map && profile['name'] is String) {
      _profile = Profile(
        name: profile['name'] as String,
        handle: profile['handle'] is String ? profile['handle'] as String : '',
      );
      unawaited(_repository.saveProfile(_profile));
    }
    _undoData = null;
    _recordPulse = null;
    _showSnack(Snack(message: '${cards.length} kart geri yüklendi', undoable: false));
    _commit(cards);
    return cards.length;
  }

  // ---- reminders ---------------------------------------------------------

  /// Rebuild what the operating system has pending from the current cards.
  /// Runs strictly one after another so a quick series of edits can't
  /// interleave its cancel/schedule steps.
  void _syncReminders() {
    final plan = planReminders(
      _cards,
      DateTime.now(),
      hour: _reminderHour,
      minute: _reminderMinute,
    );
    _syncChain = _syncChain.then((_) => _reminders.sync(plan));
  }

  /// Hands the home screen widgets what they draw. Skipped when nothing they
  /// show has changed (a record on an already-recorded day, say).
  void _syncWidgets() {
    final snapshot = widgetSnapshot(
      _cards.where((c) => !c.archived).toList(),
      _today,
      doneButton: _widgetDoneButton,
    );
    if (snapshot == _publishedSnapshot) return;
    _publishedSnapshot = snapshot;
    unawaited(_homeWidgets.publish(snapshot));
  }

  // ---- home screen widgets -------------------------------------------------

  /// Whether the widgets show the "Bugün yaptım" button.
  bool get widgetDoneButton => _widgetDoneButton;

  void setWidgetDoneButton(bool on) {
    if (on == _widgetDoneButton) return;
    _widgetDoneButton = on;
    unawaited(_repository.saveWidgetDoneButton(on));
    _syncWidgets();
    notifyListeners();
  }

  /// The app can place a widget itself (Android); elsewhere it explains how.
  bool get canPinWidget => _canPinWidget;

  /// Asks the launcher to place the single-card widget on [cardId], or the
  /// list widget.
  Future<PinResult> pinWidget({String? cardId, bool list = false}) =>
      _homeWidgets.pin(cardId: cardId, list: list);

  /// The system page for a refused "add to home screen" permission.
  Future<void> openPinPermission() => _homeWidgets.openPinPermission();

  /// Records the days marked with a widget's "Bugün yaptım" button. The
  /// widget has already redrawn itself; this makes them real records. A day
  /// already recorded, or a card deleted since, is skipped.
  Future<void> _takeWidgetMarks() async {
    final marks = await _homeWidgets.takeMarks();
    if (_disposed || marks.isEmpty) return;
    var next = _cards;
    final names = <String>[];
    for (final m in marks) {
      if (daysSince(m.day, _today) < 0) continue;
      final card = next.where((c) => c.id == m.id).firstOrNull;
      if (card == null || card.recs.contains(m.day)) continue;
      names.add(card.name);
      next = [
        for (final c in next)
          if (c.id == m.id) c.copyWith(recs: _insertRecord(c.recs, m.day)) else c,
      ];
    }
    if (names.isEmpty) return;
    _undoData = null;
    _showSnack(Snack(
      message: names.length == 1
          ? "${names.single} · widget'tan kaydedildi"
          : "${names.length} kayıt widget'tan eklendi",
      undoable: false,
    ));
    _commit(next);
  }

  /// Asks the system for notification permission (first use only prompts).
  Future<bool> requestReminderPermission() => _reminders.requestPermission();

  /// Turn one card's reminders on or off. Turning on asks for permission
  /// first; returns `false` (and changes nothing) if it is refused.
  Future<bool> setCardNotify(String cardId, bool on) async {
    final card = byId(cardId);
    if (card == null) return false;
    if (on && !await requestReminderPermission()) {
      toast('Bildirim izni kapalı. Telefon ayarlarından açabilirsin.');
      return false;
    }
    _commit([
      for (final c in _cards)
        if (c.id == cardId) c.copyWith(notify: on) else c,
    ]);
    return true;
  }

  /// The time of day reminders arrive.
  void setReminderTime(int hour, int minute) {
    _reminderHour = hour;
    _reminderMinute = minute;
    unawaited(_repository.saveReminderTime(hour, minute));
    _syncReminders();
    notifyListeners();
  }

  /// Shows a sample notification right now, in the real format.
  Future<void> sendTestReminder() async {
    if (!await requestReminderPermission()) {
      toast('Bildirim izni kapalı. Telefon ayarlarından açabilirsin.');
      return;
    }
    final sample = _cards.where((c) => c.notify && !c.archived).firstOrNull ?? _cards.firstOrNull;
    final name = sample?.name ?? 'Saçımı kestirdim';
    final days = sample == null || sample.recs.isEmpty
        ? 30
        : daysSince(sample.recs.first, todayKey(DateTime.now()));
    // A different line each time, so the test shows what reminders read like.
    await _reminders.showNow(
      name,
      dueBody(name, days < 1 ? 1 : days, seed: '${DateTime.now().microsecondsSinceEpoch}'),
    );
  }
}
