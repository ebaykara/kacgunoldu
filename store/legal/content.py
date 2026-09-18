"""
The legal texts of "Kaç Gün Oldu?" - one source for everything that shows them:
  * the in-app screens (Turkish)            -> lib/legal/legal_text.dart
  * the pages on gezip.app (Turkish + English)  -> public/kacgunoldu/...

Edit the text HERE, then run  python store/legal/build.py  (see its docstring).
Keep every statement true to what the app does: the App Store / Play Store
privacy answers (store/play_console_answers.md) are made from the same facts.

Markup inside a paragraph: **bold**, [text](https://url).
Block kinds: ("p", text) ("ul", [items]) ("callout", text) ("contact", None)
"""

EMAIL = "info@gezip.app"
DEVELOPER = "EMA Labs"
UPDATED_TR = "19 Eylül 2026"
UPDATED_EN = "19 September 2026"
APPLE_EULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

# --------------------------------------------------------------------------
# PRIVACY - Turkish
# --------------------------------------------------------------------------
PRIVACY_TR = dict(
    slug="gizlilik",
    title="Gizlilik Politikası",
    h1="Gizlilik<br/>Politikası",
    badge="Kaç Gün Oldu? · Yasal",
    description="Kaç Gün Oldu? gizlilik politikası: hiçbir kişisel veri toplamayız, kartların ve kayıtların yalnızca cihazında kalır.",
    updated=UPDATED_TR,
    lead="**Girdiğin kartlar ve kayıtlar hiçbir zaman toplanmaz, bir sunucuya gönderilmez ve kimseyle paylaşılmaz.** Yalnızca kendi cihazında kalır. Uygulamada hesap, reklam, analiz aracı ya da takip yoktur.",
    sections=[
        ("Genel Bakış", [
            ("p", "Bu gizlilik politikası, **Kaç Gün Oldu?** uygulamasının (“Uygulama”) bilgilerini nasıl ele aldığını açıklar. Uygulama, bir şeyi en son ne zaman yaptığını takip etmen için tasarlanmış, tamamen çevrimdışı çalışan bir araçtır."),
            ("p", "Uygulamayı kullanmak için hesap oluşturman, giriş yapman ya da herhangi bir kişisel bilgi vermen gerekmez. Uygulama hiçbir ağ bağlantısı kurmaz."),
        ]),
        ("Toplanan Veriler", [
            ("p", "**Hiçbir kişisel veri toplanmaz.** Özellikle:"),
            ("ul", [
                "Ad, e-posta adresi, telefon numarası gibi kimlik bilgileri toplanmaz",
                "Konum, kişiler, fotoğraflar, takvim, mikrofon ya da kamera bilgisi toplanmaz",
                "Kartların ve kayıt tarihlerin geliştiriciye ya da başka bir tarafa gönderilmez",
                "Reklam kimliği, analiz ya da çökme raporu gibi hiçbir izleme verisi toplanmaz",
            ]),
        ]),
        ("Cihazında Saklanan Bilgiler", [
            ("p", "Uygulamayı kullanırken girdiğin bilgiler yalnızca **kendi cihazında**, işletim sisteminin uygulamalara ayırdığı korumalı depolama alanında saklanır. Cihazındaki başka uygulamalar bu alana erişemez:"),
            ("ul", [
                "Oluşturduğun kartlar: ad, simge, seçtiğin sıklık ve hatırlatma tercihi",
                "Her karta işaretlediğin tarihler",
                "İsteğe bağlı olarak girdiğin ad ve kullanıcı adı (yalnızca profil ekranında görünür)",
                "Uygulama tercihlerin: renk teması, kart düzeni (ızgara ya da liste), hatırlatma saati",
            ]),
            ("p", "Bu bilgilere geliştirici dahil hiç kimse erişemez."),
        ]),
        ("Yedekleme", [
            ("p", "Uygulama kendi başına hiçbir buluta yedekleme yapmaz. Ancak işletim sistemlerinin kendi yedekleme özellikleri (Android'de Google hesabına yedekleme, iOS'ta iCloud ve bilgisayar yedekleri) açıksa, uygulama verilerin bu yedeğe dahil edilebilir. Bu yedek senin Google ya da Apple hesabın altında ilgili şirket tarafından yönetilir ve geliştiricinin erişimine açık değildir."),
            ("p", "Ayrıca dilersen **Ayarlar → Yedeği panoya kopyala** ile verilerini metin olarak kopyalayabilir, başka bir cihazda **Panodaki yedeği geri yükle** ile içeri alabilirsin. Bu yedek şifrelenmemiş düz metindir; nereye yapıştıracağın sana bağlıdır."),
        ]),
        ("Pano Kullanımı", [
            ("p", "Uygulama panoya yalnızca sen “Yedeği panoya kopyala”ya ya da “Panodaki yedeği geri yükle”ye dokunduğunda erişir. Başka hiçbir zaman panonu okumaz. Bazı Android ve iOS sürümleri, bir uygulama panoya eriştiğinde seni bilgilendirir; bu beklenen bir davranıştır."),
        ]),
        ("Hatırlatmalar", [
            ("p", "Bir karta “Bana hatırlat” dediğinde, kartın sırası geldiğinde seçtiğin saatte bir bildirim gösterilir. Bildirimler tamamen **cihazında** planlanır: zaman ve gösterilecek metin işletim sisteminin kendi bildirim sistemine verilir, hiçbir sunucuya gönderilmez. Uygulama anlık bildirim (push) altyapısı kullanmaz ve bildirim jetonu üretmez."),
            ("p", "Bildirimde kartının adı görünür; yani kilit ekranında okunabilir hâle gelebilir. Hassas bir kart adı için hatırlatmayı kapalı tutmayı tercih edebilirsin."),
            ("p", "Bildirimler için işletim sistemi izni gerekir. Bu izin, ilk hatırlatmayı açtığında istenir; uygulamayı ilk açtığında istenmez. İznin dilediğin zaman telefon ayarlarından geri alınabilir; vermezsen uygulamanın geri kalanı olduğu gibi çalışır. Android'de hatırlatmalar tam zamanlı alarm izni gerektirmeyecek şekilde planlanır, bu yüzden bildirim hedeflenen saatten birkaç dakika sonra gelebilir."),
        ]),
        ("Üçüncü Taraf Hizmetler", [
            ("p", "Uygulama; reklam ağı, analiz aracı, çökme raporlama aracı, sosyal medya bileşeni ya da kullanıcı verisi toplayan herhangi bir üçüncü taraf yazılım geliştirme kiti (SDK) içermez. Uygulamada kullanılan yazı tipleri uygulamanın içinde paketlidir; internetten indirilmez."),
            ("p", "Uygulamayı indirdiğin mağaza (Google Play ya da Apple App Store) indirme işlemine ilişkin kendi gizlilik politikası kapsamında bilgi işleyebilir; bu, Uygulama'nın dışındadır."),
        ]),
        ("İzinler", [
            ("p", "Uygulama; kamera, mikrofon, konum, kişiler, takvim ya da fotoğraf izni istemez ve internet izni kullanmaz."),
            ("ul", [
                "**Bildirim izni:** yalnızca hatırlatma kurduğunda istenir",
                "**Açılışta çalışma (Android):** telefon yeniden başladığında planlanmış hatırlatmaların yeniden kurulabilmesi için",
                "**Titreşim (Android):** bildirim geldiğinde",
            ]),
        ]),
        ("Verilerinin Silinmesi", [
            ("p", "Verilerin tamamı senin denetimindedir. Tek tek kartları ve kayıtları uygulama içinden silebilir, **Ayarlar → Bütün kartları sil** ile hepsini tek seferde kaldırabilirsin. Uygulamayı cihazından kaldırdığında uygulamaya ait tüm yerel veriler de silinir."),
            ("p", "Geliştiricide saklanan hiçbir verin olmadığı için ayrıca bir silme talebi göndermene gerek yoktur. İşletim sisteminin bulut yedeği açıksa, o yedekteki kopya ilgili Google ya da Apple hesabından ayrıca silinebilir."),
        ]),
        ("Güvenlik", [
            ("p", "Verilerin işletim sisteminin uygulama sanal alanı (sandbox) ile korunur. Uygulama verileri ayrıca kendi başına şifrelemez; güvenlik cihazının ekran kilidi ve cihaz şifrelemesi ayarlarına bağlıdır. Cihazında ekran kilidi kullanmanı öneririz."),
        ]),
        ("Çocukların Gizliliği", [
            ("p", "Uygulama çocuklara yönelik olarak pazarlanmaz. Uygulama hiç kimseden, çocuklar dahil, kişisel veri toplamaz."),
        ]),
        ("Yasal Haklarım", [
            ("p", "6698 sayılı KVKK, GDPR ve benzeri veri koruma mevzuatı kapsamında erişim, düzeltme, silme ve itiraz haklarına sahipsin. Geliştirici kişisel verini işlemediği için bu haklar bakımından karşılanacak bir veri yoktur; bütün bilgilerin cihazındadır ve tümüyle senin denetimindedir."),
            ("callout", f"Soru ya da talebin olursa [{EMAIL}](mailto:{EMAIL}) adresine yazabilirsin."),
        ]),
        ("Politikadaki Değişiklikler", [
            ("p", "Bu politika güncellenirse güncel metin uygulamanın yeni sürümüyle ve bu sayfada yayımlanır, yukarıdaki güncelleme tarihi değiştirilir. Veri işleme uygulamalarımızda esaslı bir değişiklik olursa bu, sürüm notlarında belirtilir."),
        ]),
        ("İletişim", [
            ("p", "Bu politika ya da uygulamanın gizlilik uygulamaları hakkındaki soru ve talepler için:"),
            ("contact", None),
        ]),
    ],
)

