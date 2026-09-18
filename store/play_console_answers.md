# Play Console formları — hazır cevaplar

Play Console → uygulama → **Politika → Uygulama içeriği** bölümündeki her form için.
Cevaplar uygulamanın gerçek davranışına göre (bkz. sürüm APK'sının izinleri: yalnızca
`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`; `INTERNET` **yok**).

## Gizlilik politikası

URL: **https://gezip.app/kacgunoldu/gizlilik** (İngilizce: `/kacgunoldu/privacy`).
Sayfa `store/legal/build.py` ile üretilir, gezip.app'e yayımlanmış olmalı (README adım 3).

## Uygulama erişimi

**Tüm işlevler özel erişim gerektirmeden kullanılabilir.** (Giriş, hesap, abonelik yok.)

## Reklamlar

**Hayır**, uygulamam reklam içermiyor.

## İçerik derecelendirmesi (IARC anketi)

- Kategori: **Diğer tüm uygulama türleri** (Utility, Productivity, Communication or Other)
- Şiddet, cinsellik, küfür, uyuşturucu, kumar, korku içeriği: **hepsi Hayır**
- Kullanıcılar birbirleriyle etkileşim kuruyor / içerik paylaşıyor mu: **Hayır**
- Kullanıcının konumunu paylaşıyor mu: **Hayır**
- Dijital ürün satın alımı: **Hayır**
- Beklenen sonuç: **3+ / Herkes (PEGI 3, USK 0)**

## Hedef kitle ve içerik

- Hedef yaş grupları: **18 ve üzeri** (gerekirse 13–17 de eklenebilir; 13 altını seçme —
  seçersen Aileler politikası ve ek şartlar devreye girer)
- Uygulama çocukların ilgisini çekecek şekilde tasarlandı mı: **Hayır**

## Veri güvenliği (Data safety)

- Uygulama, zorunlu kullanıcı verisi türlerinden herhangi birini **topluyor veya
  paylaşıyor mu?** → **Hayır**
  - Gerekçe: Tüm veriler yalnızca cihazda tutulur, hiçbir veri cihazdan dışarı
    aktarılmaz; uygulamanın internet izni yoktur. Google'ın tanımına göre yalnızca
    cihazda işlenen veri "toplanan veri" sayılmaz.
- Veriler aktarım sırasında şifreleniyor mu: soru "Hayır/toplanmıyor" cevabından sonra
  gelmez.
- Kullanıcılar verilerinin silinmesini isteyebilir mi: uygulama içinde
  **Ayarlar → Bütün kartları sil**; uygulamayı kaldırmak da tüm veriyi siler.
- Sonuç etiketi: **"Veri toplanmıyor" / "Üçüncü taraflarla veri paylaşılmıyor"**

## Haber uygulaması / COVID / devlet / finans / sağlık beyanları

Hepsi **Hayır** — uygulama bunlardan hiçbiri değil. (Sağlık: yalnızca kullanıcının
kendi girdiği tarihleri tutar; tıbbi ya da sağlık verisi işlemez, sağlık uygulaması
değildir.)

## İzin beyanları

Ek beyan gerektiren hassas izin **yok**: `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`
kullanılmıyor (hatırlatmalar esnek zamanlanıyor), konum, kamera, rehber, SMS yok.
`POST_NOTIFICATIONS` için beyan formu gerekmez.

---

# App Store Connect (iOS) — gizlilik etiketi

- **Data Not Collected** (Veri Toplanmıyor)
- Export compliance: `Info.plist`'te `ITSAppUsesNonExemptEncryption = NO` hazır, her
  yüklemede soru sorulmaz.
- Yaş derecelendirmesi anketinde her şey **None** → **4+**
- Kategori: **Productivity**
