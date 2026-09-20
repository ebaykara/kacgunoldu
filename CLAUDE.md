# Kaç Gün Oldu? — çalışma notları

Flutter (3.44 / Dart 3.12) mobil uygulama. Tek soru: *bunu en son ne zaman yaptım?*
Tasarım `Ne Zaman v2.dc.html` hifi handoff'undan birebir kodlandı (MD3 + Apple HIG).
Paket adı `kac_gun_oldu`, uygulama kimliği `com.emalabs.kacgunoldu`.

## Çalışma kuralları

- **Dosyaları baştan sona tekrar tekrar okuma.** Aşağıdaki harita neyin nerede
  olduğunu söyler; sadece değiştireceğin dosyayı aç.
- **Sadece değiştirmen gereken yere dokun.** Çevresindeki kodu, biçimlendirmeyi,
  yorumları, alakasız satırları olduğu gibi bırak.
- **Çalışan şeyleri bozma.** Bir davranışı değiştirmen istendiyse yalnızca onu
  değiştir; "bu arada şunu da düzelteyim" yapma.
- Bitirmeden önce `flutter analyze` + `flutter test` çalıştır. İkisi de temiz olmalı.

## Doğrulama

```bash
flutter analyze   # 0 uyarı olmalı
```

```bash
flutter test      # 209 test, hepsi geçmeli
```

```bash
flutter build apk --debug   # Android derlemesi (yavaş, sadece gerekirse)
```

**Web sunucusu başlatıp görsel kontrol yapma.** Kullanıcı kendi emülatöründe test
ediyor. `flutter analyze` + `flutter test` yeterli; akış doğrulaması zaten widget
testleriyle yapılıyor. Kullanıcı açıkça isterse o zaman `flutter run -d chrome`.

## Dosya haritası