# --------------------------------------------------------------------------
# TERMS - Turkish
# --------------------------------------------------------------------------
TERMS_TR = dict(
    slug="kullanim-kosullari",
    title="Kullanım Koşulları",
    h1="Kullanım<br/>Koşulları",
    badge="Kaç Gün Oldu? · Yasal",
    description="Kaç Gün Oldu? kullanım koşulları: uygulamanın nasıl kullanılacağı, yedekleme ve hatırlatmalara ilişkin önemli bilgiler.",
    updated=UPDATED_TR,
    lead="**Kaç Gün Oldu?** ücretsiz, çevrimdışı ve kişisel kullanım içindir. Verilerin yalnızca senin cihazında durur; bu yüzden **yedeklemek senin sorumluluğundadır** ve hatırlatmalar **kritik işler için tek başına güvenilecek bir araç değildir.** Aşağıda bunlar ve diğer koşullar var.",
    sections=[
        ("Kabul", [
            ("p", "Uygulamayı indirerek, kurarak ya da kullanarak bu Kullanım Koşulları'nı kabul etmiş olursun. Kabul etmiyorsan uygulamayı kullanma ve cihazından kaldır."),
        ]),
        ("Hizmetin Tanımı", [
            ("p", "**Kaç Gün Oldu?**, EMA Labs tarafından geliştirilen; bir şeyi en son ne zaman yaptığını kaydetmene, üzerinden kaç gün geçtiğini görmene ve isteğe bağlı hatırlatma almana yarayan bir mobil uygulamadır. Uygulama ücretsizdir, hesap gerektirmez ve internet bağlantısı olmadan çalışır."),
        ]),
        ("Lisans", [
            ("p", "EMA Labs sana, Uygulama'yı kendi cihazlarında kişisel amaçla kullanman için kişisel, devredilemez, münhasır olmayan ve geri alınabilir bir lisans verir. Uygulama sana satılmaz, yalnızca kullanım hakkı lisanslanır."),
        ]),
        ("Senin Verilerin", [
            ("p", "Girdiğin kartlar, kayıtlar ve diğer bilgiler sana aittir. Bunlar yalnızca cihazında saklanır; EMA Labs bunlara erişemez, bunları göremez ve geri getiremez. Girdiğin bilgilerden ve bunları nasıl kullandığından sen sorumlusun. Ayrıntılar için [Gizlilik Politikası](/kacgunoldu/gizlilik)'na bak."),
        ]),
        ("Yedekleme ve Veri Kaybı", [
            ("p", "Verilerin bir sunucuda tutulmadığı için, **uygulamayı silmen, telefonunu değiştirmen, cihazı sıfırlaman ya da cihazın bozulması hâlinde verilerin geri gelmez** (işletim sisteminin bulut yedeği açıksa ve o yedekten geri yüklersen hariç)."),
            ("p", "Bu yüzden önemli verilerini korumak için **Ayarlar → Yedeği panoya kopyala** özelliğini kullanıp yedeği güvenli bir yere (ör. notlar uygulaman ya da e-posta) kaydetmeni öneririz. EMA Labs, veri kaybından doğan zararlardan, kanunen sınırlanamayan haller dışında sorumlu tutulamaz."),
        ]),
        ("Hatırlatmalar ve Hesaplamalar", [
            ("p", "Hatırlatmalar **elinden geldiğince** (best-effort) gösterilir. Telefonun pil tasarrufu, “rahatsız etme” modu, uygulama kısıtlamaları, kapatılmış bildirim izni ya da işletim sisteminin zamanlama sınırları nedeniyle bildirim gecikebilir ya da hiç gelmeyebilir."),
            ("p", "Uygulamanın gösterdiği süreler, ritim ve “gecikti” gibi durumlar, senin girdiğin tarihlerden yapılan **basit tahminlerdir**; kişisel kolaylık içindir. Uygulamayı **ilaç kullanımı, sağlık kontrolü, güvenlik, hukuki süre, ödeme ya da benzeri kritik yükümlülükler için tek başına kullanma**; bunlar için ayrıca alarm, takvim ya da ilgili kurumun hatırlatmalarını kullan."),
        ]),
        ("Kabul Edilebilir Kullanım", [
            ("p", "Uygulamayı yalnızca hukuka uygun biçimde ve bu koşullara göre kullanabilirsin. Şunları yapamazsın:"),
            ("ul", [
                "Uygulamayı kopyalamak, satmak, kiralamak ya da başkalarına dağıtmak",
                "Yasaların açıkça izin verdiği ölçü dışında, uygulamanın kaynak kodunu çıkarmaya, tersine mühendislik yapmaya ya da değiştirmeye çalışmak",
                "Uygulamadaki telif ya da marka bildirimlerini kaldırmak",
                "Uygulamayı yasa dışı bir amaçla kullanmak",
            ]),
        ]),
        ("Fikri Mülkiyet ve Açık Kaynak", [
            ("p", "Uygulamanın tasarımı, kodu, simgesi ve adı EMA Labs'e aittir. Uygulama; Flutter ve çeşitli açık kaynak paketlerle, ayrıca **Instrument Serif** ve **Archivo** yazı tipleriyle (SIL Açık Yazı Tipi Lisansı 1.1) yapılmıştır. Bu bileşenlerin lisans metinleri uygulamada **Ayarlar → Açık kaynak lisansları** altında görülebilir."),
        ]),
        ("Garanti Reddi", [
            ("p", "Uygulama “olduğu gibi” ve “mevcut haliyle” sunulur. Yasaların izin verdiği en geniş ölçüde EMA Labs, kesintisiz ya da hatasız çalışacağına, hatırlatmaların zamanında geleceğine ya da belirli bir amaca uygun olacağına dair açık ya da örtülü hiçbir garanti vermez."),
        ]),
        ("Sorumluluğun Sınırlanması", [
            ("p", "Yasaların izin verdiği en geniş ölçüde EMA Labs, uygulamanın kullanımından ya da kullanılamamasından doğan dolaylı, arızi ya da sonuç olarak ortaya çıkan zararlardan (veri kaybı, kaçırılan bir hatırlatma dahil) sorumlu değildir. **Kasıt ve ağır kusur hâlleri ile, 6502 sayılı Tüketicinin Korunması Hakkında Kanun dahil, kanunen sınırlanamayan sorumluluk ve haklar bu maddeden etkilenmez.**"),
        ]),
        ("Değişiklikler ve Sonlandırma", [
            ("p", "Uygulamayı ve bu koşulları zaman zaman güncelleyebiliriz. Güncel koşullar uygulamada ve bu sayfada yayımlanır; esaslı değişiklikten sonra uygulamayı kullanmaya devam etmen, güncel koşulları kabul ettiğin anlamına gelir. Uygulamayı dilediğin zaman kaldırarak kullanımı sonlandırabilirsin."),
        ]),
        ("Google Play ve Apple App Store", [
            ("p", f"Bu koşullar yalnızca senin ve EMA Labs arasındadır; Google ya da Apple bu koşulların tarafı değildir ve uygulamanın bakımı, desteği ya da garantisinden sorumlu değildir. **iOS'ta** Apple'ın standart Lisanslı Uygulama Sonlandırma Sözleşmesi ([Apple standart EULA]({APPLE_EULA})) bu koşullara ek olarak geçerlidir; bu koşullar onun yerine geçmez. Apple ve yan kuruluşları, bu koşulların senin lehine üçüncü taraf yararlanıcılarıdır."),
        ]),
        ("Uygulanacak Hukuk", [
            ("p", "Bu koşullara Türkiye Cumhuriyeti hukuku uygulanır. Tüketici işlemlerinde, kanunla belirlenen tüketici hakem heyetleri ve tüketici mahkemeleri yetkilidir; yaşadığın ülkedeki zorunlu tüketici koruma hükümleri saklıdır."),
        ]),
        ("İletişim", [
            ("p", "Bu koşullar hakkındaki soruların için:"),
            ("contact", None),
        ]),
    ],
)

