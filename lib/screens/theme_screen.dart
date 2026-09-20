import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../l10n/strings.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/ui.dart';

/// "Tema" — every colour combination as a small live preview of the home
/// screen. Tapping one applies it at once.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key, required this.store});

  final CardStore store;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: S.themeTitle),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(Space.s18, Space.s8, Space.s18, media.padding.bottom + Space.s22),
              children: [
                Text(
                  S.themeLead,
                  style: display(24, color: AppColor.onSurface, height: 1.16),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  S.themeNote,
                  style: ui(13, color: AppColor.onSurfaceVariant, height: 1.45),
                ),
                const SizedBox(height: Space.s18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = math.max(0.0, (constraints.maxWidth - Space.s12) / 2);
                    return Wrap(
                      spacing: Space.s12,
                      runSpacing: Space.s12,
                      children: [
                        for (final p in palettes)
                          SizedBox(
                            width: w,
                            child: ThemePreview(
                              palette: p,
                              selected: p.id == store.themeId,
                              onTap: () => store.setTheme(p.id),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A miniature home screen drawn in [palette]'s own colours.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.palette, required this.selected, required this.onTap});

  final Palette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    Widget mini(Color bg, Color ink, String n, {List<BoxShadow>? shadow}) => Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 26,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(n, style: display(20, color: ink, height: 0.9)),
              ],
            ),
          ),
        );

    return PressScale(
      onTap: onTap,
      scale: 0.96,
      haptic: true,
      selected: selected,
      semanticsLabel: S.themeSemantics(S.themeName(p.id)),
      child: AnimatedContainer(
        duration: Motion.hover,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.panel + 3),
          border: Border.all(
            color: selected ? AppColor.primary : AppColor.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(Radii.panel - 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.appHeadline,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: display(14, color: p.onSurface, height: 1.1),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    mini(p.primary, p.onPrimary, '11', shadow: [
                      BoxShadow(
                        color: p.shadowTint.withValues(alpha: 0.5),
                        offset: const Offset(0, 5),
                        blurRadius: 10,
                        spreadRadius: -6,
                      ),
                    ]),
                    const SizedBox(width: 6),
                    mini(p.tertiaryContainer, p.onTertiaryContainer, '3'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    mini(p.primaryContainer, p.onPrimaryContainer, '46'),
                    const SizedBox(width: 6),
                    mini(p.surfaceBright, p.onSurface, '5'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.themeName(p.id),
                        style: ui(13.5, weight: FontWeight.w700, color: p.onSurface),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: Motion.hover,
                      opacity: selected ? 1 : 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, size: 14, color: p.onPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
