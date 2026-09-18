import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/card.dart';
import 'seed.dart';

const _cardsKey = 'nezaman.cards.v1';
const _orderKey = 'nezaman.order.v1';

/// Local-first, no backend.
///
/// Anything unreadable falls back to the seed rather than to a crash — losing
/// demo content beats losing the app.
class CardRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Card>> loadCards() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_cardsKey);
      if (raw == null) {
        final seeded = seedCards();
        await saveCards(seeded);
        return seeded;
      }
      final parsed = jsonDecode(raw);
      if (parsed is! List) return seedCards();
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
      return seedCards();
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
}