# --------------------------------------------------------------------------
# SUPPORT - Turkish
# --------------------------------------------------------------------------
SUPPORT_TR = dict(
    slug="destek",
    title="Destek",
    h1="Destek ve<br/>İletişim",
    badge="Kaç Gün Oldu? · Destek",
    description="Kaç Gün Oldu? için sık sorulan sorular ve iletişim.",
    updated=UPDATED_TR,
    lead="Sorunun cevabı aşağıda değilse **" + EMAIL + "** adresine yaz; genellikle birkaç iş günü içinde dönüş yapıyoruz.",
    sections=[
        ("Kartlarım nerede saklanıyor?", [
            ("p", "Yalnızca telefonunda. Uygulamanın hesabı ve sunucusu yoktur; hiçbir veri dışarı gönderilmez."),
        ]),
        ("Telefonumu değiştirirsem kartlarım ne olur?", [
            ("p", "Eski telefonda **Ayarlar → Yedeği panoya kopyala**'ya dokun, kopyalanan metni kendine gönder (notlar uygulaması, e-posta…). Yeni telefonda uygulamayı aç, o metni kopyala ve **Ayarlar → Panodaki yedeği geri yükle**'ye dokun."),
            ("p", "Telefonunun bulut yedeği (Google ya da iCloud) açıksa uygulama verileri onunla da taşınabilir."),
        ]),
        ("Hatırlatma gelmiyor", [
            ("ul", [
                "Kartta **Bana hatırlat** açık mı? (kartı aç → ⋯ menüsü)",
                "Kartın bir ritmi var mı? Ritim ya sen bir sıklık seçince ya da en az 3 kayıttan sonra oluşur.",
                "Telefonun ayarlarında uygulamanın **bildirim izni** açık mı?",
                "Pil tasarrufu ya da uygulama kısıtlaması uygulamayı engelliyor olabilir; uygulamayı kısıtlamalardan çıkar.",
                "**Ayarlar → Test bildirimi gönder** ile bildirimin telefonunda göründüğünü dene.",
                "Bildirimler tam saatinde değil, birkaç dakika sonra gelebilir.",
            ]),
        ]),
        ("Tema rengi açılışta hemen değişmedi", [
            ("p", "Açılış ekranının rengi, seçtiğin temaya **bir sonraki açılışta** uyar (Android 13 ve üzeri). Uygulamanın içi tema değişince hemen güncellenir."),
        ]),
        ("Verilerimi nasıl silerim?", [
            ("p", "Tek bir kartı silmek için kartı aç → ⋯ menüsü → **Kartı sil**. Hepsini silmek için **Ayarlar → Bütün kartları sil**. Uygulamayı kaldırmak da tüm verilerini siler."),
        ]),
        ("İletişim", [
            ("contact", None),
        ]),
    ],
)

