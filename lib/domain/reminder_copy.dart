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
const _stems = <(ReminderTopic, List<String>)>[
  (ReminderTopic.pill, ['ilaç', 'vitamin', 'hap\$', 'hapı', 'hapın', 'takviye']),
  (ReminderTopic.doctor, ['doktor', 'hekim', 'dişçi', 'hastane', 'tahlil', 'check', 'aşı\$', 'aşısı', 'aşıs', 'aşıl', 'aşıy']),
  (ReminderTopic.car, ['araba', 'araç', 'lastik', 'benzin', 'yakıt', 'egzoz', 'yağ\$', 'yağı', 'yağın']),
  (ReminderTopic.fridge, ['buzdolab']),
  (ReminderTopic.bed, ['çarşaf', 'nevresim', 'yatak', 'yastık']),
  (ReminderTopic.laundry, ['çamaşır', 'ütü']),
  (ReminderTopic.clean, ['temizl', 'süpür', 'toz', 'paspas', 'bulaşık', 'cam\$', 'camlar']),
  (ReminderTopic.hair, ['saç', 'berber', 'kuaför', 'tıraş', 'sakal']),
  (ReminderTopic.nails, ['tırnak']),
  (ReminderTopic.plant, ['bitki', 'çiçek', 'sula', 'saksı', 'bahçe']),
  (ReminderTopic.gym, ['spor', 'salon', 'fitness', 'antrenman', 'pilates', 'yoga', 'gym']),
  (ReminderTopic.outdoor, ['koştu', 'koşu', 'koşma', 'yürüyüş', 'yürüdü', 'bisiklet', 'yüzme', 'yüzdü', 'havuz']),
  (ReminderTopic.family, [
    'anne', 'baba', 'dede', 'nine', 'aile', 'kardeş', 'teyze', 'amca', 'dayı',
    'telefon', 'aradı', 'arama', 'görüntülü',
  ]),
  (ReminderTopic.pet, ['kedi', 'köpek', 'mama', 'veteriner', 'akvaryum']),
  (ReminderTopic.book, ['kitap', 'okud', 'okuma', 'okuy']),
  (ReminderTopic.music, ['müzik', 'gitar', 'piyano', 'keman', 'bağlama']),
  (ReminderTopic.bill, ['fatura', 'kira\$', 'kiray', 'kiran', 'ödeme', 'öded', 'aidat']),
];

final _words = RegExp(r'[^\p{L}]+', unicode: true);

ReminderTopic topicOf(String name) {
  final words = lowerTr(name).split(_words).where((w) => w.isNotEmpty).toList();
  for (final (topic, stems) in _stems) {
    for (final stem in stems) {
      final whole = stem.endsWith('\$');
      final s = whole ? stem.substring(0, stem.length - 1) : stem;
      if (words.any((w) => whole ? w == s : w.startsWith(s))) return topic;
    }
  }
  return ReminderTopic.general;
}