```
lib/
  main.dart                 tema, dil (locale), sistem çubukları, yazı boyutu sınırı (1.3x)
  l10n/strings.dart         AppLang (system/tr/en) · S (etkin dilin metinleri) · applyLang
                            · Strings (soyut: bütün metinler, veriler, biçimler)
  l10n/strings_tr.dart      Türkçe — tasarımın özgün metinleri
  l10n/strings_en.dart      İngilizce
  theme/tokens.dart         Palette + palettes (6 tema) · AppColor · Space · Radii
                            · Elevation · Motion · Layout
  theme/system_bars.dart    çubuk stili + SystemBarsRegion (kökte; bkz. tuzak 16)
  theme/typography.dart     ui() · display() · overline()
  domain/card.dart          Card (+ isteğe bağlı icon/every/created/notes/archived/remindAt)
                            · Tier · AppTab
  domain/date.dart          DateKey aritmetiği, Türkçe tarih biçimleri
  domain/logic.dart         tiers · typicalInterval · statsFor · decorate · orderCards
                            · averageGap
  domain/order.dart         applyOrder — otomatik sıra vs kalıcı sürükleme sırası
                            · mergeSubsetOrder (filtreliyken sürükleme)
  domain/filter.dart        arama + Tümü/Gecikenler/Sırası yakın (6+ kartta görünür)
  domain/share.dart         sunucusuz kart paylaşımı (kacgunoldu://app/share/<base64url>)
                            · cardsCsv (CSV dışa aktarma)
  domain/templates.dart     Yeni kart'taki "Hazır kartlar"
  domain/text.dart          capitalizeTr · upperTr (dile göre) · lowerTr · foldedForms
                            (eşleştirme: hem Türkçe hem düz küçük harf) · initialsOf
  domain/frequency.dart     "Ne sıklıkla" çipleri (Her gün … Yılda bir)
  domain/icon_guess.dart    addan simge tahmini (diş → tooth, spor → gym …); anahtar
                            kelimeler iki dilde de aynı listede
  domain/insights.dart      profil sayıları: toplamlar, aylık, en düzenli, en ihmal
  domain/reminders.dart     planReminders: hangi bildirim ne zaman (saf)
  domain/reminder_copy.dart bildirim metinleri: konu KART ADINDAN (simgeden değil); kökler
                            iki dilde tek listede, şablonlar S.reminderCopy'de
  services/reminders.dart   Reminders arayüzü · LocalReminders (OS) · NoopReminders
  services/home_widgets.dart  ana ekran widget'ları: widgetSnapshot · HomeWidgets
                            (Platform/Noop) · cardIdFromLink (bkz. tuzak 18)
  storage/seed.dart         örnek kartlar — YALNIZCA Ayarlar → "Örnek kartları ekle"
                            (ilk açılış boş başlar; mağaza sürümü uydurma veri açmaz)
  storage/repository.dart   CardRepository + Profile — shared_preferences
  state/card_store.dart     CardStore (ChangeNotifier): kayıt, geri alma, silme,
                            kayıt silme/taşıma, düzenleme, profil, yedek al/yükle,
                            sıralama, gece yarısı devri, lifecycle
  screens/home_screen.dart  Kartlar + Zaman tüneli sekmeleri, boş durum
  screens/card_detail_screen.dart   kart detayı: Bugün yaptım, geçmiş, ⋯ menüsü
  screens/card_form_screen.dart     Yeni kart / Kartı düzenle (sıklık, simge)
  screens/late_screen.dart          Gecikenler (sağa kaydır = bugün yaptım)
  screens/profile_screen.dart       Profil + istatistikler
  screens/settings_screen.dart      Ayarlar: sıralama, arşiv, paylaşılan kart, örnekler, yedek
                                    (telefon yedeği bilgisi, CSV), silme, Hakkında
  screens/archive_screen.dart       Arşiv: listeden kaldırılmış kartlar
  screens/legal_screen.dart         Gizlilik politikası / Kullanım koşulları (legal_text.dart'tan)
  legal/                            legal_model · legal_text (ÜRETİLİR: TR + EN) · font_licenses (OFL)
  app_info.dart                     appVersion (pubspec ile aynı; test kontrol eder)
  screens/legend_screen.dart        Durum renkleri
  screens/theme_screen.dart         Tema seçici (canlı önizlemeli)
  services/launch_theme.dart        açılış animasyonuna 'hazırım' + splash teması (kanal)
  widgets/                  card_tile (+ DayCountLine) · card_row_tile (liste) · card_status · rhythm_ring · halo · day_count · card_glyph
                            app_sheet · record_sheet · draggable_card_grid
                            header (+ Avatar) · fab · bottom_tab_bar · app_snackbar
                            store_snack · timeline · empty_state · icons · ui
                            confirm_destructive · gap_chart (detayda "Aralıklar")
                            · note_sheet (kayda not)
test/  domain · l10n · storage · state · theme · widgets · screens
      flutter_test_config.dart: bütün testlerde cihaz dilini Türkçe'ye sabitler
store/  mağaza metinleri, gizlilik politikası, Play form cevapları, görseller (README)
tool/create_upload_key.ps1   yükleme anahtarı + android/key.properties (git dışı)
tool/gen_widget_glyphs.py    kart simgelerinin widget kopyaları (Android wg_* + iOS glyph_*)
tool/widget_previews_test.dart  Android widget menüsü önizlemeleri (drawable-nodpi/widget_preview_*):
                            `flutter test tool/widget_previews_test.dart`; widget görünümü değişince
lib/widgets/home_widget_help.dart  "Ana ekrana widget ekle" adımları (iOS; sabitleyemeyen Android)
android/.../kacgunoldu/widget/  CardWidget (Kart, 2×2, seçilebilir) · CardListWidget (Kartlar)
                            · WidgetSnapshot (mantık) · WidgetViews · CardWidgetConfigActivity
ios/KacGunOlduWidget/        WidgetKit uzantısı (iOS 17+): Kart (küçük + kilit ekranı,
                            AppIntent ile kart seçimi) · Kartlar (orta, büyük)
      fake_reminders.dart: bildirim servisinin kayıt tutan sahtesi
```

Dış bağımlılıklar: `shared_preferences`; bildirimler için `flutter_local_notifications`,
`timezone`, `flutter_timezone`. `flutter_localizations` (SDK) takvim
ve sistem diyaloglarını Türkçe yapar. Fontlar `assets/fonts/` altında paketli.
Kart simgeleri Material ikonları; diş simgesi `card_glyph.dart`'ta elle çizili.

## Değişmemesi gereken kurallar

