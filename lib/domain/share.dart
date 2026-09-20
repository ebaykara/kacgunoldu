import 'dart:convert';

import '../l10n/strings.dart';
import 'card.dart';
import 'date.dart';

/// Sharing a card without a server: the card travels inside a link,
/// `kacgunoldu://app/share/<data>`, where `<data>` is the card as compact
/// JSON in unpadded base64url. The other person opens the link, or copies
/// the message and uses Ayarlar → "Paylaşılan kartı ekle"; either way they
/// get their own copy. Nothing is synced afterwards.
const shareLinkPrefix = 'kacgunoldu://app/share/';

/// The card's shareable data: what the person wrote, never an id or a flag
/// about this device (reminders, archive).
String shareLink(Card card) {
  final data = jsonEncode({
    'n': card.name,
    if (card.icon != null) 'i': card.icon,
    if (card.every != null) 'e': card.every,
    'r': card.recs,
    if (card.notes.isNotEmpty) 'o': card.notes,
  });
  final encoded = base64Url.encode(utf8.encode(data)).replaceAll('=', '');
  return '$shareLinkPrefix$encoded';
}

/// The message the share sheet sends.
String shareMessage(Card card) => S.shareMessage(card.name, shareLink(card));

/// The scheme and host are optional: Flutter hands an opened link over as
/// its path alone (`/share/<data>`), the way `cardIdFromLink` reads a widget's.
final _linkPattern = RegExp(r'(?:kacgunoldu://app)?/share/([A-Za-z0-9_\-]+)');

/// Reads a shared card out of [text] — a whole message, just the link, or the
/// link's path.
/// The result has an empty id; the store gives it a fresh one. `null` when
/// there is no well-formed card in [text].
Card? parseSharedCard(String text) {
  final match = _linkPattern.firstMatch(text);
  if (match == null) return null;
  var data = match.group(1)!;
  data = data.padRight((data.length + 3) ~/ 4 * 4, '=');
  try {
    final json = jsonDecode(utf8.decode(base64Url.decode(data)));
    if (json is! Map) return null;
    final card = Card.tryFromJson({
      'id': '',
      'name': json['n'],
      'recs': json['r'],
      'icon': json['i'],
      'every': json['e'],
      'notes': json['o'],
    });
    if (card == null || card.name.trim().isEmpty) return null;
    return card.copyWith(
      name: card.name.trim(),
      recs: [...card.recs]..sort((a, b) => b.compareTo(a)),
    );
  } catch (_) {
    return null;
  }
}

/// Every record of every card as CSV, one row per record, newest first per
/// card: `Kart,Tarih,Not`. Commas, quotes and line breaks are quoted so a
/// spreadsheet opens it cleanly.
String cardsCsv(List<Card> cards) {
  String cell(String v) =>
      v.contains(RegExp('[",\n\r]')) ? '"${v.replaceAll('"', '""')}"' : v;
  final out = StringBuffer('${S.csvHeader}\r\n');
  for (final card in cards) {
    for (final DateKey r in card.recs) {
      out
        ..write(cell(card.name))
        ..write(',')
        ..write(r)
        ..write(',')
        ..write(cell(card.notes[r] ?? ''))
        ..write('\r\n');
    }
  }
  return out.toString();
}