# --------------------------------------------------------------------------
# English
# --------------------------------------------------------------------------
PRIVACY_EN = dict(
    slug="privacy",
    title="Privacy Policy",
    h1="Privacy<br/>Policy",
    badge="Kaç Gün Oldu? · Legal",
    description="Kaç Gün Oldu? privacy policy: we collect no personal data; your cards and records stay on your device.",
    updated=UPDATED_EN,
    lead="**The cards and records you enter are never collected, never sent to a server and never shared.** They stay on your own device. The app has no account, ads, analytics or tracking.",
    sections=[
        ("Overview", [
            ("p", "This privacy policy explains how **Kaç Gün Oldu?** (“the App”) handles information. The App is a fully offline tool for keeping track of when you last did something."),
            ("p", "You don't need to create an account, sign in or provide any personal information. The App makes no network connections."),
        ]),
        ("Data We Collect", [
            ("p", "**No personal data is collected.** In particular:"),
            ("ul", [
                "No identity information such as name, email address or phone number",
                "No location, contacts, photos, calendar, microphone or camera data",
                "Your cards and record dates are never sent to the developer or anyone else",
                "No advertising ID, analytics or crash reports of any kind",
            ]),
        ]),
        ("What Is Stored On Your Device", [
            ("p", "What you enter is stored **only on your own device**, in the protected storage area the operating system gives the App. Other apps on your device cannot access it:"),
            ("ul", [
                "The cards you create: name, icon, the frequency you choose and your reminder preference",
                "The dates you mark on each card",
                "Optionally, a name and username (shown only on the profile screen)",
                "Your preferences: colour theme, card layout (grid or list), reminder time",
            ]),
            ("p", "Nobody, including the developer, can access this information."),
        ]),
        ("Backups", [
            ("p", "The App does not back anything up to any cloud by itself. However, if your operating system's own backup is on (Google account backup on Android; iCloud and computer backups on iOS), the App's data may be included in it. That backup is managed by Google or Apple under your account and is not accessible to the developer."),
            ("p", "You can also use **Settings → Yedeği panoya kopyala** to copy your data as text, and **Panodaki yedeği geri yükle** to import it on another device. That backup is unencrypted plain text; where you paste it is up to you."),
        ]),
        ("Clipboard", [
            ("p", "The App accesses the clipboard only when you tap “copy backup” or “restore backup”. It never reads your clipboard at any other time. Some versions of Android and iOS notify you when an app accesses the clipboard; that is expected."),
        ]),
        ("Reminders", [
            ("p", "When you turn on “Bana hatırlat” for a card, a notification is shown at your chosen time when the card is due. Notifications are scheduled entirely **on your device**: the time and text are handed to the operating system's own notification service and are never sent to any server. The App uses no push infrastructure and creates no notification tokens."),
            ("p", "The notification shows the card's name, so it may be readable on the lock screen. You may prefer to leave reminders off for a sensitive card name."),
            ("p", "Notifications need the operating system's permission. It is requested when you turn on your first reminder, not when you first open the App, and you can withdraw it any time in your phone's settings; if you don't grant it, the rest of the App works as usual. On Android, reminders are scheduled without needing the exact-alarm permission, so a notification may arrive a few minutes after its target time."),
        ]),
        ("Third-Party Services", [
            ("p", "The App contains no ad network, analytics tool, crash reporter, social media component or any third-party software development kit (SDK) that collects user data. The typefaces used are bundled inside the App; nothing is downloaded."),
            ("p", "The store you download the App from (Google Play or the Apple App Store) may process information about the download under its own privacy policy; that is outside the App."),
        ]),
        ("Permissions", [
            ("p", "The App does not ask for camera, microphone, location, contacts, calendar or photos permission, and does not use the internet permission."),
            ("ul", [
                "**Notifications:** requested only when you set up a reminder",
                "**Run at startup (Android):** so scheduled reminders can be set up again after the phone restarts",
                "**Vibration (Android):** when a notification arrives",
            ]),
        ]),
        ("Deleting Your Data", [
            ("p", "All of your data is under your control. You can delete cards and records one by one in the App, or remove everything at once with **Settings → Bütün kartları sil**. Uninstalling the App also deletes all of its local data."),
            ("p", "Because the developer holds no data about you, there is no need to send a deletion request. If your operating system's cloud backup is on, the copy in that backup can be deleted separately from your Google or Apple account."),
        ]),
        ("Security", [
            ("p", "Your data is protected by the operating system's app sandbox. The App does not additionally encrypt it; security depends on your device's screen lock and encryption settings. We recommend using a screen lock."),
        ]),
        ("Children's Privacy", [
            ("p", "The App is not marketed to children. It collects personal data from no one, children included."),
        ]),
        ("Your Legal Rights", [
            ("p", "Under Turkish KVKK (Law No. 6698), the GDPR and similar data protection laws you have rights of access, correction, deletion and objection. Since the developer does not process your personal data, there is no data to act on; everything is on your device and entirely under your control."),
            ("callout", f"If you have a question or request, write to [{EMAIL}](mailto:{EMAIL})."),
        ]),
        ("Changes To This Policy", [
            ("p", "If this policy is updated, the current text is published with the App's new version and on this page, and the date above changes. A material change to our data practices will be stated in the release notes."),
        ]),
        ("Contact", [
            ("p", "For questions or requests about this policy or the App's privacy practices:"),
            ("contact", None),
        ]),
    ],
)

