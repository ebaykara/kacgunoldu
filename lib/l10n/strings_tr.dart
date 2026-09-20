import '../domain/reminder_copy.dart' show ReminderTopic;
import 'strings.dart';

/// Türkçe — the app's original voice. Everything here is the copy the design
/// was written in; see `CLAUDE.md` for the lines that must not drift.
class TrStrings extends Strings {
  const TrStrings();

  @override
  AppLang get lang => AppLang.tr;

  @override
  String get langName => 'Türkçe';

  @override
  String get appHeadline => 'Kaç gün oldu?';

  @override
  String get cancel => 'Vazgeç';
  @override
  String get ok => 'Tamam';
  @override
  String get save => 'Kaydet';
  @override
  String get delete => 'Sil';
  @override
  String get deleteAll => 'Hepsini sil';
  @override
  String get back => 'Geri';
  @override
  String get close => 'Kapat';
  @override
  String get undo => 'Geri al';
  @override
  String get select => 'Seç';
  @override
  String get restore => 'Geri yükle';

  // -------------------------------------------------------------------- date

  @override
  List<String> get dow => const ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];

  @override
  List<String> get months => const [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  List<String> get monthsShort => const [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  @override
  String dayMonth(int day, int month, {int? year}) =>
      '$day ${months[month - 1]}${year == null ? '' : ' $year'}';

  @override
  String fullDate(int day, int month, int year) => '$day ${months[month - 1]} $year';

  @override
  String get relToday => 'bugün';
  @override
  String get relYesterday => 'dün';
  @override
  String relDaysAgo(int n) => '$n gün önce';
  @override
  String relWeeksAgo(int n) => '$n hafta önce';
  @override
  String relMonthsAgo(int n) => '$n ay önce';

  // --------------------------------------------------------------- frequency

  @override
  List<(int, String)> get frequencyPresets => const [
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

  @override
  String everyNDays(int days) => '$days günde bir';

  @override
  String goalSuffix(String frequencyLabel) =>
      ' Hedefin ${frequencyLabel.toLowerCase()}.';

  // ------------------------------------------------------------------ filter

  @override
  String get filterAll => 'Tümü';
  @override
  String get filterLate => 'Gecikenler';
  @override
  String get filterSoon => 'Sırası yakın';

  // ------------------------------------------------------- stats & card face

  @override
  String get notMarkedYet => 'Henüz işaretlenmedi';
  @override
  String get doneTodayMeta => 'Bugün yapıldı';

  @override
  String metaEvery(String date, int typical) => '$date ~$typical günde bir';

  @override
  String get ringNew => 'yeni';
  @override
  String ringDays(int n) => '$n gün';
  @override
  String get ringToday => 'bugün';
  @override
  String ringOver(int n) => '+$n gün';
  @override
  String get ringUnitSuffix => ' gün';
  @override
  String get ringUnit => 'gün';
  @override
  String get ringOverWord => 'geçti';
  @override
  String get ringLeftWord => 'kaldı';

  @override
  String get ringHintNew => 'ritmi henüz öğrenilmedi';
  @override
  String ringHintLeft(int n) => 'her zamanki aralığa $n gün kaldı';
  @override
  String get ringHintDueToday => 'her zamanki aralık bugün doluyor';
  @override
  String ringHintOver(int n) => 'her zamanki aralığı $n gün aştı';

  @override
  String get statusLearning => 'Ritim öğreniliyor';
  @override
  String statusDaysLeft(int n) => '$n gün kaldı';
  @override
  String get statusDueToday => 'Bugün sırası';
  @override
  String statusDaysOver(int n) => '$n gün geçti';

  @override
  String get unitDaysSince => 'gün oldu';
  @override
  String get unitNoRecord => 'kayıt yok';

  // ------------------------------------------------------------------- cards

  @override
  List<NamedCard> get templates => const [
    ('Diş fırçamı değiştirdim', 'tooth', 90),
    ('Klima filtresini temizledim', 'home', 90),
    ('Arabanın yağını değiştirdim', 'car', 365),
    ('Lastik basıncına baktım', 'car', 30),
    ('Nevresimi değiştirdim', 'bed', 14),
    ('Havluları yıkadım', 'laundry', 7),
    ('Buzdolabını temizledim', 'fridge', 30),
    ('Banyoyu temizledim', 'bath', 7),
    ('Bitkileri suladım', 'plant', 3),
    ('Saçımı kestirdim', 'scissors', 30),
    ('Diş hekimine gittim', 'tooth', 180),
    ('Kan tahlili yaptırdım', 'doctor', 365),
    ('Veterinere götürdüm', 'pet', 365),
    ('Anneme telefon ettim', 'phone', 7),
    ('Kirayı ödedim', 'money', 30),
    ('Kitap bitirdim', 'book', 30),
  ];

  @override
  List<NamedCard> get suggestions => const [
    ('Saçımı kestirdim', 'scissors', 30),
    ('Diş hekimine gittim', 'tooth', 180),
    ('Spor salonuna gittim', 'gym', 3),
    ('Çarşafları değiştirdim', 'bed', 14),
    ('Bitkileri suladım', 'plant', 3),
    ('Anneme telefon ettim', 'phone', 7),
  ];

  @override
  List<(String, int, List<int>)> get seedCards => const [
    ('Diş hekimine gittim', 214, [186, 192]),
    ('Spor salonuna gittim', 11, [3, 4, 2, 3]),
    ('Saçımı kestirdim', 46, [34, 38]),
    ('Çarşafları değiştirdim', 9, [11, 12, 10]),
    ('Anneme telefon ettim', 3, [4, 2, 5]),
    ('Bitkileri suladım', 5, [4, 3, 4]),
    ('Arabanın yağını değiştirdim', 121, [160, 175]),
    ('Buzdolabını temizledim', 28, [30, 26]),
    ('Yüzmeye gittim', 17, [9, 8, 11]),
  ];

  @override
  Map<String, String> get glyphLabels => const {
    'gym': 'spor',
    'swim': 'yüzme',
    'run': 'koşu',
    'bike': 'bisiklet',
    'bed': 'yatak',
    'scissors': 'makas',
    'tooth': 'diş',
    'doctor': 'doktor',
    'pill': 'ilaç',
    'plant': 'bitki',
    'fridge': 'buzdolabı',
    'clean': 'temizlik',
    'laundry': 'çamaşır',
    'bath': 'banyo',
    'phone': 'telefon',
    'car': 'araba',
    'book': 'kitap',
    'pet': 'evcil hayvan',
    'cart': 'alışveriş',
    'coffee': 'kahve',
    'music': 'müzik',
    'money': 'para',
    'mail': 'posta',
    'heart': 'kalp',
    'home': 'ev',
    'spark': 'yıldız',
  };

  @override
  String themeName(String id) => switch (id) {
    'okyanus' => 'Okyanus',
    'orman' => 'Orman',
    'lavanta' => 'Lavanta',
    'gul' => 'Gül',
    'gece' => 'Gece',
    _ => 'Kiremit',
  };

  // ------------------------------------------------------------------ header

  @override
  String lateBadge(int n) => '$n kart gecikti';
  @override
  String get lateBadgeHint => 'gecikenleri görmek için dokun';
  @override
  String get profile => 'Profil';
  @override
  String get listView => 'Liste görünümü';
  @override
  String get gridView => 'Izgara görünümü';

  @override
  String get tabCards => 'Kartlar';
  @override
  String get tabTimeline => 'Zaman tüneli';
  @override
  String get newCard => 'Yeni kart';

  @override
  String cardSemantics(String name, int days, bool late, String ringHint) =>
      '$name, $days gün önce${late ? ', geç' : ''}. $ringHint';
  @override
  String get hintOpenCard => 'ayrıntılar için dokun';
  @override
  String get hintOpenCardDrag =>
      'ayrıntılar için dokun, yer değiştirmek için basılı tutup sürükle';

  // -------------------------------------------------------------------- home

  @override
  String archiveLink(int n) => 'Arşiv ($n)';
  @override
  String get noMatchingCards => 'Eşleşen kart yok.';
  @override
  String get searchCards => 'Kartlarda ara';
  @override
  String get clearSearch => 'Aramayı temizle';

  // ---------------------------------------------------------------- timeline

  @override
  String get timelineNew => 'Yeni';
  @override
  String get timelineDueToday => 'sırası bugün';
  @override
  String gapApart(int n) => '$n gün arayla';
  @override
  String get firstRecord => 'ilk kayıt';

  @override
  String timelineAge(int offset) => switch (offset) {
    0 => 'bugün',
    1 => 'dün',
    _ => '$offset gün',
  };

  @override
  String get rangeAll => 'Tümü';
  @override
  String get rangeWeek => 'Hafta';
  @override
  String get rangeMonth => 'Ay';
  @override
  String get timelineEmptyAll => 'Henüz hiç kayıt yok.';
  @override
  String get timelineEmptyWeek => 'Son bir haftada kayıt yok.';
  @override
  String get timelineEmptyMonth => 'Son bir ayda kayıt yok.';
  @override
  String timelineRowSemantics(String date, String name, String age, String status) =>
      '$date, $name, $age, $status';

  // --------------------------------------------------------------- gap chart

  @override
  String gapsSemantics(List<int> gaps, int? typical) =>
      'Kayıtlar arası aralıklar: ${gaps.join(', ')} gün'
      '${typical != null ? '. Ritim $typical gün' : ''}';
  @override
  String get gapOldest => 'en eski';
  @override
  String get gapNewest => 'en yeni';
  @override
  String gapRhythm(int n) => 'ritim $n gün';

  // ------------------------------------------------------------- empty state

  @override
  String get emptyTitle => 'Hayatındaki küçük\nşeyleri takip etmeye başla.';
  @override
  String get emptyBody => 'En son ne zaman yaptığını merak ettiğin\nbir şey ekle.';
  @override
  String get emptyCta => 'İlk kartını oluştur';
  @override
  String get suggestedCards => 'Önerilen kartlar';

  // ------------------------------------------------------------ record sheet

  @override
  String get whenDidYouDoIt => 'Ne zaman yaptın?';
  @override
  String get pickEarlier => 'Daha geriden seç';
  @override
  String get pickFromCalendar => 'Takvimden seç';
  @override
  String get notYetDone => 'Henüz yapmadım';
  @override
  String get today => 'Bugün';
  @override
  String get yesterday => 'Dün';
  @override
  String get twoDaysAgo => '2 gün önce';
  @override
  String daysAgoOn(int offset, String dow, String dom) => '$offset gün önce, $dow $dom';

  // ------------------------------------------------------------ card details

  @override
  String get menuTurnOffReminder => 'Hatırlatmayı kapat';
  @override
  String get menuRemindMe => 'Bana hatırlat';
  @override
  String get menuReminderOffDetail => 'Bu kart için bildirim gelmiyor olacak';
  @override
  String get menuReminderOnDetail => 'Sırası gelince bildirim gönder';
  @override
  String get toastReminderOn => 'Hatırlatma açıldı';
  @override
  String get menuEdit => 'Düzenle';
  @override
  String get menuEditDetail => 'Ad, simge ve sıklık';
  @override
  String get menuAddDay => 'Başka bir gün ekle';
  @override
  String get menuAddDayDetail => 'Geçmişe kayıt ekle';
  @override
  String get menuAddToHome => 'Ana ekrana ekle';
  @override
  String get menuAddToHomeDetail => 'Bu kartı widget olarak göster';
  @override
  String get menuShare => 'Paylaş';
  @override
  String get menuShareDetail => 'Kartın bir kopyasını birine gönder';
  @override
  String get menuUnarchive => 'Arşivden çıkar';
  @override
  String get menuArchive => 'Arşivle';
  @override
  String get menuUnarchiveDetail => 'Kartlarının arasına geri döner';
  @override
  String get menuArchiveDetail => 'Kayıtlar kalır; listeden kalkar, hatırlatılmaz';
  @override
  String get menuDeleteCard => 'Kartı sil';
  @override
  String get menuDeleteCardDetail => 'Bütün kayıtlarıyla birlikte';
  @override
  String confirmDeleteCardTitle(String name) => '“$name” silinsin mi?';
  @override
  String get confirmDeleteCardMessage =>
      'Bu kartın bütün kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.';
  @override
  String get cardOptions => 'Kart seçenekleri';
  @override
  String get archivedBanner => 'Bu kart arşivde';

  @override
  String get recordOverline => 'Kayıt';
  @override
  String get addNote => 'Not ekle';
  @override
  String get editNote => 'Notu düzenle';
  @override
  String get noteDetail => 'Örn. kilometre, ne yapıldığı';
  @override
  String get notePlaceholder => 'Örn. 45.200 km, dolgu yapıldı';
  @override
  String get changeDate => 'Tarihi değiştir';
  @override
  String get changeDateDetail => 'Bu kaydı başka bir güne taşı';
  @override
  String get newDate => 'Yeni tarih';
  @override
  String get move => 'Taşı';
  @override
  String get deleteRecord => 'Bu kaydı sil';
  @override
  String get deleteRecordDetail => 'Geri alabilirsin';

  @override
  String daysSinceSemantics(int n) => '$n gün oldu';
  @override
  String get noRecordYetLower => 'henüz kayıt yok';
  @override
  String get didItTodayLower => 'bugün yaptın';
  @override
  String get factLastRecord => 'Son kayıt';
  @override
  String get factGoal => 'Hedef';
  @override
  String get factAverage => 'Ortalama';
  @override
  String nDays(int n) => '$n gün';
  @override
  String actualAverage(int n) => 'Gerçekte ortalama $n günde bir yapıyorsun.';
  @override
  String get markedToday => 'Bugün işaretlendi';
  @override
  String get didItToday => 'Bugün yaptım';
  @override
  String get pickAnotherDay => 'Başka bir gün seç';
  @override
  String get sectionGaps => 'Aralıklar';
  @override
  String get sectionHistory => 'Geçmiş';
  @override
  String nRecords(int n) => '$n kayıt';
  @override
  String get historyEmpty => 'Henüz kayıt yok. Yaptığında yukarıdaki düğmeyle işaretle.';
  @override
  String get showLess => 'Daha az göster';
  @override
  String showAll(int n) => 'Tümünü göster ($n)';
  @override
  String historySemantics(String date, int? gap, String? note) =>
      '$date${gap != null ? ', $gap gün arayla' : ''}'
      '${note != null ? ', not: $note' : ''}';

  // --------------------------------------------------------------- card form

  @override
  String get notifyPermissionOff =>
      'Bildirim izni kapalı. Telefon ayarlarından açabilirsin.';
  @override
  String notifyHintRhythm(String time) => 'Sırası gelince saat $time civarı haber veririm.';
  @override
  String get notifyHintNoRhythm =>
      'Ritmini öğrenince haber veririm (3 kayıttan sonra) ya da bir sıklık seç.';
  @override
  String get cardReminderTime => 'Bu kartın hatırlatma saati';
  @override
  String get pickIcon => 'Simge seç';
  @override
  String get editCardTitle => 'Kartı düzenle';
  @override
  String get whatDidYouDo => 'Ne yaptın?';
  @override
  String get namePlaceholder => 'Örn. Saçımı kestirdim';
  @override
  String get howOften => 'Ne sıklıkla tekrarlıyorsun?';
  @override
  String get customFrequency => 'Özel';
  @override
  String get frequencyHintNone => 'Seçmezsen ritmini kayıtlarından kendim öğrenirim.';
  @override
  String frequencyHint(String label) =>
      '$label demek: bu aralık belirgin şekilde aşılınca kart “gecikti” olur.';
  @override
  String get remindMe => 'Bana hatırlat';
  @override
  String reminderTimeSemantics(String time) => 'Hatırlatma saati $time';
  @override
  String get timeGlobal => 'Saat (genel ayar)';
  @override
  String get timeThisCard => 'Bu kartın saati';
  @override
  String get backToGlobalTime => 'Genel saate dön';
  @override
  String get advancedOptions => 'Gelişmiş seçenekler';
  @override
  String get iconLabel => 'Simge';
  @override
  String get createCard => 'Kartı oluştur';
  @override
  String get everyHowManyDays => 'Kaç günde bir?';
  @override
  String get decrease => 'Azalt';
  @override
  String get increase => 'Artır';
  @override
  String get dayIntervalUnit => 'günde bir';
  @override
  String get autoShort => 'oto';
  @override
  String get autoIcon => 'Otomatik simge';
  @override
  String get readyMadeCards => 'Hazır kartlar';

  // ------------------------------------------------------------- late screen

  @override
  String get lateTitle => 'Gecikenler';
  @override
  String get swipeRightIfDone => 'Yaptıysan sağa kaydır';
  @override
  String lateBanner(int n) => '$n kartın zamanı geçti';
  @override
  String get lateBannerSub => 'Hemen kontrol et, tekrarını planla.';
  @override
  String get allClear => 'Her şey yerinde.';
  @override
  String get allClearSub => 'Geciken hiçbir şey yok — nadir bir gün.';

  // ----------------------------------------------------------------- archive

  @override
  String get archiveTitle => 'Arşiv';
  @override
  String get archiveEmpty =>
      'Arşivde kart yok. Bir kartı kartın ⋯ menüsünden arşivleyebilirsin.';
  @override
  String get archiveNote =>
      'Arşivdeki kartlar kart listende görünmez, gecikme sayılmaz ve '
      'hatırlatılmaz. Kayıtları olduğu gibi durur.';

  // ------------------------------------------------------------------ legend

  @override
  String get legendTitle => 'Durum renkleri';
  @override
  String get legendLead => 'Kartın rengi, durumunu anlatır.';

  @override
  List<LegendRow> get legendRows => const [
    (
      'Yeni',
      'Yakın zamanda yaptın; her zamanki aralığın yarısı bile dolmadı.',
      'Çarşafları değiştirdim',
    ),
    ('Normal', 'Her şey yolunda, sırası henüz gelmedi.', 'Bitkileri suladım'),
    ('Yaklaşıyor', 'Her zamanki aralık dolmak üzere ya da doldu.', 'Saçımı kestirdim'),
    ('Gecikti', 'Her zamanki aralığı belirgin şekilde aştı.', 'Spor salonuna gittim'),
  ];

  @override
  String get ringSectionTitle => 'Halka ne gösterir?';
  @override
  String get ringSectionBody =>
      'Halka, bir sonraki sefere ne kadar kaldığını gösterir. '
      '“4 gün” dört gün kaldı, “bugün” sırası bugün, “+8 gün” her zamanki '
      'aralığı sekiz gün aştı demek. “yeni” ise ritim henüz öğrenilmedi demek — '
      'üç kayıttan sonra ya da bir sıklık seçince öğrenilir.';

  // ------------------------------------------------------------------- theme

  @override
  String get themeTitle => 'Tema';
  @override
  String get themeLead => 'Renklerini seç.';
  @override
  String get themeNote =>
      'Kart durumlarının anlamı her temada aynı kalır: geciken kart her zaman en koyu renkte.';
  @override
  String themeSemantics(String name) => '$name teması';

  // ----------------------------------------------------------------- profile

  @override
  String get profileTitle => 'Profil';
  @override
  String get settings => 'Ayarlar';
  @override
  String get addYourName => 'Adını ekle';
  @override
  String editProfileSemantics(String name) => '$name, profili düzenle';
  @override
  String get tapToPersonalise => 'Profilini kişiselleştirmek için dokun';
  @override
  String get tapToEdit => 'Düzenlemek için dokun';
  @override
  String get statTotalCards => 'Toplam kart';
  @override
  String get statTotalRecords => 'Toplam kayıt';
  @override
  String get statNewThisMonth => 'Bu ay yeni';
  @override
  String get monthSummary => 'Bu ayın özeti';
  @override
  String recordsMade(int n) => '$n kayıt yaptın';
  @override
  String get vsLastMonth => 'Geçen aya göre ';
  @override
  String get insightRegular => 'En düzenli yaptığın';
  @override
  String insightRegularDetail(int n) => 'Ortalama $n günde bir';
  @override
  String get insightRegularEmpty => 'Üç kayıttan sonra burada görünür.';
  @override
  String get insightNeglected => 'En uzun süredir yapmadığın';
  @override
  String get insightNeglectedEmpty => 'Henüz kayıt yok.';
  @override
  String get fieldName => 'Adın';
  @override
  String get fieldNameHint => 'Adını yaz';
  @override
  String get fieldHandle => 'Kullanıcı adı';
  @override
  String get fieldHandleHint => 'isteğe bağlı';

  // ---------------------------------------------------------------- settings

  @override
  String get settingsTitle => 'Ayarlar';
  @override
  String get groupAppearance => 'Görünüm';
  @override
  String get groupProfile => 'Profil';
  @override
  String get groupCards => 'Kartlar';
  @override
  String get groupNotifications => 'Bildirimler';
  @override
  String get groupHomeWidget => "Ana ekran widget'ı";
  @override
  String get groupBackup => 'Yedekleme';
  @override
  String get groupDanger => 'Tehlikeli bölge';
  @override
  String get groupAbout => 'Hakkında';

  @override
  String get language => 'Dil';
  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get theme => 'Tema';
  @override
  String get editProfile => 'Profili düzenle';
  @override
  String get statusColours => 'Durum renkleri';
  @override
  String get statusColoursDetail => 'Kartın rengi ne anlatıyor?';
  @override
  String get resetOrder => 'Sıralamayı sıfırla';
  @override
  String get resetOrderDetail =>
      'Sürükleyerek verdiğin sıra unutulur, kartlar aciliyete göre dizilir';
  @override
  String get resetOrderNoop => 'Kartlar zaten aciliyete göre sıralı';
  @override
  String get archive => 'Arşiv';
  @override
  String get archiveEmptyDetail => 'Arşivde kart yok';
  @override
  String archiveCount(int n) => '$n kart arşivde';
  @override
  String get importShared => 'Paylaşılan kartı ekle';
  @override
  String get importSharedDetail => 'Sana gönderilen mesajı kopyala, sonra dokun';
  @override
  String get loadSamples => 'Örnek kartları ekle';
  @override
  String get loadSamplesDetail => 'Uygulamayı denemek için hazır kartlar';
  @override
  String get samplesAlreadyThere => 'Örnek kartların hepsi zaten ekli';

  @override
  String get reminderTime => 'Hatırlatma saati';
  @override
  String get reminderTimeNoneDetail => 'Kart eklerken “Bana hatırlat”ı aç';
  @override
  String reminderTimeCount(int n) => '$n kart için hatırlatma açık';
  @override
  String get sendTestNotification => 'Test bildirimi gönder';
  @override
  String get sendTestNotificationDetail => 'Bildirimin nasıl görüneceğini gör';

  @override
  String get addCardWidget => "Kart widget'ı ekle";
  @override
  String get addCardWidgetDetail => 'Tek bir kartın kaç gün olduğu';
  @override
  String get addListWidget => "Kartlar widget'ı ekle";
  @override
  String get addListWidgetDetail => 'Sırası en yakın kartlar bir arada';
  @override
  String get addHomeWidget => 'Ana ekrana widget ekle';
  @override
  String get addHomeWidgetDetail => 'Kartların uygulamayı açmadan görünsün';
  @override
  String get doneButtonSetting => '“Bugün yaptım” düğmesi';
  @override
  String get doneButtonSettingDetail => "Widget'tan tek dokunuşla işaretle";

  @override
  String get systemBackup => 'Telefonun yedeği';
  @override
  String get systemBackupDetail =>
      'Google ya da iCloud yedeği açıksa kartların da yedeklenir';

  @override
  List<String> get systemBackupExplainer => const [
    'Android’de Google hesabına yedekleme, iPhone’da iCloud yedeği '
        'açıksa kartların ve kayıtların da otomatik olarak o yedeğe '
        'girer.',
    'Yeni telefonu kurarken bu yedekten geri yüklersen kartların '
        'kendiliğinden gelir; hatırlatmalar da yeniden kurulur.',
    'Yedeği telefonun ayarlarından açıp kapatabilirsin. Bu yedeği '
        'Google ya da Apple tutar; biz göremeyiz.',
    'Yedek günde bir kez, telefon şarjdayken ve Wi-Fi varken alınır; '
        'bugünkü son kayıtların henüz yedekte olmayabilir.',
    'Geri yükleme yalnızca uygulamayı kurarken olur; uygulama '
        'kuruluyken yedeğe dönemezsin. Mağaza dışından kurulan '
        'sürümlerde geri yükleme her telefonda çalışmayabilir.',
    'Yedeği kapatmışsan hiçbir şey yedeklenmez. Bunun yerine '
        'Ayarlar’daki “Yedeği panoya kopyala” ile verilerini elle '
        'saklayabilirsin.',
  ];

  @override
  String get copyBackup => 'Yedeği panoya kopyala';
  @override
  String get copyBackupDetail => 'Notlarına ya da kendine mesaj olarak yapıştır';
  @override
  String get restoreBackup => 'Panodaki yedeği geri yükle';
  @override
  String get restoreBackupDetail => 'Kopyaladığın yedeği bu cihaza aktar';
  @override
  String get exportCsv => 'CSV olarak dışa aktar';
  @override
  String get exportCsvDetail => 'Bütün kayıtlar, tablo programında açılır';
  @override
  String get csvSubject => 'Kaç Gün Oldu? kayıtları';
  @override
  String get csvHeader => 'Kart,Tarih,Not';

  @override
  String get backupCopied => 'Yedek panoya kopyalandı';
  @override
  String get noBackupOnClipboard => 'Panoda yedek bulunamadı';
  @override
  String get restoreTitle => 'Yedek geri yüklensin mi?';
  @override
  String get restoreMessage =>
      'Şu anki bütün kartların, panodaki yedekle değiştirilecek. Bu işlem geri alınamaz.';
  @override
  String get notAValidBackup => 'Panodaki metin geçerli bir yedek değil';
  @override
  String get noSharedCardOnClipboard => 'Panoda paylaşılan bir kart bulunamadı';

  @override
  String get deleteAllCards => 'Bütün kartları sil';
  @override
  String get notUndoable => 'Geri alınamaz';
  @override
  String get deleteAllTitle => 'Bütün kartlar silinsin mi?';
  @override
  String get deleteAllMessage =>
      'Bütün kartlar ve kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.';

  @override
  String get privacyPolicyRow => 'Gizlilik politikası';
  @override
  String get privacyPolicyRowDetail => 'Hiçbir veri toplanmaz';
  @override
  String get termsRow => 'Kullanım koşulları';
  @override
  String get openSourceLicenses => 'Açık kaynak lisansları';
  @override
  String versionLine(String version) => 'Kaç gün oldu? · $version';
  @override
  String get dataStaysHere => 'Bütün verin yalnızca bu cihazda durur.';
  @override
  String lastUpdated(String date) => 'Son güncelleme: $date';
  @override
  String get legalContactTitle => 'Kaç Gün Oldu? · EMA Labs';

  // ------------------------------------------------------------ home widgets

  @override
  String get widgetPinned => 'Widget ana ekrana eklendi';
  @override
  String get widgetCantPinTitle => 'Telefonun eklemeye izin vermiyor';
  @override
  String get widgetCantPinBody =>
      'Onay penceresinde “Reddet”i seçince telefon bu isteği bir daha sormadan '
      'engelliyor. İzinler sayfasında “Ana ekran kısayolları”nı açıp tekrar dene.';
  @override
  String get widgetOpenPermission => 'İzni aç';
  @override
  String get widgetShowManual => 'Elle eklemeyi göster';

  @override
  List<String> widgetHelpSteps({required bool ios, String? pick}) => ios
      ? [
          'Ana ekranda boş bir yere basılı tut, sol üstteki Düzenle → Widget ekle’ye dokun.',
          'Listeden Kaç Gün Oldu?’yu seç: tek kart için Kart, birkaçı için Kartlar.',
          pick == null
              ? 'Kart’ın göstereceği kartı seçmek için widget’a basılı tut → Widget’ı Düzenle.'
              : 'Widget’a basılı tut → Widget’ı Düzenle → Kart: $pick.',
          'Kilit ekranına da ekleyebilirsin: kilit ekranına basılı tut → Özelleştir.',
        ]
      : [
          'Ana ekranda boş bir yere basılı tut, Widget’lar’a dokun.',
          'Kaç Gün Oldu?’yu bul: tek kart için Kart, birkaçı için Kartlar.',
          pick == null
              ? 'Kart’ı ekleyince hangi kartı göstereceğini sorar.'
              : 'Kart’ı ekleyince açılan listeden $pick kartını seç.',
        ];

  @override
  String get widgetHelpTitle => 'Ana ekrana widget ekle';
  @override
  String get widgetHelpBody =>
      'Kartlarının kaç gün olduğunu uygulamayı açmadan gör; '
      '“Bugün yaptım”a widget’tan dokun.';

  @override
  Map<String, String> get widgetStrings => const {
    'title': 'Kaç gün oldu?',
    'late': '{n} kart gecikti',
    'notMarked': 'Henüz işaretlenmedi',
    'learning': 'Ritim öğreniliyor',
    'daysLeft': '{n} gün kaldı',
    'dueToday': 'Bugün sırası',
    'daysOver': '{n} gün geçti',
    'unitDays': 'gün oldu',
    'unitNone': 'kayıt yok',
    'doneToday': 'Bugün yapıldı',
    'markDone': 'Bugün yaptım',
    'firstCard': 'İlk kartını oluştur',
    'openApp': 'Kartlarını görmek için uygulamayı aç',
  };

  // --------------------------------------------------------------- reminders

  @override
  String get notificationChannelName => 'Hatırlatmalar';
  @override
  String get notificationChannelDescription => 'Bir kartın sırası geldiğinde haber verir.';
  @override
  String get sampleCardName => 'Saçımı kestirdim';

  @override
  Map<ReminderTopic, (List<String>, List<String>)> get reminderCopy => const {
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

  // -------------------------------------------------------------- store/undo

  @override
  String recordedSnack(String name, String relative) => '$name · $relative';
  @override
  String cardAdded(String name) => '“$name” eklendi';
  @override
  String cardDeleted(String name) => '“$name” silindi';
  @override
  String recordDeleted(String date) => '$date kaydı silindi';
  @override
  String recordMoved(String date) => 'Kayıt $date olarak güncellendi';
  @override
  String get noteSaved => 'Not kaydedildi';
  @override
  String get noteDeleted => 'Not silindi';
  @override
  String cardArchived(String name) => '“$name” arşivlendi';
  @override
  String cardUnarchived(String name) => '“$name” arşivden çıktı';
  @override
  String cardAlreadyThere(String name) => '“$name” zaten kartların arasında';
  @override
  String get cardUpdated => 'Kart güncellendi';
  @override
  String get orderReset => 'Kartlar aciliyete göre sıralandı';
  @override
  String get allCardsDeleted => 'Bütün kartlar silindi';
  @override
  String samplesAdded(int n) => '$n örnek kart eklendi';
  @override
  String cardsRestored(int n) => '$n kart geri yüklendi';
  @override
  String widgetMarkedOne(String name) => "$name · widget'tan kaydedildi";
  @override
  String widgetMarkedMany(int n) => "$n kayıt widget'tan eklendi";

  // ------------------------------------------------------------------- share

  @override
  String shareMessage(String name, String link) =>
      '“$name” kartını seninle paylaştım.\n'
      'Kaç Gün Oldu? uygulamasında bağlantıya dokun ya da bu mesajı kopyalayıp '
      'Ayarlar → Paylaşılan kartı ekle’yi seç.\n\n'
      '$link';

  // ------------------------------------------------------------------ casing

  /// Dart's [String.toUpperCase] maps `i` to the ASCII `I`, which is wrong in
  /// Turkish — `ilaç` has to become `İlaç`, and a dotless `ı` becomes `I`.
  @override
  String upper(String text) {
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

  @override
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return upper(text[0]) + text.substring(1);
  }
}
