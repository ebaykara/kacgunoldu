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
flutter test      # 141 test, hepsi geçmeli
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
  main.dart                 tema, sistem çubukları, yazı boyutu sınırı (1.3x)
  theme/tokens.dart         Palette + palettes (6 tema) · AppColor · Space · Radii
                            · Elevation · Motion · Layout
  theme/system_bars.dart    çubuk stili + SystemBarsRegion (kökte; bkz. tuzak 16)
  theme/typography.dart     ui() · display() · overline()
  domain/card.dart          Card (+ isteğe bağlı icon/every/created) · Tier · AppTab
  domain/date.dart          DateKey aritmetiği, Türkçe tarih biçimleri
  domain/logic.dart         tiers · typicalInterval · statsFor · decorate · orderCards
                            · averageGap
  domain/order.dart         applyOrder — otomatik sıra vs kalıcı sürükleme sırası
  domain/text.dart          capitalizeTr · upperTr · lowerTr · initialsOf
  domain/frequency.dart     "Ne sıklıkla" çipleri (Her gün … Yılda bir)
  domain/icon_guess.dart    addan simge tahmini (diş → tooth, spor → gym …)
  domain/insights.dart      profil sayıları: toplamlar, aylık, en düzenli, en ihmal
  domain/reminders.dart     planReminders: hangi bildirim ne zaman, metinler (saf)
  services/reminders.dart   Reminders arayüzü · LocalReminders (OS) · NoopReminders
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
  screens/settings_screen.dart      Ayarlar: sıralama, örnekler, yedek, silme, Hakkında
  screens/legal_screen.dart         Gizlilik politikası / Kullanım koşulları (legal_text.dart'tan)
  legal/                            legal_model · legal_text (ÜRETİLİR) · font_licenses (OFL)
  app_info.dart                     appVersion (pubspec ile aynı; test kontrol eder)
  screens/legend_screen.dart        Durum renkleri
  screens/theme_screen.dart         Tema seçici (canlı önizlemeli)
  services/launch_theme.dart        açılış animasyonuna 'hazırım' + splash teması (kanal)
  widgets/                  card_tile (+ DayCountLine) · card_row_tile (liste) · card_status · rhythm_ring · halo · day_count · card_glyph
                            app_sheet · record_sheet · draggable_card_grid
                            header (+ Avatar) · fab · bottom_tab_bar · app_snackbar
                            store_snack · timeline · empty_state · icons · ui
                            confirm_destructive
test/  domain · storage · state · theme · widgets · screens
store/  mağaza metinleri, gizlilik politikası, Play form cevapları, görseller (README)
tool/create_upload_key.ps1   yükleme anahtarı + android/key.properties (git dışı)
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
(gün), `created`, `notify` (yalnızca true iken yazılır). Üçü de kullanıcının girdisi, türetilmiş değil; bozuksa kart
atılmaz, alan yok sayılır. `recs` mutlak ISO tarihleri (`YYYY-MM-DD`), en
yeniden eskiye. **Türetilmiş hiçbir değer saklanmaz.** Profil (`name`, `handle`)
ayrı anahtarda (`nezaman.profile.v1`). Kart düzeni (ızgara/liste) `nezaman.layout.v1`;
başlıktaki avatarın solundaki düğme değiştirir, seçim kalıcıdır. Kaydı olmayan kart asla geç sayılmaz.

Gün sayıları takvim günü sınırında hesaplanır (24 saat değil); `today` gece
yarısı `Timer`'ı ve `didChangeAppLifecycleState` ile tazelenir.

## Metinler

Türkçe ve kesin. Değiştirmen istenmediyse aynen kalsın:

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
- Bildirim: başlık = kart adı. Vadesinde `{n} gündür yapmadın, sırası geldi.
  Genelde {t} günde bir yapıyorsun.` (seçilmiş sıklıkta `Hedefin haftada bir.`),
  2 gün sonra `{n} gün oldu, 2 gün geçti. Yaptıysan dokun, işaretle.` Form:
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
