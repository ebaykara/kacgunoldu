import '../l10n/strings.dart';

/// Capitalise the first letter using the active language's casing rules.
///
/// Dart's [String.toUpperCase] is locale-insensitive and maps `i` to the ASCII
/// `I`, which is wrong in Turkish — `ilaç` has to become `İlaç`, and an already
/// dotless `ı` becomes `I`. [Strings.capitalize] handles both per language.
String capitalizeTr(String text) => S.capitalize(text);

/// Uppercase the whole string with the same rules, for the overlines.
String upperTr(String text) => S.upper(text);

/// Lowercase with Turkish rules (`I` -> `ı`, `İ` -> `i`), for matching.
///
/// Always Turkish, whatever the interface language: card names are the
/// person's own words and a Turkish name has to keep matching after a switch
/// to English. Anything matched against this is also matched against a plain
/// [String.toLowerCase] — see [foldedForms].
String lowerTr(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(switch (ch) {
      'I' => 'ı',
      'İ' => 'i',
      _ => ch.toLowerCase(),
    });
  }
  return buffer.toString();
}

/// [text] lowercased both ways — Turkish rules and plain ASCII/Unicode.
///
/// Keyword matching (the glyph guess, a reminder's topic, the search box) runs
/// against both, so `Ironed the shirts` finds `iron` and `İlaç aldım` finds
/// `ilaç`, whichever language the interface happens to be in. The two are
/// identical for most strings; the set is deduplicated.
List<String> foldedForms(String text) {
  final turkish = lowerTr(text);
  final plain = text.toLowerCase();
  return turkish == plain ? [turkish] : [turkish, plain];
}

/// Up to two initials for an avatar: `Eyüp Baykara` -> `EB`.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final first = upperTr(parts.first[0]);
  if (parts.length == 1) return first;
  return first + upperTr(parts.last[0]);
}
