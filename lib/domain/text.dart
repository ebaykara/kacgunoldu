/// Capitalise the first letter using Turkish casing rules.
///
/// Dart's [String.toUpperCase] is locale-insensitive and maps `i` to the ASCII
/// `I`, which is wrong in Turkish — `ilaç` has to become `İlaç`, and an already
/// dotless `ı` becomes `I`. Both are handled explicitly here.
String capitalizeTr(String text) {
  if (text.isEmpty) return text;
  final first = text[0];
  final upper = switch (first) {
    'i' => 'İ',
    'ı' => 'I',
    _ => first.toUpperCase(),
  };
  return upper + text.substring(1);
}

/// Uppercase the whole string with the same Turkish rules, for the overlines.
String upperTr(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(switch (ch) {
      'i' => 'İ',
      'ı' => 'I',
      _ => ch.toUpperCase(),
    });
  }
  return buffer.toString();
}

/// Lowercase with Turkish rules (`I` -> `ı`, `İ` -> `i`), for matching.
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

/// Up to two initials for an avatar: `Eyüp Baykara` -> `EB`.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final first = upperTr(parts.first[0]);
  if (parts.length == 1) return first;
  return first + upperTr(parts.last[0]);
}
