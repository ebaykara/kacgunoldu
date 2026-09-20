import '../l10n/strings.dart';

/// "Ne sıklıkla tekrarlıyorsun?" — the declared rhythms offered as chips.
List<(int, String)> get frequencyPresets => S.frequencyPresets;

bool isPresetFrequency(int days) => frequencyPresets.any((p) => p.$1 == days);

/// `Haftada bir` for a preset, `10 günde bir` for anything custom.
String frequencyLabel(int days) {
  for (final (d, label) in frequencyPresets) {
    if (d == days) return label;
  }
  return S.everyNDays(days);
}
