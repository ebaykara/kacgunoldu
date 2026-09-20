import '../l10n/strings.dart';
import 'text.dart';

/// What a card is about, read from its NAME (never from its icon: the icon
/// is a guess the user may not have corrected). Drives the wording of its
/// reminders.
enum ReminderTopic {
  pill,
  doctor,
  car,
  fridge,
  bed,
  laundry,
  clean,
  hair,
  nails,
  plant,
  gym,
  outdoor,
  family,
  pet,
  book,
  music,
  bill,
  general,
}

/// Word starts that put a card in a topic, checked in this order — health
/// first, so "Vitamin aldım spor sonrası" is a pill card and gets no joke,
/// and the specific before the broad ("Buzdolabını temizledim" is the
/// fridge, not cleaning). A stem matches the START of a word, so "sula"
/// finds "suladım" but not "masum"; a stem ending in `$` must be the whole
/// word ("yağ" but not "yağmur").
///
/// Both languages' stems live in one list, like the glyph rules: the topic of
/// a card is a property of what the person wrote, not of the interface
/// language they happen to be in today.
const _stems = <(ReminderTopic, List<String>)>[
  (ReminderTopic.pill, [
    'ilaç', 'vitamin', 'hap\$', 'hapı', 'hapın', 'takviye',
    'pill', 'medic', 'supplement',
  ]),
  (ReminderTopic.doctor, [
    'doktor', 'hekim', 'dişçi', 'hastane', 'tahlil', 'check', 'aşı\$', 'aşısı',
    'aşıs', 'aşıl', 'aşıy',
    'doctor', 'dentist', 'hospital', 'blood', 'gp\$',
  ]),
  (ReminderTopic.car, [
    'araba', 'araç', 'lastik', 'benzin', 'yakıt', 'egzoz', 'yağ\$', 'yağı', 'yağın',
    'car\$', 'cars', 'tyre', 'tire', 'petrol', 'fuel', 'engine', 'oil\$', 'oils',
  ]),
  (ReminderTopic.fridge, ['buzdolab', 'fridge', 'freezer']),
  (ReminderTopic.bed, [
    'çarşaf', 'nevresim', 'yatak', 'yastık',
    'sheet', 'duvet', 'pillow', 'mattress', 'bed\$', 'beds',
  ]),
  (ReminderTopic.laundry, ['çamaşır', 'ütü', 'laundry', 'washing', 'iron', 'towel']),
  (ReminderTopic.clean, [
    'temizl', 'süpür', 'toz', 'paspas', 'bulaşık', 'cam\$', 'camlar',
    'clean', 'vacuum', 'hoover', 'dust', 'mop', 'dish', 'window',
  ]),
  (ReminderTopic.hair, [
    'saç', 'berber', 'kuaför', 'tıraş', 'sakal',
    'hair', 'barber', 'shave', 'beard',
  ]),
  (ReminderTopic.nails, ['tırnak', 'nail']),
  (ReminderTopic.plant, [
    'bitki', 'çiçek', 'sula', 'saksı', 'bahçe',
    'plant', 'flower', 'water', 'garden', 'pot\$', 'pots',
  ]),
  (ReminderTopic.gym, [
    'spor', 'salon', 'fitness', 'antrenman', 'pilates', 'yoga', 'gym',
    'workout', 'weight',
  ]),
  (ReminderTopic.outdoor, [
    'koştu', 'koşu', 'koşma', 'yürüyüş', 'yürüdü', 'bisiklet', 'yüzme', 'yüzdü',
    'havuz',
    'run\$', 'ran\$', 'running', 'jog', 'walk', 'hike', 'cycl', 'bike', 'swim',
    'swam', 'pool',
  ]),
  (ReminderTopic.family, [
    'anne', 'baba', 'dede', 'nine', 'aile', 'kardeş', 'teyze', 'amca', 'dayı',
    'telefon', 'aradı', 'arama', 'görüntülü',
    'mum\$', 'mom\$', 'mother', 'dad\$', 'father', 'grandma', 'grandpa', 'famil',
    'brother', 'sister', 'aunt', 'uncle', 'call', 'phone', 'rang',
  ]),
  (ReminderTopic.pet, [
    'kedi', 'köpek', 'mama', 'veteriner', 'akvaryum',
    'cat\$', 'cats', 'dog', 'vet\$', 'vets', 'pet\$', 'pets', 'aquarium',
  ]),
  (ReminderTopic.book, ['kitap', 'okud', 'okuma', 'okuy', 'book', 'read']),
  (ReminderTopic.music, [
    'müzik', 'gitar', 'piyano', 'keman', 'bağlama',
    'music', 'guitar', 'piano', 'violin',
  ]),
  (ReminderTopic.bill, [
    'fatura', 'kira\$', 'kiray', 'kiran', 'ödeme', 'öded', 'aidat',
    'bill', 'rent', 'pay', 'paid', 'invoice', 'subscription',
  ]),
];

final _words = RegExp(r'[^\p{L}]+', unicode: true);

ReminderTopic topicOf(String name) {
  final wordSets = [
    for (final form in foldedForms(name))
      form.split(_words).where((w) => w.isNotEmpty).toList(),
  ];
  for (final (topic, stems) in _stems) {
    for (final stem in stems) {
      final whole = stem.endsWith('\$');
      final s = whole ? stem.substring(0, stem.length - 1) : stem;
      for (final words in wordSets) {
        if (words.any((w) => whole ? w == s : w.startsWith(s))) return topic;
      }
    }
  }
  return ReminderTopic.general;
}

/// FNV-1a: the same card and day always pick the same line, so a re-plan
/// never swaps the text of a pending notification, while the next cycle
/// (another day) usually reads differently.
int _pick(String seed, int count) {
  var h = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h % count;
}

String _fill(String line, int n, int k) =>
    line.replaceAll('{n}', '$n').replaceAll('{k}', '$k');

/// The body for the day a card's interval runs out. [seed] picks the line.
String dueBody(String name, int n, {required String seed}) {
  final lines = S.reminderCopy[topicOf(name)]!.$1;
  return _fill(lines[_pick(seed, lines.length)], n, 0);
}

/// The body once the card is [k] days past its interval, [n] days in all.
String lateBody(String name, int n, int k, {required String seed}) {
  final lines = S.reminderCopy[topicOf(name)]!.$2;
  return _fill(lines[_pick(seed, lines.length)], n, k);
}

/// Every line a topic can show — for tests.
List<String> linesFor(ReminderTopic topic) =>
    [...S.reminderCopy[topic]!.$1, ...S.reminderCopy[topic]!.$2];