TERMS_EN = dict(
    slug="terms",
    title="Terms of Use",
    h1="Terms of<br/>Use",
    badge="Kaç Gün Oldu? · Legal",
    description="Kaç Gün Oldu? terms of use: how the app may be used, and important information about backups and reminders.",
    updated=UPDATED_EN,
    lead="**Kaç Gün Oldu?** is free, offline and for personal use. Your data lives only on your device, so **backing it up is your responsibility**, and reminders are **not a tool to rely on alone for critical matters.** These and the other terms follow.",
    sections=[
        ("Acceptance", [
            ("p", "By downloading, installing or using the App you accept these Terms of Use. If you do not accept them, do not use the App and remove it from your device."),
        ]),
        ("The Service", [
            ("p", "**Kaç Gün Oldu?** is a mobile app developed by EMA Labs for recording when you last did something, seeing how many days have passed and, optionally, getting reminders. It is free, needs no account and works without an internet connection."),
        ]),
        ("Licence", [
            ("p", "EMA Labs grants you a personal, non-transferable, non-exclusive, revocable licence to use the App on your own devices for personal purposes. The App is licensed, not sold."),
        ]),
        ("Your Data", [
            ("p", "The cards, records and other information you enter are yours. They are stored only on your device; EMA Labs cannot access, see or recover them. You are responsible for what you enter and how you use it. See the [Privacy Policy](/kacgunoldu/privacy) for details."),
        ]),
        ("Backups And Data Loss", [
            ("p", "Because your data is not kept on a server, **if you uninstall the App, change phones, reset the device or the device fails, your data does not come back** (unless your operating system's cloud backup is on and you restore from it)."),
            ("p", "To protect important data we recommend using **Settings → Yedeği panoya kopyala** and saving the backup somewhere safe (for example your notes app or email). EMA Labs cannot be held liable for damage arising from data loss, except where the law does not allow liability to be limited."),
        ]),
        ("Reminders And Calculations", [
            ("p", "Reminders are shown on a **best-effort** basis. A notification may be late or not arrive at all because of battery saver, do-not-disturb mode, app restrictions, a revoked notification permission or the operating system's scheduling limits."),
            ("p", "The durations, rhythm and states such as “late” that the App shows are **simple estimates** made from the dates you enter, for personal convenience. **Do not rely on the App alone for medication, health checks, safety, legal deadlines, payments or similar critical obligations**; use a separate alarm, calendar or the relevant institution's reminders for those."),
        ]),
        ("Acceptable Use", [
            ("p", "You may use the App only lawfully and in accordance with these terms. You may not:"),
            ("ul", [
                "Copy, sell, rent or distribute the App to others",
                "Attempt to extract the source code, reverse engineer or modify the App, except to the extent the law expressly allows",
                "Remove copyright or trademark notices from the App",
                "Use the App for any unlawful purpose",
            ]),
        ]),
        ("Intellectual Property And Open Source", [
            ("p", "The App's design, code, icon and name belong to EMA Labs. The App is built with Flutter and various open-source packages, and the typefaces **Instrument Serif** and **Archivo** (SIL Open Font License 1.1). The licence texts of these components can be viewed in the App under **Settings → Açık kaynak lisansları**."),
        ]),
        ("Disclaimer Of Warranties", [
            ("p", "The App is provided “as is” and “as available”. To the fullest extent permitted by law, EMA Labs gives no express or implied warranty that it will run uninterrupted or error-free, that reminders will arrive on time, or that it is fit for a particular purpose."),
        ]),
        ("Limitation Of Liability", [
            ("p", "To the fullest extent permitted by law, EMA Labs is not liable for indirect, incidental or consequential damages (including data loss or a missed reminder) arising from use of or inability to use the App. **Intent and gross negligence, and liability and rights that cannot be limited by law, including under Turkish Consumer Protection Law No. 6502, are not affected by this section.**"),
        ]),
        ("Changes And Termination", [
            ("p", "We may update the App and these terms from time to time. The current terms are published in the App and on this page; continuing to use the App after a material change means you accept the current terms. You may stop using the App at any time by uninstalling it."),
        ]),
        ("Google Play And The Apple App Store", [
            ("p", f"These terms are between you and EMA Labs only; Google and Apple are not parties to them and are not responsible for the App's maintenance, support or warranty. **On iOS**, Apple's Standard Licensed Application End User License Agreement ([Apple Standard EULA]({APPLE_EULA})) applies in addition to these terms; these terms do not replace it. Apple and its subsidiaries are third-party beneficiaries of these terms."),
        ]),
        ("Governing Law", [
            ("p", "These terms are governed by the laws of the Republic of Türkiye. For consumer transactions, the consumer arbitration committees and consumer courts designated by law have jurisdiction; mandatory consumer protection provisions of the country where you live are reserved."),
        ]),
        ("Contact", [
            ("p", "For questions about these terms:"),
            ("contact", None),
        ]),
    ],
)

