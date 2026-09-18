import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/logic.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/card_glyph.dart';
import '../widgets/rhythm_ring.dart';
import '../widgets/ui.dart';

/// "Durum renkleri" — the four tiers side by side, each explained.
class LegendScreen extends StatelessWidget {
  const LegendScreen({super.key});

  static const _rows = <(Tier, String, String, String, String, String, int)>[
    (
      Tier.fresh,
      'Yeni',
      'Yakın zamanda yaptın; her zamanki aralığın yarısı bile dolmadı.',
      'Çarşafları değiştirdim',
      'bed',
      'yeni',
      18,
    ),
    (
      Tier.calm,
      'Normal',
      'Her şey yolunda, sırası henüz gelmedi.',
      'Bitkileri suladım',
      'plant',
      '5 gün',
      60,
    ),
    (
      Tier.soon,
      'Yaklaşıyor',
      'Her zamanki aralık dolmak üzere ya da doldu.',
      'Saçımı kestirdim',
      'scissors',
      'bugün',
      100,
    ),
    (
      Tier.late,
      'Gecikti',
      'Her zamanki aralığı belirgin şekilde aştı.',
      'Spor salonuna gittim',
      'gym',
      '+8 gün',
      100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(title: 'Durum renkleri'),
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
                'Kartın rengi, durumunu anlatır.',
                style: display(24, color: AppColor.onSurface, height: 1.16),
              ),
              const SizedBox(height: Space.s16),
              for (final (tier, title, body, sample, icon, ring, pct) in _rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s12),
                  child: _TierRow(
                    tier: tier,
                    title: title,
                    body: body,
                    sample: sample,
                    icon: icon,
                    ring: ring,
                    pct: pct,
                  ),
                ),
              const SizedBox(height: Space.s8),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halka ne gösterir?',
                      style: ui(
                        14,
                        weight: FontWeight.w700,
                        color: AppColor.onSurface,
                      ),
                    ),
                    const SizedBox(height: Space.s8),
                    Text(
                      'Halka, bir sonraki sefere ne kadar kaldığını gösterir. '
                      '“4 gün” dört gün kaldı, “bugün” sırası bugün, “+8 gün” her zamanki '
                      'aralığı sekiz gün aştı demek. “yeni” ise ritim henüz öğrenilmedi demek — '
                      'üç kayıttan sonra ya da bir sıklık seçince öğrenilir.',
                      style: ui(
                        13,
                        color: AppColor.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.title,
    required this.body,
    required this.sample,
    required this.icon,
    required this.ring,
    required this.pct,
  });

  final Tier tier;
  final String title;
  final String body;
  final String sample;
  final String icon;
  final String ring;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final p = tiers[tier]!;
    return Semantics(
      label: '$title: $body',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Space.s16),
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(Radii.card),
            boxShadow: tier == Tier.late ? Elevation.cardLate : Elevation.card,
          ),
          child: Row(
            children: [
              CardGlyph(iconKey: icon, color: p.ink, size: 30),
              const SizedBox(width: Space.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ui(16, weight: FontWeight.w800, color: p.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sample,
                      style: ui(
                        12.5,
                        weight: FontWeight.w600,
                        color: p.ink.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      body,
                      style: ui(
                        11.5,
                        color: p.ink.withValues(alpha: 0.72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.s12),
              RhythmRing(
                pct: pct,
                ring: p.ring,
                track: p.track,
                ink: p.ink,
                label: ring,
                reduceMotion: true,
                size: 58,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
