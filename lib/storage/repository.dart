import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/card.dart';

const _cardsKey = 'nezaman.cards.v1';
const _orderKey = 'nezaman.order.v1';
const _profileKey = 'nezaman.profile.v1';
const _themeKey = 'nezaman.theme.v1';
const _reminderTimeKey = 'nezaman.remindertime.v1';
const _layoutKey = 'nezaman.layout.v1';

/// The person behind the cards. Local only — there are no accounts.
class Profile {
  const Profile({this.name = '', this.handle = ''});

  final String name;

  /// Shown under the name as `@handle`; optional.
  final String handle;

  bool get isEmpty => name.trim().isEmpty;

  Map<String, Object?> toJson() => {'name': name, 'handle': handle};
}

/// Local-first, no backend.
///
/// A first launch starts empty — the home screen then shows its guided start
/// with suggested cards. The example cards (`seed.dart`) are only ever added
/// on request, from Settings: a store install must not open on made-up
/// records. Anything unreadable also gives an empty list rather than a crash.
class CardRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Card>> loadCards() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cardsKey);
      if (raw == null) return const [];
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      final cards = <Card>[];
      for (final entry in parsed) {
        final card = Card.tryFromJson(entry);
        if (card != null) {
          // Records are kept newest-first; re-sort defensively on read.
          cards.add(card.copyWith(recs: [...card.recs]..sort((a, b) => b.compareTo(a))));
        }
      }
      return cards;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCards(List<Card> cards) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_cardsKey, jsonEncode(cards.map((c) => c.toJson()).toList()));
    } catch (_) {
      // Persistence is best-effort; the in-memory state stays authoritative.
    }
  }

  /// The grid sorts itself by urgency until someone drags a card — at that
  /// point their arrangement is remembered here as an explicit id order, and
  /// takes over from the automatic sort for good.
  Future<List<String>?> loadManualOrder() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_orderKey);
      if (raw == null) return null;
      final parsed = jsonDecode(raw);
      if (parsed is! List) return null;
      final ids = <String>[];
      for (final id in parsed) {
        if (id is! String) return null;
        ids.add(id);
      }
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveManualOrder(List<String> order) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_orderKey, jsonEncode(order));
    } catch (_) {
      // Best-effort, same as saveCards.
    }
  }

  /// Back to the automatic urgency sort.
  Future<void> clearManualOrder() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_orderKey);
    } catch (_) {
      // Best-effort, same as saveCards.
    }
  }

  Future<Profile> loadProfile() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_profileKey);
      if (raw == null) return const Profile();
      final parsed = jsonDecode(raw);
      if (parsed is! Map) return const Profile();
      final name = parsed['name'];
      final handle = parsed['handle'];
      return Profile(
        name: name is String ? name : '',
        handle: handle is String ? handle : '',
      );
    } catch (_) {
      return const Profile();
    }
  }

  Future<void> saveProfile(Profile profile) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    } catch (_) {
      // Best-effort, same as saveCards.
    }
  }

  /// The chosen colour theme's id; `null` means the default.
  Future<String?> loadThemeId() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_themeKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeId(String id) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_themeKey, id);
    } catch (_) {
      // Best-effort, same as saveCards.
    }
  }

  /// The time of day reminders arrive, as `(hour, minute)`; `null` = default.
  Future<(int, int)?> loadReminderTime() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_reminderTimeKey);
      if (raw == null) return null;
      final parts = raw.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return (h, m);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReminderTime(int hour, int minute) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_reminderTimeKey, '$hour:$minute');
    } catch (_) {
      // Best-effort, same as saveCards.
    }
  }

  /// Grid or list; the grid until someone picks the list.
  Future<CardLayout> loadLayout() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_layoutKey) == 'list' ? CardLayout.list : CardLayout.grid;
    } catch (_) {
      return CardLayout.grid;
    }
  }

  Future<void> saveLayout(CardLayout layout) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_layoutKey, layout.name);
    } catch (_) {
      // Best-effort, same as saveCards.
    }
  }
}
