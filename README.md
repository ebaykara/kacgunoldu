# Ne Zaman? — Flutter

*En son ne zaman?* — tek soruya cevap veren mobil uygulama: **bunu en son ne zaman yaptım?**

Uygulama `Ne Zaman v2.dc.html` hifi tasarımından birebir kodlanmıştır: aynı renkler,
aynı ölçüler, aynı hareket süreleri, aynı Türkçe metinler.

Proje önce React Native/Expo ile yazıldı, sonra Flutter/Dart'a aktarıldı. React
Native sürümü artık çalışma ağacında değil; `25734ff` commit'inde duruyor ve
gerekirse oradan çıkarılabilir:

```bash
git show 25734ff --stat
```

## Çalıştırma

```bash
flutter pub get
```

```bash
flutter run
```

Telefon USB ile bağlıysa doğrudan ona kurar. Tarayıcıda denemek için:

```bash
flutter run -d chrome
```

Analiz ve testler:

```bash
flutter analyze
```

```bash
flutter test
```

**64 test**, `flutter analyze` temiz, `flutter build apk --debug` başarılı.

## Mimari

```
lib/
  main.dart                 tema, sistem çubukları, yazı boyutu sınırı
  theme/
    tokens.dart             renk, boşluk, yarıçap, gölge, hareket — handoff'tan birebir
    typography.dart         Instrument Serif (display) + Archivo (UI)
  domain/
    card.dart               Card / Tier / AppTab modelleri + JSON doğrulaması
    date.dart               yerel takvim günü aritmetiği, Türkçe tarih biçimleri
    logic.dart              tipik aralık, ratio, gecikme, kademe, halka, meta satırı
    text.dart               Türkçe büyük harf kuralları (i → İ, ı → I)
    order.dart              otomatik aciliyet sırası + kalıcı sürükleme sırası
  storage/
    seed.dart               ilk açılış içeriği (mock'taki dokuz kart)
    repository.dart         shared_preferences kalıcılığı
  state/
    card_store.dart         ChangeNotifier: kayıt, geri alma, silme, sıralama, gece yarısı
  widgets/                  card_tile, rhythm_ring, halo, day_count, app_sheet,
                            record_sheet, create_sheet, draggable_card_grid,
                            bottom_tab_bar, header, fab, app_snackbar, timeline,
                            empty_state, icons, confirm_destructive
  screens/
    home_screen.dart        tüm ekranı birleştirir
```

**Hiçbir türetilmiş değer saklanmaz.** Kalıcı olan tek şey `{ id, name, recs }`;
`recs` mutlak ISO tarihleridir (`YYYY-MM-DD`), en yeniden eskiye sıralı.

## Türetilen mantık

| Değer | Kural |
| --- | --- |
| `days` | `recs[0]` ile bugün arasındaki tam takvim günü |
| `typical` | `median(gaps)` — **iki boşluktan azsa `null`** (yani üç kayıttan az) |
| `ratio` | `days / typical`, `typical` yoksa `min(0.95, days / 30)` |
| `isLate` | `typical != null && days > typical * 1.25 + 1` |
| kademe | `late` → `soon` (`ratio > 0.95`) → `fresh` (`ratio < 0.5`) → `calm` |
| `remaining` | `typical - days` — halkadaki `4 gün` / `bugün` / `+8 gün` |

`+1` payı, kısa aralıklı kartların (üç günde bir sulanan bitkiler) tek günlük
gecikmede "geç" damgası yemesini engeller.

### Takvim günü, 24 saat değil

Gün sayıları cihazın yerel saat diliminde **takvim günü** sınırlarında hesaplanır.
`today`, gece yarısı bir `Timer` ile ve uygulama öne geldiğinde
(`didChangeAppLifecycleState`) yeniden okunur. Her iki uç da yerel gece yarısına
normalize edildiği için yaz saati geçişleri sonucu bozmaz.

## React Native sürümünden farklar

Davranış ve görünüm aynı; altyapı Flutter'ın kendi araçlarına taşındı:

