import 'text.dart';

/// The glyph a card gets when nobody picked one: the first keyword hit in
/// its name. Order matters — `diş` must win over `hekim`, `buzdolabı` over
/// `temizledim`, `araba` over the `ara` of a phone call.
const _rules = <(String, List<String>)>[
  ('tooth', ['diş']),
  ('fridge', ['buzdolab']),
  ('car', ['araba', 'araç', 'yağ', 'lastik', 'benzin', 'muayene']),
  ('phone', ['telefon', 'aradım', 'anneme', 'babama', 'görüntülü']),
  ('swim', ['yüzme', 'havuz']),
  ('gym', ['spor', 'salon', 'fitness', 'antrenman', 'pilates', 'yoga']),
  ('run', ['koş', 'yürüyüş']),
  ('bike', ['bisiklet']),
  ('bed', ['çarşaf', 'yatak', 'nevresim']),
  ('scissors', ['saç', 'tıraş', 'berber', 'kuaför', 'tırnak']),
  ('doctor', ['doktor', 'hekim', 'hastane', 'tahlil', 'kontrol']),
  ('plant', ['bitki', 'çiçek', 'sula', 'saksı', 'bahçe']),
  ('laundry', ['çamaşır', 'ütü']),
  ('pill', ['ilaç', 'vitamin']),
  ('bath', ['banyo', 'duş']),
  ('clean', ['temizl', 'süpür', 'toz', 'paspas', 'bulaşık']),
  ('book', ['kitap', 'oku']),
  ('pet', ['kedi', 'köpek', 'mama', 'veteriner']),
  ('cart', ['market', 'alışveriş']),
  ('coffee', ['kahve', 'çay']),
  ('music', ['müzik', 'gitar', 'piyano']),
  ('money', ['fatura', 'ödeme', 'kira']),
  ('mail', ['mektup', 'mail', 'e-posta']),
];

/// Fallback when nothing in the name matches.
const defaultIconKey = 'spark';

String guessIcon(String name) {
  final lower = lowerTr(name);
  for (final (key, words) in _rules) {
    if (words.any(lower.contains)) return key;
  }
  return defaultIconKey;
}
