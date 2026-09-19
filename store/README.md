# Yayına hazırlık — Kaç Gün Oldu?

Bu klasör, uygulamayı Google Play'e (ve istenirse App Store'a) göndermek için
gereken her şeyi içerir. Kodla ilgili hazırlık tamam; aşağıdaki adımlar yalnızca
**senin yapabileceğin** işler (hesap, anahtar, yükleme).

| Dosya | Ne işe yarar |
| --- | --- |
| `aso_appstore.md` | **App Store** ASO metinleri (TR+EN): ad, alt başlık, anahtar kelimeler, tanıtım, açıklama, başlıklar |
| `listing_tr.md` / `listing_en.md` | Play Store sayfası: ad, kısa ve tam açıklama (karakter sınırları kontrol edildi) |
| `play_console_answers.md` | "Uygulama içeriği" formlarının hazır cevapları (veri güvenliği, derecelendirme, hedef kitle…) |
| `legal/content.py` · `legal/build.py` | Gizlilik politikası, kullanım koşulları, destek (TR + EN) — **tek kaynak**; uygulama içi ekranları ve gezip.app sayfalarını üretir |
| `privacy_policy.md` | Eski düz metin kopya (yalnızca okuma; güncel olan `legal/content.py`) |
| `graphics/icon-512.png` | Play uygulama simgesi (512×512) |
| `graphics/feature-graphic.png` | Tanıtım görseli (1024×500) |
| `screenshots/play/01–05.png` | Telefon ekran görüntüleri (1080×1920, 9:16) |
| `make_graphics.py` · `frame_screenshots.py` | Görselleri yeniden üreten betikler |

## Teknik durum (kontrol edildi)

- Paket adı `com.emalabs.kacgunoldu`, sürüm `1.0.0` (kod `1`), hedef SDK 36, min SDK 24
- İzinler yalnızca: bildirim, açılışta hatırlatmaları yeniden kurma, titreşim. **İnternet izni yok.**
- R8 küçültmesi açık; adla aranan kaynaklar (bildirim simgesi, tema renkleri) `res/raw/keep.xml`
  ile korunuyor — sürüm derlemesinde zamanlanmış bildirimin gerçekten geldiği cihazda doğrulandı.
- İlk açılış **boş** başlar (rehberli boş ekran); örnek kartlar yalnızca Ayarlar'dan eklenir.
- `flutter analyze` temiz, bütün testler geçiyor.

## Adım adım

### 1. Yükleme anahtarını oluştur (bir kez)

```powershell
powershell -ExecutionPolicy Bypass -File tool\create_upload_key.ps1
```

Şifreyi sen belirlersin. Anahtar `%USERPROFILE%\keys\kacgunoldu-upload.jks` konumuna, ayarı
`android\key.properties`'e yazılır (ikisi de git'e girmez). **İkisini de hemen güvenli bir yere
yedekle** — sonraki her güncelleme aynı anahtarla imzalanmak zorunda.

### 2. Yayın paketini derle

```bash
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`. Anahtar yoksa derleme uyarı verir ve
paketi debug anahtarıyla imzalar — Play bunu kabul etmez; 1. adımı atlama.

### 3. Gizlilik politikasını yayımla