| Konu | React Native | Flutter |
| --- | --- | --- |
| Kalıcılık | `AsyncStorage` | `shared_preferences` |
| Durum | `useState` + custom hook | `ChangeNotifier` (`CardStore`) |
| Ritim halkası | `react-native-svg` yay | `CustomPainter` yay |
| İkonlar | inline SVG | `CustomPainter` |
| Bottom sheet | özel `Animated` + `PanResponder` | `PopupRoute` + dikey sürükleme |
| Sürükle-bırak | `react-native-draggable-flatlist` | `LongPressDraggable` + `DragTarget` (kendi kodumuz) |
| Silme onayı | `Alert.alert` / `window.confirm` | `CupertinoAlertDialog` (iOS) / `AlertDialog` |
| Blur | `expo-blur` | `BackdropFilter` |
| Yazı boyutu sınırı | `maxFontSizeMultiplier` | `MediaQuery.withClampedTextScaling` |

Sürükle-bırak için harici paket yerine kendi uygulamamız var: ızgara iki sabit
sütun ve tek tip bir widget, üstelik böylece sürükleme jesti kartın zaten sahip
olduğu dokunma ve uzun basma jestleriyle çakışmıyor. Kayıt bırakıldığı anda tam
id dizisi `shared_preferences`'a yazılır.

## Aktarım sırasında yakalanan ve düzeltilen üç hata

Testler, RN sürümünde fark edilmemiş üç sorunu ortaya çıkardı:

1. **Yeni kart sayfası açılışta çöküyordu.** `TextField` bir `Material` atası
   ister; sayfa kabuğu sade `Container`'lardan oluşuyordu. Kabuk artık gerçek
   bir `Material` (`app_sheet.dart`).
2. **Gün sayısı satır kutusu iki katına çıkıyordu.** `TextHeightBehavior` ile
   `applyHeightToFirstAscent/LastDescent` kapatılınca Flutter `height: 0.86`'yı
   tümden yok sayıp font metriklerine düşüyordu; 58pt sayı 100pt yer kaplıyor,
   kart 168 yerine 414 piksel oluyordu.
3. **Üç haneli sayı rakam rakam alt satıra kayıyordu** (`214` → `2`/`1`/`4`).
   Sayı + `gün` grubu artık tek satırda ve sığmazsa orantılı küçülüyor.

## Erişilebilirlik

- Her kart tek bir düğmedir: `"{ad}, {n} gün önce, geç. her zamanki aralığı 8 gün aştı"`,
  ipucu `"işaretlemek için dokun, yer değiştirmek için basılı tutup sürükle"`.
- Gecikme yalnızca renkle anlatılmaz — `8 gün geç` etiketi nedeni yazar, halkadaki
  `+8 gün` aynı sayıyı taşır.
- Dokunma hedefleri ≥ 44pt (gün hücreleri yüksekliğe kadar doldurulur).
- Sistem yazı boyutu desteklenir, 1.3x'te sınırlanır.
- **Reduce motion** açıkken hale, sayaç ve sayfa animasyonları atlanır.
- Snackbar `liveRegion` ile duyurulur.

## Test kapsamı

- `test/domain/` — medyan/gecikme kuralı, kademe eşikleri, halka etiketi, meta
  satırı, takvim günü aritmetiği, gece yarısı devri, hafta günü eşlemesi,
  Türkçe büyük harf kuralları, sıralama mantığı.
- `test/storage/` — kart ve sıra kalıcılığı, bozuk veriden kurtarma.
- `test/widgets/` — kart düzeni ve yüksekliği, geç etiketi, **sürükle-bırak
  yeniden sıralama** (uzun bas → sürükle → bırak).
- `test/screens/` — kart açma, tarih seçme, geri alma, onaylı silme, kart
  oluşturma (iki buton), gecikenler filtresi, zaman tüneli, sıranın yeniden
  açılışta korunması.

## Fontlar

`Instrument Serif` ve `Archivo` `assets/fonts/` altında **paketlenir**, çalışma
anında indirilmez — seri/sans karşıtlığı ürünün karakterini taşıdığı için sistem
fontuyla bir kare bile gösterilmez.
