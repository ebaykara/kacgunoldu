import 'text.dart';

/// The glyph a card gets when nobody picked one: the first keyword hit in
/// its name. Order matters — `diş` must win over `hekim`, `buzdolabı` over
/// `temizledim`, `araba` over the `ara` of a phone call.
///
/// Both languages' keywords sit in the same list: the guess should work on a
/// Turkish card name with the interface in English and the other way round,
/// and a word from one language never means something else in the other.
const _rules = <(String, List<String>)>[
  ('tooth', ['diş', 'tooth', 'dentist', 'floss']),
  ('fridge', ['buzdolab', 'fridge', 'freezer']),
  ('car', ['araba', 'araç', 'yağ', 'lastik', 'benzin', 'muayene',
           'tyre', 'tire', 'petrol', 'fuel', ' oil', 'the car']),
  ('phone', ['telefon', 'aradım', 'anneme', 'babama', 'görüntülü',
             'call', 'phone', 'mum', 'mom', 'dad', 'rang']),
  ('swim', ['yüzme', 'havuz', 'swim', 'pool']),
  ('gym', ['spor', 'salon', 'fitness', 'antrenman', 'pilates', 'yoga',
           'gym', 'workout', 'weights']),
  ('run', ['koş', 'yürüyüş', 'run', 'jog', 'walk']),
  ('bike', ['bisiklet', 'bike', 'cycl']),
  ('bed', ['çarşaf', 'yatak', 'nevresim', 'sheet', 'duvet', 'bed', 'pillow']),
  ('scissors', ['saç', 'tıraş', 'berber', 'kuaför', 'tırnak',
                'haircut', 'hair', 'barber', 'shave', 'nail']),
  ('doctor', ['doktor', 'hekim', 'hastane', 'tahlil', 'kontrol',
              'doctor', 'hospital', 'blood test', 'check-up', 'checkup']),
  ('plant', ['bitki', 'çiçek', 'sula', 'saksı', 'bahçe',
             'plant', 'flower', 'water the', 'watered', 'garden']),
  ('laundry', ['çamaşır', 'ütü', 'laundry', 'washing', 'iron', 'towel']),
  ('pill', ['ilaç', 'vitamin', 'medic', 'pill', 'supplement']),
  ('bath', ['banyo', 'duş', 'bathroom', 'shower', 'bath']),
  ('clean', ['temizl', 'süpür', 'toz', 'paspas', 'bulaşık',
             'clean', 'vacuum', 'dust', 'mop', 'dishes']),
  ('book', ['kitap', 'oku', 'book', 'read']),
  ('pet', ['kedi', 'köpek', 'mama', 'veteriner', 'cat', 'dog', 'vet', 'pet']),
  ('cart', ['market', 'alışveriş', 'grocer', 'shopping']),
  ('coffee', ['kahve', 'çay', 'coffee', 'tea']),
  ('music', ['müzik', 'gitar', 'piyano', 'music', 'guitar', 'piano']),
  ('money', ['fatura', 'ödeme', 'kira', 'bill', 'rent', 'paid', 'payment']),
  ('mail', ['mektup', 'mail', 'e-posta', 'email', 'letter']),
];

/// Fallback when nothing in the name matches.
const defaultIconKey = 'spark';

String guessIcon(String name) {
  final forms = foldedForms(name);
  for (final (key, words) in _rules) {
    if (words.any((w) => forms.any((f) => f.contains(w)))) return key;
  }
  return defaultIconKey;
}
