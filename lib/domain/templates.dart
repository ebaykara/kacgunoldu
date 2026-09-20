import '../l10n/strings.dart';

/// A ready-made card offered on the "Yeni kart" page: tap one and the name,
/// glyph and rhythm are filled in. Named the way the field invites — a
/// first-person sentence — so they read like cards someone wrote.
class CardTemplate {
  const CardTemplate(this.name, this.icon, this.every);

  final String name;

  /// Key into the glyph catalog (`widgets/card_glyph.dart`).
  final String icon;

  /// Days; a typical rhythm for it, which the person can change.
  final int every;
}

/// The small, easy-to-forget things this app is for, in the interface's
/// language — a card created from one keeps the name it was shown under.
List<CardTemplate> get cardTemplates => [
  for (final (name, icon, every) in S.templates) CardTemplate(name, icon, every),
];