/// `{n}` = days since the last time, `{k}` = days past the usual interval.
/// "due" is the day the interval runs out; "late" is the follow-up and the
/// nudge. Health topics stay plain: no jokes about medicine or doctors.
const _copy = <ReminderTopic, (List<String>, List<String>)>{
  ReminderTopic.hair: ([
    '{n} gün oldu. Berber seni özledi, ayna da biraz.',
    '{n} gün oldu. Saçın yeni bir başlangıç istiyor.',
  ], [
    '{n} gün oldu. Saçın artık kendi kararlarını veriyor.',
    '{k} gün geçti. Tarak pes etmeden bir randevu?',
  ]),
  ReminderTopic.nails: ([
    '{n} gün oldu. Tırnak makası çekmecede seni bekliyor.',
  ], [
    '{k} gün geçti. Beş dakikalık iş, tam şimdi.',
  ]),
  ReminderTopic.plant: ([
    '{n} gündür su yok. Sessizler ama not alıyorlar.',
    '{n} gün oldu. Bir bardak su, bir dünya teşekkür.',
  ], [
    '{n} gün oldu. Bir yaprak sararırsa sebebini biliyoruz.',
    '{k} gün geçti. Saksılar sessiz bir eylemde.',
  ]),
  ReminderTopic.bed: ([
    '{n} gün oldu. Bu gece mis gibi bir yatağı hak ediyorsun.',
  ], [
    '{n} gün oldu. Yastık da aynı fikirde.',
  ]),
  ReminderTopic.fridge: ([
    '{n} gün oldu. Arka raftakiler bilim deneyine dönüşmeden…',
  ], [
    '{k} gün geçti. Kapağı açınca sürpriz olmasın.',
  ]),
  ReminderTopic.clean: ([
    '{n} gün oldu. Bir şarkı aç, on beş dakika, bitti.',
    '{n} gün oldu. Toz tanecikleri örgütlenmeye başladı.',
  ], [
    '{k} gün geçti. Başlamak en zor kısmı, gerisi kolay.',
  ]),
  ReminderTopic.laundry: ([
    '{n} gün oldu. Sepet dolmak üzere, sen de biliyorsun.',
  ], [
    '{k} gün geçti. En sevdiğin tişört sırada bekliyor.',
  ]),
  ReminderTopic.gym: ([
    '{n} gündür salon yok. Dambıllar merak etmeye başladı.',
    '{n} gün oldu. Spor çantası kapının yanında güzel durur.',
  ], [
    '{n} gün oldu. Kaslar sessiz bir eylem başlattı.',
    '{k} gün geçti. Kısa bir antrenman da sayılır.',
  ]),
  ReminderTopic.outdoor: ([
    '{n} gün oldu. Dışarısı seni bekliyor.',
    '{n} gün oldu. Ayakkabılar hazır, sen?',
  ], [
    '{k} gün geçti. Yirmi dakika bile fark yaratır.',
  ]),
  ReminderTopic.family: ([
    '{n} gün oldu. Kısa bir "nasılsın" bile günü güzelleştirir.',
    '{n} gün oldu. Sesini duymak iyi gelir.',
  ], [
    '{n} gün oldu. Açılış cümlesi belli: "Nerelerdesin sen?"',
    '{k} gün geçti. İki dakikalık bir arama yeter.',
  ]),
  ReminderTopic.car: ([
    '{n} gün oldu. Motor teşekkür edemez ama edeceğini bil.',
  ], [
    '{k} gün geçti. Yolda kalmadan bir bakım iyi olur.',
  ]),
  ReminderTopic.pet: ([
    '{n} gün oldu. Patili ev arkadaşın da bu fikre katılıyor.',
  ], [
    '{k} gün geçti. Bakışlarından belli, sırası geldi.',
  ]),
  ReminderTopic.book: ([
    '{n} gün oldu. Ayraç aynı sayfada bekliyor.',
  ], [
    '{k} gün geçti. Birkaç sayfa da okumaktır.',
  ]),
  ReminderTopic.music: ([
    '{n} gün oldu. Enstrüman köşede kendini unutulmuş hissediyor.',
  ], [
    '{k} gün geçti. On dakika çal, gerisi gelir.',
  ]),
  ReminderTopic.bill: ([
    'Ödeme zamanı geldi. Son günü beklemeden halledelim mi?',
  ], [
    '{k} gün geçti. Gecikme bedeli çıkmadan bakmakta fayda var.',
  ]),
  ReminderTopic.doctor: ([
    'Son kontrolden bu yana {n} gün geçti. Randevu almak için iyi bir zaman.',
  ], [
    'Kontrol zamanı {k} gün geçti. Uygun olduğunda randevu almayı unutma.',
  ]),
  ReminderTopic.pill: ([
    'Sırası geldi. {n} gün önce almıştın.',
  ], [
    '{k} gün geçti. Yaptıysan dokun, işaretle.',
  ]),
  ReminderTopic.general: ([
    '{n} gün oldu, tam sırası.',
    '{n} gün oldu. Bugün iyi bir gün olabilir.',
    '{n} gün oldu. Aklının bir köşesinde duruyordu, değil mi?',
  ], [
    '{n} gün oldu, {k} gün geçti. Yaptıysan dokun, işaretle.',
    '{k} gün geçti. Geç olsun, güç olmasın.',
  ]),
};

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
  final lines = _copy[topicOf(name)]!.$1;
  return _fill(lines[_pick(seed, lines.length)], n, 0);
}

/// The body once the card is [k] days past its interval, [n] days in all.
String lateBody(String name, int n, int k, {required String seed}) {
  final lines = _copy[topicOf(name)]!.$2;
  return _fill(lines[_pick(seed, lines.length)], n, k);
}

/// Every line a topic can show — for tests.
List<String> linesFor(ReminderTopic topic) =>
    [..._copy[topic]!.$1, ..._copy[topic]!.$2];
