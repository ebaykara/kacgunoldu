/// A ready-made card offered on the "Yeni kart" page: tap one and the name,
/// glyph and rhythm are filled in. Named the way the field invites — a
/// first-person sentence — so they read like cards someone wrote.
class CardTemplate {
  const CardTemplate(this.name, this.icon, this.every);

  final String name;

  /// Key into the glyph catalog (`widgets/card_glyph.dart`).
  final String icon;

  /// Days; a typical rhythm for it, which the person can change.
  final int every;
}

/// The small, easy-to-forget things this app is for.
const cardTemplates = [
  CardTemplate('Diş fırçamı değiştirdim', 'tooth', 90),
  CardTemplate('Klima filtresini temizledim', 'home', 90),
  CardTemplate('Arabanın yağını değiştirdim', 'car', 365),
  CardTemplate('Lastik basıncına baktım', 'car', 30),
  CardTemplate('Nevresimi değiştirdim', 'bed', 14),
  CardTemplate('Havluları yıkadım', 'laundry', 7),
  CardTemplate('Buzdolabını temizledim', 'fridge', 30),
  CardTemplate('Banyoyu temizledim', 'bath', 7),
  CardTemplate('Bitkileri suladım', 'plant', 3),
  CardTemplate('Saçımı kestirdim', 'scissors', 30),
  CardTemplate('Diş hekimine gittim', 'tooth', 180),
  CardTemplate('Kan tahlili yaptırdım', 'doctor', 365),
  CardTemplate('Veterinere götürdüm', 'pet', 365),
  CardTemplate('Anneme telefon ettim', 'phone', 7),
  CardTemplate('Kirayı ödedim', 'money', 30),
  CardTemplate('Kitap bitirdim', 'book', 30),
];
