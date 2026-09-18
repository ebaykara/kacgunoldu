/// "Ne sıklıkla tekrarlıyorsun?" — the declared rhythms offered as chips.
const frequencyPresets = <(int, String)>[
  (1, 'Her gün'),
  (2, '2 günde bir'),
  (3, '3 günde bir'),
  (7, 'Haftada bir'),
  (14, '2 haftada bir'),
  (30, 'Ayda bir'),
  (60, '2 ayda bir'),
  (90, '3 ayda bir'),
  (180, '6 ayda bir'),
  (365, 'Yılda bir'),
];

bool isPresetFrequency(int days) => frequencyPresets.any((p) => p.$1 == days);

/// `Haftada bir` for a preset, `10 günde bir` for anything custom.
String frequencyLabel(int days) {
  for (final (d, label) in frequencyPresets) {
    if (d == days) return label;
  }
  return '$days günde bir';
}
