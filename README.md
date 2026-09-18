# Ne Zaman?

*En son ne zaman?* — tek soruya cevap veren bir mobil uygulama: **bunu en son ne zaman yaptım?**

Takip etmek istediğin her şey için bir kart açarsın. Her yaptığında karta dokunur,
tarihi seçersin; kart sıfırlanır ve yeniden gün saymaya başlar. Uygulama her kartın
**tipik aralığını** (kayıtlar arasındaki boşlukların medyanı) öğrenir, kartı ona göre
renklendirir ve geciktiğinde işaretler. Seri yok, hedef yok, puan yok.

`design_handoff_ne_zaman/` paketindeki **`Ne Zaman v2.dc.html`** kanonik tasarımının
birebir uygulamasıdır.

## Çalıştırma

```bash
npm install
```

```bash
npx expo start
```

Ardından iOS için `i`, Android için `a`, tarayıcı için `w`. Doğrudan:

```bash
npm run ios
```

```bash
npm run android
```

```bash
npm run web
```

Tip kontrolü ve testler:

```bash
npx tsc --noEmit
```

```bash
npm test
```

Testler `src/domain/__tests__/` ve `src/storage/__tests__/` içinde: medyan/gecikme
kuralı, kademe eşikleri, meta satırının tutarlılığı, kayıtsız kart durumu, gece
yarısı devri, Türkçe büyütme kuralı, kalıcı sürükle-bırak sıralaması (`applyOrder`)
ve `AsyncStorage` üzerinden manuel sıra kalıcılığı — 34 test.

`app.json` değiştirdiysen Metro'nun önbelleğini temizleyerek başlat — yoksa
uygulama boş ekranda kalabilir:

```bash
npx expo start --clear
```

## Neden Expo / React Native

Handoff "hazır bir kod tabanı yoksa bu tür bir mobil uygulama için en uygun
framework'ü seç" diyor. Expo + TypeScript seçildi: tek koddan iOS + Android
(+ doğrulama için web), yerel bir Material 3 / HIG eşlemesi ve ekstra SDK kurulumu
gerektirmeyen bir geliştirme akışı.

## Mimari

```
App.tsx                     fontlar + splash + SafeAreaProvider
src/
  theme/
    tokens.ts               renk, boşluk, yarıçap, gölge, hareket — handoff'tan birebir
    typography.ts           Instrument Serif (display) + Archivo (UI) yardımcıları
  domain/
    date.ts                 yerel takvim günü aritmetiği, Türkçe tarih biçimleri
    logic.ts                tipik aralık, ratio, gecikme, kademe, meta satırı
    types.ts                Card / Tier / Filter / Tab
  storage/
    repository.ts           AsyncStorage kalıcılığı (şema doğrulamalı)
    seed.ts                 ilk açılış içeriği (mock'taki dokuz kart)
  state/
    useCardStore.ts         kartlar, kayıt, geri alma, snackbar, gece yarısı yenileme
  components/               CardTile, RhythmRing, Halo, DayCount, Sheet,
                            RecordSheet, CreateSheet, TabBar, Fab, Snackbar,
                            Timeline, FilterChips, Header, EmptyState, icons
  screens/
    HomeScreen.tsx          tüm ekranı birleştirir
```

**Hiçbir türetilmiş değer saklanmaz.** Kalıcı olan tek şey `{ id, name, recs }`;
`recs` mutlak ISO tarihleridir (`YYYY-MM-DD`), en yeniden eskiye sıralı.

## Türetilen mantık

| Değer | Kural |
| --- | --- |
| `days` | `recs[0]` ile bugün arasındaki tam takvim günü |
| `gaps[i]` | `offsets[i+1] - offsets[i]` |
| `typical` | `median(gaps)` — **iki boşluktan azsa `null`** (yani üç kayıttan az) |
| `ratio` | `days / typical`, `typical` yoksa `min(0.95, days / 30)` |
| `overdue` | `typical !== null && days > typical * 1.25 + 1` |
| kademe | `late` → `soon` (`ratio > 0.95`) → `fresh` (`ratio < 0.5`) → `calm` |
| halka % | `clamp(3, round(ratio * 100), 100)` |

`+1` payı, kısa aralıklı kartların (üç günde bir sulanan bitkiler) tek günlük
gecikmede "geç" damgası yemesini engeller. `typical`'ın iki boşluk şartı da yeni
bir kartın asla gecikmiş sayılmamasını garanti eder.

### Takvim günü, 24 saat değil

