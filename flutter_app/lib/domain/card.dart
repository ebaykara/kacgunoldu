import 'date.dart';

/// A tracked thing. [recs] holds the days it was done, newest first.
/// Nothing derived is ever stored — see `domain/logic.dart`.
class Card {
  const Card({required this.id, required this.name, required this.recs});

  final String id;
  final String name;
  final List<DateKey> recs;

  Card copyWith({String? id, String? name, List<DateKey>? recs}) =>
      Card(id: id ?? this.id, name: name ?? this.name, recs: recs ?? this.recs);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'recs': recs};

  /// Returns `null` for anything that is not a well-formed card, so a corrupt
  /// entry is dropped instead of crashing the whole load.
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
    return Card(id: id, name: name, recs: parsed);
  }

  static final _dateKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}

enum Tier { fresh, calm, soon, late }

enum AppTab { cards, time }