SUPPORT_EN = dict(
    slug="support",
    title="Support",
    h1="Support &<br/>Contact",
    badge="Kaç Gün Oldu? · Support",
    description="Frequently asked questions and contact for Kaç Gün Oldu?.",
    updated=UPDATED_EN,
    lead="If the answer isn't below, write to **" + EMAIL + "**; we usually reply within a few working days. (The app's interface is in Turkish.)",
    sections=[
        ("Where are my cards stored?", [
            ("p", "Only on your phone. The app has no account and no server; nothing is sent anywhere."),
        ]),
        ("What happens to my cards if I change phones?", [
            ("p", "On the old phone tap **Ayarlar → Yedeği panoya kopyala**, send the copied text to yourself (notes app, email…). On the new phone open the app, copy that text and tap **Ayarlar → Panodaki yedeği geri yükle**."),
            ("p", "If your phone's cloud backup (Google or iCloud) is on, the app's data may move with it too."),
        ]),
        ("Reminders don't arrive", [
            ("ul", [
                "Is **Bana hatırlat** on for the card? (open the card → ⋯ menu)",
                "Does the card have a rhythm? It forms when you choose a frequency, or after at least 3 records.",
                "Is the app's **notification permission** on in your phone's settings?",
                "Battery saver or an app restriction may be blocking the app; take it off the restrictions.",
                "Try **Ayarlar → Test bildirimi gönder** to see a notification on your phone.",
                "Notifications may arrive a few minutes after the exact time.",
            ]),
        ]),
        ("The theme colour didn't change on the launch screen", [
            ("p", "The launch screen's colour follows your chosen theme **from the next launch** (Android 13 and up). Inside the app it updates at once."),
        ]),
        ("How do I delete my data?", [
            ("p", "To delete one card open it → ⋯ menu → **Kartı sil**. To delete everything use **Ayarlar → Bütün kartları sil**. Uninstalling the app also deletes all your data."),
        ]),
        ("Contact", [
            ("contact", None),
        ]),
    ],
)

DOCS_TR = [PRIVACY_TR, TERMS_TR, SUPPORT_TR]
DOCS_EN = [PRIVACY_EN, TERMS_EN, SUPPORT_EN]
