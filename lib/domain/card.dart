import 'date.dart';

/// A tracked thing. [recs] holds the days it was done, newest first.
/// Nothing derived is ever stored — see `domain/logic.dart`.
///
/// [icon], [every] and [created] are what the person told us, not something
/// computed: the glyph they picked, the rhythm they declared ("haftada bir")
/// and the day the card was made. All three are optional so cards written by
/// older builds still load.
///
/// [notes], [archived] and [remindAt] are the same kind of input: a line
/// written on a record ("45.200 km"), a card put away for now, and a time of
/// day for this card's reminders that differs from the global one.
class Card {
  const Card({
    required this.id,
    required this.name,
    required this.recs,
    this.icon,
    this.every,
    this.created,
    this.notify = false,
    this.notes = const {},
    this.archived = false,
    this.remindAt,
  });

  final String id;
  final String name;
  final List<DateKey> recs;

  /// Key into the glyph catalog (`widgets/card_glyph.dart`); `null` means
  /// "guess from the name".
  final String? icon;

  /// Declared interval in days. Wins over the learned median when set.
  final int? every;

  /// The day the card was created — `null` for seed and legacy cards.
  final DateKey? created;

  /// The person asked to be reminded when this comes due.
  final bool notify;

  /// A note per record day. A key always names a day in [recs] — removing or
  /// moving a record takes its note with it (see `CardStore`).
  final Map<DateKey, String> notes;

  /// Put away: hidden from the grid, never late, never reminded, not on the
  /// home screen widgets. Its records stay as they are.
  final bool archived;

  /// This card's reminder time as minutes after midnight; `null` follows the
  /// global "Hatırlatma saati".
  final int? remindAt;

  Card copyWith({
    String? id,
    String? name,
    List<DateKey>? recs,
    String? icon,
    bool clearIcon = false,
    int? every,
    bool clearEvery = false,
    DateKey? created,
    bool? notify,
    Map<DateKey, String>? notes,
    bool? archived,
    int? remindAt,
    bool clearRemindAt = false,
  }) => Card(
    id: id ?? this.id,
    name: name ?? this.name,
    recs: recs ?? this.recs,
    icon: clearIcon ? null : icon ?? this.icon,
    every: clearEvery ? null : every ?? this.every,
    created: created ?? this.created,
    notify: notify ?? this.notify,
    notes: notes ?? this.notes,
    archived: archived ?? this.archived,
    remindAt: clearRemindAt ? null : remindAt ?? this.remindAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'recs': recs,
    if (icon != null) 'icon': icon,
    if (every != null) 'every': every,
    if (created != null) 'created': created,
    if (notify) 'notify': true,
    if (notes.isNotEmpty) 'notes': notes,
    if (archived) 'archived': true,
    if (remindAt != null) 'remindAt': remindAt,
  };

  /// Returns `null` for anything that is not a well-formed card, so a corrupt
  /// entry is dropped instead of crashing the whole load. The optional fields
  /// are forgiving: a malformed one is ignored rather than losing the card.
  static Card? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final name = value['name'];
    final recs = value['recs'];
    if (id is! String || name is! String || recs is! List) return null;
    final parsed = <DateKey>[];
    for (final r in recs) {
      if (r is! String || !_dateKey.hasMatch(r)) return null;
      parsed.add(r);
    }
    final icon = value['icon'];
    final every = value['every'];
    final created = value['created'];
    final remindAt = value['remindAt'];
    final notes = <DateKey, String>{};
    final rawNotes = value['notes'];
    if (rawNotes is Map) {
      for (final e in rawNotes.entries) {
        final k = e.key;
        final v = e.value;
        if (k is String && parsed.contains(k) && v is String && v.trim().isNotEmpty) {
          notes[k] = v.trim();
        }
      }
    }
    return Card(
      id: id,
      name: name,
      recs: parsed,
      icon: icon is String && icon.isNotEmpty ? icon : null,
      every: every is int && every > 0 ? every : null,
      created: created is String && _dateKey.hasMatch(created) ? created : null,
      notify: value['notify'] == true,
      notes: notes,
      archived: value['archived'] == true,
      remindAt: remindAt is int && remindAt >= 0 && remindAt < 24 * 60 ? remindAt : null,
    );
  }

  static final _dateKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}

enum Tier { fresh, calm, soon, late }

enum AppTab { cards, time }

/// How the Kartlar tab lays its cards out: the two-column grid or a list of
/// full-width rows. Remembered across launches.
enum CardLayout { grid, list }
