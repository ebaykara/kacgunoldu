import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/logic.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/card_glyph.dart';
import '../widgets/rhythm_ring.dart';
import '../widgets/ui.dart';

/// "Durum renkleri" — the four tiers side by side, each explained.
class LegendScreen extends StatelessWidget {
  const LegendScreen({super.key});

  /// The glyph, ring label and fill per tier; the words beside them come
  /// from [Strings.legendRows], in the same order.
  static const _shape = <(Tier, String, int)>[
    (Tier.fresh, 'bed', 18),
    (Tier.calm, 'plant', 60),
    (Tier.soon, 'scissors', 100),
    (Tier.late, 'gym', 100),
  ];

  static List<String> get _ringLabels =>
      [S.ringNew, S.ringDays(5), S.ringToday, S.ringOver(8)];

  List<(Tier, String, String, String, String, String, int)> get _rows => [
    for (var i = 0; i < _shape.length; i++)
      (
        _shape[i].$1,
        S.legendRows[i].$1,
        S.legendRows[i].$2,
        S.legendRows[i].$3,
        _shape[i].$2,
        _ringLabels[i],
        _shape[i].$3,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: S.legendTitle),
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
                S.legendLead,
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
                      S.ringSectionTitle,
                      style: ui(
                        14,
                        weight: FontWeight.w700,
                        color: AppColor.onSurface,
                      ),
                    ),
                    const SizedBox(height: Space.s8),
                    Text(
                      S.ringSectionBody,
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