Bunlar tasarımdan gelir; bilerek istenmedikçe dokunma (`domain/logic.dart`):

| Değer | Kural |
| --- | --- |
| `days` | `recs[0]` ile bugün arası tam takvim günü |
| `typical` | kullanıcı sıklık seçtiyse `every`; yoksa boşlukların medyanı — **2 boşluktan azsa `null`** (3 kayıttan az) |
| `ratio` | `days / typical`, yoksa `min(0.95, days / 30)` |
| `isLate` | `typical != null && days > typical * 1.25 + 1` |
| kademe | `late` → `soon` (`ratio > 0.95`) → `fresh` (`ratio < 0.5`) → `calm` |
| `pct` | `clamp(3, round(ratio * 100), 100)` |
| `remaining` | `typical - days` |

`* 1.25 + 1`'deki **+1**, kısa aralıklı kartların tek günlük gecikmede "geç"
damgası yemesini engeller. Kaldırma.

Kalıcı olan kart verisi `{ id, name, recs }` + isteğe bağlı `icon`, `every`
(gün), `created`, `notify` ve `archived` (yalnızca true iken yazılır), `notes`
(`{tarih: metin}`, anahtar mutlaka `recs`'te olan bir gün — kayıt silinince/taşınınca
not da gider/taşınır), `remindAt` (gece yarısından dakika; yoksa genel saat). Hepsi
kullanıcının girdisi, türetilmiş değil; bozuksa kart atılmaz, alan yok sayılır.
Arşivli kart `store.cards`'ta yoktur (ızgara, zaman tüneli, gecikenler, profil, widget,
bildirim hepsi onu görmez); `archivedCards` ve `byId` görür. `recs` mutlak ISO tarihleri (`YYYY-MM-DD`), en
yeniden eskiye. **Türetilmiş hiçbir değer saklanmaz.** Profil (`name`, `handle`)
ayrı anahtarda (`nezaman.profile.v1`). Dil `nezaman.lang.v1` (yoksa telefonun dili). Kart düzeni (ızgara/liste) `nezaman.layout.v1`;
başlıktaki avatarın solundaki düğme değiştirir, seçim kalıcıdır. Kaydı olmayan kart asla geç sayılmaz.

Gün sayıları takvim günü sınırında hesaplanır (24 saat değil); `today` gece
yarısı `Timer`'ı ve `didChangeAppLifecycleState` ile tazelenir.

## Diller

Uygulama Türkçe ve İngilizce. Varsayılan **telefonun dili**; `Ayarlar → Dil`'den
`Telefonun dili / Türkçe / English` seçilebilir ve seçim kalıcıdır
(`nezaman.lang.v1`). İngilizce olmayan her cihaz dili Türkçe'ye düşer.

- **Ekranlara metin yazma.** Her metin `Strings`'te bir üye; `S.xxx` ile okunur.
  `S` de `AppColor` gibi genel bir getter'dır (bkz. tuzak 14): `const` ifadede
  kullanılamaz, varsayılan parametre değeri olamaz. Yeni metin eklerken soyut
  `Strings`'e ekle — analyzer iki dilde de doldurmaya zorlar.
- Dil değişimi `CardStore.setLang`: kaydeder, widget'ları ve bildirimleri
  yeniden kurar, bütün ağacı yeniden çizer (`_rebuildEverything`).
  Telefonun dili açıkken değişirse `didChangeLocales` aynısını yapar.
- **Kart adları çevrilmez.** Kullanıcının yazdığı addır; dil değişince olduğu gibi
  kalır. Bu yüzden ad üzerinden çalışan eşleştirmeler (simge tahmini, bildirim
  konusu, arama) iki dilin anahtarlarını da tek listede tutar ve `foldedForms`
  ile hem Türkçe hem düz küçük harfe bakar.
- Ana ekran widget'ları günü kendileri sayar, bu yüzden **metin şablonları
  anlık görüntüyle taşınır** (`S.widgetStrings`, `{n}` sayı yerine geçer).
  Kotlin `WidgetStrings`, Swift `WidgetStrings`; ikisinin de yedeği Türkçe.
  Yeni anahtar eklersen üç yeri birden güncelle.