Gün sayıları cihazın yerel saat diliminde **takvim günü** sınırlarında hesaplanır.
`today` gece yarısı bir zamanlayıcıyla ve uygulama öne geldiğinde yeniden okunur,
böylece kart dokunmadan 24 saat sonra değil, gece yarısı devreder. Her iki taraf da
yerel gece yarısına normalize edildiği için yaz saati geçişleri sonucu bozmaz.

## Tasarım eşlemesi

| Tasarım öğesi | Material 3 | Apple HIG | Bu kod |
| --- | --- | --- | --- |
| Başlık | Large top app bar | Large title | `Header` (sabit, kaymaz) |
| Kart | Tonal card + state layer | Grouped card, 26pt | `CardTile` |
| Yeni kart | Extended FAB | Prominent button | `Fab` |
| Tarih seçici | Modal bottom sheet | Sheet + grabber | `Sheet` + `RecordSheet` |
| Kaydedildi · Geri al | Snackbar + action | Toast + Undo | `Snackbar` |
| Kartlar / Zaman tüneli | Navigation bar | Tab bar | `TabBar` |

- **Ritim halkası** mock'ta bir conic gradient; burada `react-native-svg` ile
  kırpılmış yay olarak çizilir, 12 yönünden saat yönünde, 500ms'de dolar.
- **Gölgeler** CSS `box-shadow` dizeleri olarak birebir taşınır (negatif spread
  dahil), yaklaşık bir iOS gölge üçlüsüne indirgenmez.
- **Sayaç animasyonu** 620ms, `1-(1-p)³`, her karede yuvarlanır ve yalnızca ilgili
  kartın içinde yaşar — kayıt sırasında ızgara yeniden render edilmez.
- **Izgara yeniden sıralaması** `react-native-draggable-flatlist` ile
  sürüklenir (numColumns=2); bırakılan düzen `AsyncStorage`'a kalıcı olarak
  kaydedilir ve otomatik aciliyet sıralamasının yerini alır.

## Erişilebilirlik

- Her kart tek bir düğmedir: `"{ad}, {n} gün önce"` + halkanın tam açıklaması
  (`"her zamanki aralığı 8 gün aştı"`), ipucu draggable ızgarada
  `"işaretlemek için dokun, yer değiştirmek için basılı tutup sürükle"`.
- Gecikme yalnızca renkle anlatılmaz — kartın üstündeki `8 gün geç` etiketi
  nedeni doğrudan yazar, halkadaki `+8 gün` de aynı sayıyı taşır.
- Dokunma hedefleri ≥ 44pt: gün hücreleri yüksekliğe kadar doldurulur, çipler
  tasarımdaki 37pt görünümünü koruyup `hitSlop` ile hedefi büyütür.
- Dinamik tip `maxFontSizeMultiplier` ile sınırlanarak desteklenir (46pt seri rakam
  ızgarayı taşırmasın diye).
- **Reduce motion** açıkken hale ve sayaç animasyonu atlanır, yerine çapraz geçiş
  kullanılır; halka ve sayfa animasyonları anında tamamlanır.
- Snackbar `accessibilityLiveRegion="polite"` ile duyurulur.

## Tasarımdan ayrılan yerler

Handoff'un üstüne istenen ürün değişiklikleri:

1. **Başlıktaki alt metin kaldırıldı.** `En son ne zaman?` altındaki açıklama satırı
   yok; başlık bloğu tarih + geciken rozeti + başlıktan ibaret.
2. **Kart düzeni.** Kart adının hemen altında `~{n} günde bir` açıklaması tek satır
   (kelime kaymaz — bkz. madde 4), gün sayısı ise kartın altında ve daha büyük
   (46 → **58pt**). Ritim halkası sayının sağında kalır.
3. **Filtre çip sırası (`Tümü` / `Gecikenler` / `Taze`) tamamen kaldırıldı.**
   Tek kalan filtre başlıktaki rozet: dokununca gecikenleri gösterir, tekrar
   dokununca tam ızgaraya döner. `Taze` filtresi kaldırıldığı için `domain/types.ts`
   içindeki `Filter` türü de silindi.
4. **Meta satırı: tek satır, aradaki çizgi yok.** `{tarih} · ~{aralık} günde bir`
   yerine `{tarih} ~{aralık} günde bir` — orta nokta kaldırıldı, `günde` ve `bir`
   arası bölünmez boşlukla (` `) birleştirildi, `Text` `numberOfLines={1}`;
   native'de sıkışınca `adjustsFontSizeToFit` ile küçülür (web'de eşdeğeri
   olmadığı için orada kırpılır). Gecikme miktarı zaten halkada (`+8 gün`) ve artık
   ayrıca `geç` etiketinde (`8 gün geç`); burada tekrar etmek kafa karıştırıyordu.
