import 'date.dart';

/// A tracked thing. [recs] holds the days it was done, newest first.
/// Nothing derived is ever stored — see `domain/logic.dart`.
///
/// [icon], [every] and [created] are what the person told us, not something
/// computed: the glyph they picked, the rhythm they declared ("haftada bir")
/// and the day the card was made. All three are optional so cards written by
/// older builds still load.
class Card {
  const Card({
    required this.id,
    required this.name,
    required this.recs,
    this.icon,
    this.every,
    this.created,
    this.notify = false,
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
  }) => Card(
    id: id ?? this.id,
    name: name ?? this.name,
    recs: recs ?? this.recs,
    icon: clearIcon ? null : icon ?? this.icon,
    every: clearEvery ? null : every ?? this.every,
    created: created ?? this.created,
    notify: notify ?? this.notify,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'recs': recs,
    if (icon != null) 'icon': icon,
    if (every != null) 'every': every,
    if (created != null) 'created': created,
    if (notify) 'notify': true,
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
    return Card(
      id: id,
      name: name,
      recs: parsed,
      icon: icon is String && icon.isNotEmpty ? icon : null,
      every: every is int && every > 0 ? every : null,
      created: created is String && _dateKey.hasMatch(created) ? created : null,
      notify: value['notify'] == true,
    );
  }

  static final _dateKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}

enum Tier { fresh, calm, soon, late }

enum AppTab { cards, time }

/// How the Kartlar tab lays its cards out: the two-column grid or a list of
/// full-width rows. Remembered across launches.
enum CardLayout { grid, list }