1. Metni değiştirdiysen `legal/content.py`'yi düzenle, sonra `python store/legal/build.py`
   (gezip.app klasörüne 6 sayfa + simge yazar, `lib/legal/legal_text.dart`'ı yeniler).
2. gezip.app sitesini Firebase'e yayımla (`firebase deploy --only hosting`). Yayımlanan adresler:
   - Gizlilik: `https://gezip.app/kacgunoldu/gizlilik` · `/privacy`
   - Koşullar: `https://gezip.app/kacgunoldu/kullanim-kosullari` · `/terms`
   - Destek: `https://gezip.app/kacgunoldu/destek` · `/support`
3. Mağaza formlarına: Play → gizlilik URL'si; App Store Connect → **Privacy Policy URL**,
   **Support URL** (destek sayfası), Marketing URL boş bırakılabilir.

### 4. Play Console

1. [Play Console](https://play.google.com/console) geliştirici hesabı (tek seferlik 25 USD).
   Kişisel hesaplarda yeni uygulamalar için Google, üretime çıkmadan önce **en az 12 test
   kullanıcısıyla 14 gün kapalı test** ister — 5. adıma göre planla.
2. **Uygulama oluştur**: ad `Kaç Gün Oldu?`, varsayılan dil Türkçe, Uygulama, Ücretsiz.
3. **Mağaza sayfası**: metinleri `listing_tr.md`'den kopyala; `graphics/` ve `screenshots/play/`
   dosyalarını yükle. İstersen İngilizce çeviriyi `listing_en.md`'den ekle.
4. **Uygulama içeriği**: her formu `play_console_answers.md`'ye göre doldur; gizlilik politikası
   URL'sini gir.
5. **Play Uygulama İmzalama**: varsayılanı kabul et (Google uygulama imza anahtarını tutar, sen
   yükleme anahtarını).

### 5. Test ve yayın

1. **Test → Kapalı test** kanalı oluştur, `app-release.aab`'ı yükle, test kullanıcılarını ekle.
2. Testçilerle şunları dene: kart ekleme, "Bugün yaptım", hatırlatma açma (izin penceresi gelmeli),
   tema değiştirme, telefonu yeniden başlatınca hatırlatmanın hâlâ gelmesi.
3. Şart karşılanınca **Üretim**'e yükselt ve incelemeye gönder (genelde 1–7 gün).

### Sonraki güncellemeler

`pubspec.yaml`'da sürümü artır (`1.0.1+2` gibi — `+` sonrası her yüklemede büyümeli), sonra 2. adım.

## iOS (App Store) — Codemagic

Kod tarafı hazır (paket kimliği, ad, şifreleme beyanı `Info.plist`'te). `codemagic.yaml` iOS'u
derleyip TestFlight'a gönderir; Mac gerekmez. Apple Developer üyeliği (yıllık 99 USD) gerekir.

1. App Store Connect → Uygulamalar → **+** → Yeni uygulama: ad `Kaç Gün Oldu?`, dil Türkçe,
   paket kimliği `com.emalabs.kacgunoldu`, SKU serbest. Oluşan **Apple ID** (sayı) → `codemagic.yaml`
   içindeki `APP_STORE_APPLE_ID`.
2. Users and Access → Integrations → **App Store Connect API** → anahtar üret (rol: App Manager),
   `.p8` dosyasını indir (bir kez indirilir!). Codemagic → Teams → Integrations → App Store
   Connect → anahtarı ekle, adı `kacgunoldu_asc`.
3. Codemagic'e depoyu ekle, `codemagic.yaml`'ı seç. Sürüm etiketi at: `git tag v1.0.0 && git push --tags`
   → derleme başlar (ya da elle "Start new build").
4. Derleme bitince build TestFlight'ta görünür; App Store Connect'te sürüme bağla, ekran
   görüntülerini (6.7" ve 6.5") ve metinleri gir, **Review'a gönder**.
5. Uygulama Gizliliği: **Veri Toplanmıyor** (Data Not Collected). Yaş derecelendirmesi
   `play_console_answers.md` sonundaki cevaplara göre. Lisans sözleşmesi: Apple'ın standart
   EULA'sı (uygulama içi koşullar buna ek).
6. Şifreleme sorusu çıkmaz (`ITSAppUsesNonExemptEncryption=false`).

### Widget'lar için bir kez (App Group)

Ana ekran widget'ları (`ios/KacGunOlduWidget`, iOS 17+) ayrı bir uzantıdır ve kart verisini
uygulamayla bir **App Group** üzerinden paylaşır. Bu yapılmadan iOS derlemesi imzalamada düşer.
[developer.apple.com](https://developer.apple.com/account/resources) → Certificates, IDs & Profiles:

1. Identifiers → **+** → App Groups → `group.com.emalabs.kacgunoldu`.
2. Identifiers → `com.emalabs.kacgunoldu` → **App Groups** kutusunu işaretle → Configure → bu
   grubu seç → Save.
3. Identifiers → **+** → App IDs → App → paket kimliği `com.emalabs.kacgunoldu.KacGunOlduWidget`,
   açıklama `Kac Gun Oldu Widget` → **App Groups** işaretle, aynı grubu seç → Register.
4. Profiles: `com.emalabs.kacgunoldu` için daha önce oluşmuş App Store profili yetenek değişince
   "Invalid" olur; sil. Codemagic sonraki derlemede ikisini de (uygulama + widget) yeniden
   üretir (`codemagic.yaml` → "Set up code signing").

Android'i sonra yayımlarsan `android-play` iş akışı hazır: yükleme anahtarını Codemagic'e
"Android keystore" olarak `kacgunoldu_upload` adıyla yükle.
