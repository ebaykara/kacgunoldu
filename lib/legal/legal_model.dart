/// Data shapes for the in-app legal texts. The texts themselves live in
/// `legal_text.dart`, generated from `store/legal/content.py`.
enum LegalBlockKind { paragraph, bullets, callout, contact }

class LegalBlock {
  const LegalBlock.p(String this.text)
      : kind = LegalBlockKind.paragraph,
        items = const [];
  const LegalBlock.callout(String this.text)
      : kind = LegalBlockKind.callout,
        items = const [];
  const LegalBlock.list(this.items)
      : kind = LegalBlockKind.bullets,
        text = null;
  const LegalBlock.contact()
      : kind = LegalBlockKind.contact,
        text = null,
        items = const [];

  final LegalBlockKind kind;
  final String? text;
  final List<String> items;
}

class LegalSection {
  const LegalSection(this.title, this.blocks);
  final String title;
  final List<LegalBlock> blocks;
}

class LegalDoc {
  const LegalDoc({
    required this.title,
    required this.updated,
    required this.lead,
    required this.sections,
  });
  final String title;
  final String updated;
  final String lead;
  final List<LegalSection> sections;
}