5. **Halka etiketi anlamlı hale getirildi.** Eski `/36` ve `%367` yerine
   `4 gün` (kalan gün) · `bugün` · `+8 gün` (aşılan gün) · `yeni`. Ekran okuyucu
   için tam cümle: `"her zamanki aralığa 4 gün kaldı"` / `"...8 gün aştı"`.
6. **`geç` etiketi nedenini kendisi açıklar.** Salt `GEÇ` yerine `8 gün geç` —
   kartın üstündeki tek bakışta, ayrı bir cümleye ihtiyaç kalmadan.
7. **"{n} kart bekliyor" → "{n} kart gecikti" ve tıklanabilir.** Rozet bir düğme:
   dokununca sadece geciken kartları gösterir, tekrar dokununca tam ızgaraya
   döner. Geciken yokken düz bir durum etiketi olarak kalır.
8. **Kartlar tutulup sürüklenerek yeniden sıralanabilir, kalıcı olarak.**
   `react-native-draggable-flatlist` ile uzun basıp sürükleme; bırakılan tam id
   dizisi `AsyncStorage`'a yazılır (`src/storage/repository.ts`'teki
   `loadManualOrder`/`saveManualOrder`, `src/domain/order.ts`'teki `applyOrder`).
   Hiç sürüklenmemişse ızgara otomatik aciliyet sırasında kalır (geciken önce,
   sonra en yakın vadeli); ilk sürükleme anından itibaren bırakılan düzen kalıcı
   olarak kazanır. Yeni oluşturulan bir kart, henüz kayıtlı düzende yer almadığı
   için en öne düşer — bir kartın her zaman en üstte açılması davranışıyla aynı.
   Sürükleme sadece filtrelenmemiş ana ızgarada etkin; `Gecikenler` görünümü
   geçici bir alt küme olduğu için otomatik sıralamada kalır ve sürüklenemez.
9. **Silme, karttan kayıt sayfasına taşındı.** Kart artık uzun basınca sürüklenir
   (yeniden sıralama), o yüzden "basılı tut = sil" gestüsü kalktı. Silmek için
   karta dokunup açılan "Ne zaman yaptın?" sayfasının sağ üstündeki çöp kutusu
   ikonuna dokun — aynı onay diyaloğu (`Vazgeç` / `Sil`) oradan açılır.
10. **Kart adı Türkçe kurala göre büyütülür.** Öneri çipleri küçük harf kalır
   (`çamaşır yıkadım`) — alan hâlâ kendi cümlen gibi okunsun diye. Kaydedilen
   kart adının ilk harfi `src/domain/text.ts`'teki `capitalizeTr` ile
   büyütülür: `i` → `İ` (noktalı), `ı` büyütülünce noktasız `I` olur —
   `String.toUpperCase()` bunu yanlış yapardı.
11. **Yeni kart sayfası.** Öneri çipleri en sık unutulan on işe genişletildi. Butonlar:
    - `Ekle ve tarih seç` — kartı kayıtsız oluşturur ve hemen kayıt sayfasını açar.
    - `Bugün itibariyle ekle` — kartı bugünü işaretleyerek oluşturur.

    Kanonik prototipte iki buton da bugünü işaretliyordu (`recs: [offset === null ? 0 :
    offset]`), yani aynı sonucu veriyorlardı; yeni etiketler bunu gerçekten ayırıyor.
    Kayıtsız kart meşru bir durum: `yeni` halka etiketi ve `Henüz işaretlenmedi` meta
    satırıyla görünür ve asla gecikmiş sayılmaz.

Ayrıca iki veri kararı:

- **İlk açılış içeriği.** Mock'taki dokuz kart `src/storage/seed.ts` içinde, gerçek
  ilk açılış tarihine göre çözülür; böylece kademeler ve gecikmeler tasarımdaki gibi
  görünür. Uygulamanın boş başlaması isteniyorsa o dosyadaki `SEED` dizisini boşalt.
- **Aynı güne iki kayıt.** Veri modeli gün çözünürlüğünde olduğu için aynı gün
  tekrar işaretlemek tek kayıt sayılır; aksi halde 0 uzunluğunda bir boşluk medyanı
  bozardı. Kayıtlar sıralı eklenir, yani eski bir tarih seçmek gün sayısını değiştirmez.

## Fontlar

`Instrument Serif` ve `Archivo` `@expo-google-fonts/*` ile **paketlenir**, çalışma
anında indirilmez. Uygulama her ikisi de yüklenene kadar splash'i açık tutar; seri /
sans karşıtlığı ürünün karakterini taşıdığı için sistem fontuyla bir kare bile
gösterilmez.