- Android'in kendi çizdiği yüzeyler (widget seçici, "Hangi kart?" ekranı)
  `res/values` + `res/values-en` ile **telefonun dilini** izler; uygulama içi
  seçim oraya ulaşmaz.
- iOS widget galerisindeki başlık/açıklama (`configurationDisplayName`,
  `.description`, `CardIntent`) hâlâ Türkçe sabit: `LocalizedStringResource`
  bir string catalog ister, o da Xcode'da hedefe eklenmeli.
- Hukuki metinler `store/legal/content.py`'den iki dilde üretilir; yalnız Dart
  dosyasını yenilemek için `python store/legal/build.py --dart`.

## Metinler

Türkçe metinler tasarımın özgün hali; `l10n/strings_tr.dart`'ta durur.
Değiştirmen istenmediyse aynı kalsın (İngilizce karşılığı da aynı tonu izler):

- Başlık `Kaç gün oldu?` — altında açıklama satırı **yok**
- Rozet yalnızca gecikme varsa: `{n} kart gecikti`; gecikme yoksa hiçbir rozet
  gösterilmez (`her şey yerinde` yazısı yok)
- Kartta geç etiketi **yok** — gecikme başlıktaki `{n} kart gecikti` düğmesiyle
  anlatılır. **Kartta tek sayı var:** gün sayısı, yanında `gün oldu` rakamın
  zemininde (3 hanede de yan yana, sayı her kartta aynı boyda: 52pt). Kayıt
  yoksa `—` · `kayıt yok`. Altında tek durum satırı (`CardStatus`): `{n} gün
  kaldı` · `Bugün sırası` · `{n} gün geçti` · `Ritim öğreniliyor` · `Henüz
  işaretlenmedi`. Halka kartta yazısız; simgeyi çevreleyen ilerleme işaretidir.
  Tarih (`meta`) kartta gösterilmez — detayda var. Liste satırında sayı sağda,
  sabit genişlikli sütunda sağa hizalı, altında `gün oldu`. Halkanın yazılı hâli
  (`{n} gün kaldı` · `+{n} gün geçti`) yalnızca detay ve durum renkleri ekranında
- Meta satırı `{tarih} ~{n} günde bir` — **ayırıcı nokta yok**, tek satır.
  `günde` ile `bir` arasındaki boşluk bölünmez boşluktur (U+00A0); testler
  bunu doğruluyor, düz boşlukla değiştirme.
- Kayıt sayfası `Ne zaman yaptın?` · `Daha geriden seç` (`upperTr` ile büyütülür)
  · `Takvimden seç` (· yeni kartta `Henüz yapmadım`)
- Yeni kart sayfası `Ne yaptın?` · `Ne zaman yaptın?` · `Ne sıklıkla
  tekrarlıyorsun?` · `Gelişmiş seçenekler` · `Kartı oluştur`
- Kart detayı `gün oldu` · `Son kayıt` / `Ortalama` · `Bugün yaptım` ·
  `Başka bir gün seç` · `Geçmiş`
- Gecikenler `{n} kartın zamanı geçti` · `Hemen kontrol et, tekrarını planla.`
- Bildirim: başlık = kart adı. Gövde `reminder_copy.dart`'taki şablonlardan: konu
  kart adındaki kelime köklerinden bulunur (sağlık/ilaç önce, şakasız), vadede
  ve gecikmede ayrı cümle; seçim kart+gün tohumuyla sabittir (yeniden planlama
  metni değiştirmez). Seçilmiş sıklıkta sona ` Hedefin haftada bir.` eklenir. Form:
  `Bana hatırlat`. Ayarlar: `Hatırlatma saati` · `Test bildirimi gönder`
- Boş durum `Hayatındaki küçük şeyleri takip etmeye başla.` · `İlk kartını oluştur`
- Silme onayı `"{ad}" silinsin mi?` · `Vazgeç` / `Sil`
- `Kartlar` · `Zaman tüneli` · `Yeni kart` · `Geri al` · `Kartı sil`

## Tuzaklar (hepsi bir kez canımızı yaktı)

