import 'package:flutter/material.dart' hide Card;

import '../l10n/strings.dart';
import '../legal/legal_model.dart';
import '../legal/legal_text.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/ui.dart';

/// Gizlilik Politikası / Kullanım Koşulları — the text is generated from
/// store/legal/content.py, the same source as the pages on gezip.app.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: doc.title),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Space.s18,
              Space.s8,
              Space.s18,
              media.padding.bottom + Space.s22,
            ),
            children: [
              Text(
                S.lastUpdated(doc.updated),
                style: ui(
                  12,
                  weight: FontWeight.w600,
                  color: AppColor.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: Space.s12),
              Panel(child: _Rich(doc.lead, size: 15, ink: AppColor.onSurface)),
              const SizedBox(height: Space.s18),
              for (var i = 0; i < doc.sections.length; i++)
                _Section(index: i + 1, section: doc.sections[i]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.index, required this.section});

  final int index;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '$index. ${section.title}',
              style: ui(16, weight: FontWeight.w800, color: AppColor.onSurface),
            ),
          ),
          const SizedBox(height: Space.s8),
          for (final b in section.blocks) _Block(b),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.block);

  final LegalBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.kind) {
      case LegalBlockKind.paragraph:
        return _gap(_Rich(block.text!));
      case LegalBlockKind.callout:
        return _gap(Panel(child: _Rich(block.text!, ink: AppColor.onSurface)));
      case LegalBlockKind.bullets:
        return _gap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in block.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: Space.s8),
                        child: Text(
                          '•',
                          style: ui(14, color: AppColor.primary, height: 1.5),
                        ),
                      ),
                      Expanded(child: _Rich(item)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case LegalBlockKind.contact:
        return _gap(
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.legalContactTitle,
                  style: ui(
                    14,
                    weight: FontWeight.w700,
                    color: AppColor.onSurface,
                  ),
                ),
                const SizedBox(height: Space.xs),
                SelectableText(
                  legalEmail,
                  style: ui(
                    14,
                    weight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _gap(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: Space.s12), child: child);
}

/// Body text with **bold** runs.
class _Rich extends StatelessWidget {
  const _Rich(this.text, {this.size = 14, this.ink});

  final String text;
  final double size;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final base = ui(
      size,
      color: ink ?? AppColor.onSurfaceVariant,
      height: 1.55,
    );
    final bold = base.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColor.onSurface,
    );
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(text: parts[i], style: i.isOdd ? bold : null),
        ],
      ),
    );
  }
}

/// Both languages are generated into `legal_text.dart`; the interface
/// language picks which one opens.
void openPrivacy(BuildContext context) => pushPage<void>(
  context,
  (_) => LegalScreen(
    doc: S.lang == AppLang.en ? privacyPolicyEn : privacyPolicy,
  ),
);

void openTerms(BuildContext context) => pushPage<void>(
  context,
  (_) => LegalScreen(doc: S.lang == AppLang.en ? termsOfUseEn : termsOfUse),
);