1. **`DayCount`'ta `TextHeightBehavior` kullanma.** `applyHeightToFirstAscent/
   LastDescent` kapatılınca Flutter `height: 0.86`'yı tümden yok sayıp font
   metriklerine düşer; 58pt sayı 100pt yer kaplar, kart 168 yerine 414 olur.
2. **Sayı asla alt satıra kaymamalı.** `214` → `2`/`1`/`4` diye bölünmüştü. Sayı +
   `gün` grubu `FittedBox(scaleDown)` içinde, `maxLines: 1, softWrap: false`.
3. **Sayfa kabuğunun `Material` atası olmalı.** `TextField` bunu ister; olmadan
   yeni kart sayfası açılışta çöker (`app_sheet.dart`).
4. **Material'ın `Card`'ı bizim `Card`'ımızla çakışır** →
   `import 'package:flutter/material.dart' hide Card;`
5. **Widget testlerinde ekran boyutunu ayarla** (`tester.view.physicalSize`);
   varsayılan 800x600'de iki sütunlu telefon düzeni taşar.
6. **Widget testlerinde `CardStore`'u test gövdesi İÇİNDE `dispose` et.** Gece
   yarısı zamanlayıcısı açık kalırsa test düşer ve `addTearDown` bu kontrolden
   sonra çalışır — `home_screen_test.dart`'taki `runHome` yardımcısını kullan.
7. **`dow` dizisi Pazar başlangıçlı**, Dart'ın `weekday` alanı Pazartesi=1. Doğru
   indeksleme: `dow[d.weekday % 7]`.
8. **Uzun basış sürüklemeye ayrılmış** (350ms), o yüzden karta dokunmak detay
   sayfasını açar; silme detaydaki `⋯` menüsünde. Bu ikisini karıştırma.
9. **Manuel sıra bir kez kaydedilince kalıcıdır.** Kayıtlı listede olmayan kart
   (yeni oluşturulmuş) en öne düşer — `applyOrder`.
10. **Izgara `Wrap` değil, satır satır kurulur** (`draggable_card_grid.dart`):
    her satır `IntrinsicHeight(Row(stretch, [Expanded(kart), Expanded(kart)]))`.
    Böylece aynı satırdaki iki kart eşit yükseklikte olur ve sayılar/durum
    satırları başlık uzunluğundan bağımsız aynı hizaya oturur; `CardTile`'ın
    `spaceBetween` sütunu da ancak böyle sınırlı yükseklik alır (yoksa sayı alt
    kenara değil içeriğin altına yapışır). `Wrap`'e geri dönme.
    `card_tile_test.dart`'taki `pumpTile` aynı sarmalamayı kullanır ve **gerçek
    fontları yükler** (test fontu her harfi 1em kare çizer; sığma/hiza ölçümleri
    anlamsız olur). `gün oldu`'nun zemine oturması baseline Row ile değil ölçülü
    dolguyla yapılır (baseline Row'un yüksekliği `IntrinsicHeight`'a yanlış
    raporlanıyordu); bunun için birimin `height`'ı açıkça verilmeli, yoksa
    Material'ın 1.43'ünü devralır ve ölçüm kayar.
11. **Açılış animasyonu native: `SplashActivity` → `MainActivity`.** Flutter'da ya da
    `MainActivity`'de çizilen animasyon görünmez: `FlutterActivity` motoru yüklerken ana
    iş parçacığını kilitler (release ~1,4 sn, debug ~5 sn). Akış: launcher girişi hafif
    `SplashActivity` (`SplashTheme`, **şeffaf** → Android kendi açılış ekranını hiç
    göstermez; MIUI karanlık modda onu karartıyordu = "önce tek renk") ilk çizimde
    `avd_splash_mark`'ı oynatır (render iş parçacığı), sonra `MainActivity`'yi başlatır;
    `MainActivity` aynı yerde bitmiş logoyu (`ic_splash_mark`) tutar, Dart `appReady()`
    deyince animasyon süresi + bekleme dolunca solar (`LaunchScreen.remainingMs`, telefonun
    animatör ölçeğini hesaba katar — Geliştirici seçenekleri 0,5× yapabilir). Görünüm her iki
    aktivitede **decor view'a** eklenir (içerik alanına değil), yoksa devirde zıplar.
    **Intent'i bayraklarıyla kopyalama:** launcher intent'i `FLAG_ACTIVITY_NEW_TASK` taşır;
    kopyalanınca `MainActivity` ikinci görevde açılıyordu (Son uygulamalar'da iki kayıt +
    "kesilip yeniden açılma"). Yalnızca eylem/veri/ekler + `CLEAR_TOP|SINGLE_TOP`.
    **`taskAffinity=""` koyma:** kapalıyken bildirimle açılış mevcut görevi bulamayıp yeni
    görev açıyordu. Çubuklar: `LaunchScreen.prepareWindow` kenardan kenara + şeffaf;
    `NormalTheme`'de (FlutterActivity açılış ortasında buna geçer) `windowDrawsSystemBarBackgrounds`
    şart, `Theme.Light` çubuk arka planı çizmez. Şekil ikonla birebir: `ic_splash_mark.xml`
    **üretilir** (`python assets/icon/gen_splash.py`, `fonttools`). Renk: `Palette.launchColor`
    = `colors.xml` `launch_<tema>` (`palette_test.dart` uyuşmayı doğrular); açık/krem renk
    seçme. Doğrulama: `adb shell screenrecord` + kare kare bak (soğuk açılış, arkadan dönüş,
    açıkken ve kapalıyken bildirim; `dumpsys activity recents` tek kayıt göstermeli).
12. **`dart format`'ı tüm ağaçta çalıştırma.** Kod 80 sütuna göre biçimli değil;
    `dart format lib test` alakasız onlarca dosyayı yeniden biçimler. Sadece
    kendi yazdığın yeni dosyayı biçimle.
13. **Yalnızca konumlandırılmış çocuk içeren `Stack`'e `fit: StackFit.expand`
    ver.** Yoksa sıfır boyuta düşer ve dokunuşları almaz (boş durum ekranı).

14. **`AppColor` sabit değil, seçili temadan okunan getter.** `const` bir ifadenin
    içinde kullanılamaz (`const BoxDecoration(color: AppColor.primary)` derlenmez)
    ve varsayılan parametre değeri olamaz. Yeni renk rolü gerekiyorsa `Palette`'e
    ekle; ekranlara sabit `Color(0x…)` yazma, yoksa temalarla değişmez. Tema
    değişimi `CardStore.setTheme` ile olur: kaydeder, çubukları günceller ve
    bütün ağacı yeniden kurar. Rengi elde tutan `CustomPainter`'ın
    `shouldRepaint`'i tema değişimini de görmeli (`_PlantPainter`'daki `themeId`).
    Kiremit = tasarımın kendi değerleri; `palette_test.dart` bunu ve her temanın
    kontrastını doğrular.

15. **Bildirimler türetilir, saklanmaz.** Kalıcı olan yalnızca kartın `notify`
    bayrağı ve saat (`nezaman.remindertime.v1`, varsayılan 09:00). Bekleyen
    bütün bildirimler `planReminders`'tan çıkar; her kart değişiminde, gece
    yarısında ve açılışta `cancelAll` + yeniden planlanır (`CardStore._syncReminders`,
    sıraya dizilir). Bildirim gövdesindeki gün sayıları planlama anında
    *bildirimin çıkacağı güne* göre hesaplanır. Ritmi olmayan (3 kayıttan az,
    sıklık seçilmemiş) kart planlanmaz. İzin ilk açışta istenir, uygulama
    açılışında değil. Zamanlama `inexactAllowWhileIdle`: özel alarm izni gerekmez.
    Testlerde `CardStore` varsayılan olarak `NoopReminders` kullanır; gerçek
    servis yalnızca `main.dart`'ta bağlanır — `CardStore(reminders: …)`.
    Android tarafı `AndroidManifest.xml` (izinler + alıcılar), `build.gradle.kts`
    (desugaring) ve `ic_notification.xml`'e bağlı; bunlara dokunduysan
    `flutter build apk --debug` çalıştır.

16. **`MaterialApp` her build'de `SystemUiOverlayStyle.dark` uygular — gezinme çubuğu SİYAH.**
    Açılışta ilk karede ve her tema değişiminde çubuğumuzu eziyordu. Kalıcı çözüm kökteki
    `SystemBarsRegion` (`AnnotatedRegion`): çerçeve her karede ondan sonra uygulanır.
    Çubuk rengini başka yerden kalıcı ayarlamaya çalışma; `systemBarsStyle()`'ı değiştir.
    `system_bars_test.dart` bunu (ve bölgesiz hâlin siyah olduğunu) doğrular.
17. **Sürüm (R8) derlemesi adla aranan kaynakları siler.** `ic_notification` silinince
    bildirimler sürümde SESSİZCE hiç görünmüyordu (debug'da her şey çalışır). Adla aranan her
    kaynak `res/raw/keep.xml`'de olmalı. Kontrol: `aapt2 dump resources app-release.apk`.

18. **Ana ekran widget'ları günü kendileri sayar.** Dart (`widgetSnapshot`) yalnızca kartın
    son kaydını ve aralığını (`every` ya da öğrenilmiş medyan — bugüne bağlı değil) + tema
    renklerini yazar; gün/kademe/durum satırı Kotlin (`widget/WidgetSnapshot.kt`) ve Swift
    (`KacGunOlduWidget/WidgetSnapshot.swift`) içinde `statsFor`/`CardStatus`'un kopyasıyla
    hesaplanır. **`logic.dart`'taki kuralları değiştirirsen ikisini de değiştir.** Yayın her
    `_commit`, açılış ve tema değişiminde (`CardStore._syncWidgets`). Android: kanal →
    `SharedPreferences` → `refreshAll`; gece yarısı uyandırmayan alarm. iOS: kanal → App Group
    `group.com.emalabs.kacgunoldu` → `reloadAllTimelines`; zaman çizelgesi her gece yarısına giriş
    koyar. Dokunuş `kacgunoldu://app/card/<id>` açar; Flutter'ın derin bağlantısı
    `CardStore.didPushRouteInformation`'a (sıcak) ya da `defaultRouteName`'e (soğuk) getirir,
    kart detayı `openCardRequest` ile açılır. Bu yüzden `MaterialApp` `home` yerine
    `onGenerateInitialRoutes` kullanır — bağlantı rota sanılmasın. Simgeler adla aranır:
    `wg_*` `keep.xml`'de (tuzak 17); katalog değişince `python tool/gen_widget_glyphs.py`
    (`home_widgets_test.dart` eksik kopyayı yakalar). iOS imzası App Group ister
    (`store/README.md`).
    **"Bugün yaptım" widget'ta kayıt yazmaz, işaret bırakır:** widget anlık görüntüdeki
    `last`'ı bugüne çeker (hemen yeniden çizilir) ve `marks` listesine ekler; uygulama
    açılışta (ilk yayından ÖNCE) ve öne gelişte `takeMarks` ile alıp gerçek kayda çevirir
    (`CardStore._takeWidgetMarks`; aynı gün/silinmiş kart atlanır). Düğme Ayarlar'dan
    kapatılabilir (`nezaman.widgetdone.v1`, anlık görüntüde `doneButton`). Android'de
    "Ana ekrana ekle" `requestPinAppWidget` ile; seçilen kart geri çağrıda (`ACTION_PINNED`)
    widget'a yazılır. Kart widget'ı eklenirken kart seçme ekranı her sürümde açılır.

## Yayın

Adımlar ve mağaza materyalleri `store/README.md`'de. İmza: `tool/create_upload_key.ps1` →
`android/key.properties` (+ `.jks`, ikisi de git dışı); yoksa release debug anahtarıyla
imzalanır (Play reddeder), Gradle uyarı basar. Paket: `flutter build appbundle --release`.

**Hukuki metinler tek kaynaktan gelir:** `store/legal/content.py` (TR+EN gizlilik, koşullar,
destek). `python store/legal/build.py` → uygulama içi `lib/legal/legal_text.dart` (elle
düzenleme!) + gezip.app'in `public/kacgunoldu/*` sayfaları. Metni değiştirince uygulamanın
gerçek davranışıyla (izinler, veri, bildirim) tutarlı kalsın; sürümde `appVersion` ile
pubspec'i birlikte artır. iOS derlemesi `codemagic.yaml` ile (`v*` etiketi → TestFlight),
kurulum adımları `store/README.md`'de.

## Geçmiş

Proje önce React Native/Expo ile yazıldı, sonra Flutter'a aktarıldı. RN sürümü
`25734ff` commit'inde duruyor; çalışma ağacında yok.
