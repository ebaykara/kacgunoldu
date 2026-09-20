import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show HapticFeedback;

import '../domain/card.dart' show Tier;
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'card_glyph.dart';

/// Shared building blocks for the pushed pages (detail, overdue, profile,
/// settings, the card form). Everything dips on press the same way the grid
/// cards do, so the whole app has one tactile language.

/// Scales its child down while pressed. Carries the button semantics.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.scale = 0.97,
    this.semanticsLabel,
    this.haptic = false,
    this.enabled = true,
    this.selected,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double scale;
  final String? semanticsLabel;
  final bool haptic;
  final bool enabled;
  final bool? selected;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _active,
      selected: widget.selected,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _active
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        onLongPress: widget.onLongPress,
        onTapDown: _active ? (_) => _set(true) : null,
        onTapUp: _active ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Motion.emphasized,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Top bar of a pushed page: back arrow, centred title, optional trailing.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(
        top: top + Space.xs,
        left: Space.xs,
        right: Space.xs,
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            RoundIconButton(
              icon: Icons.arrow_back_rounded,
              label: S.back,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ui(
                    16,
                    weight: FontWeight.w700,
                    color: AppColor.onSurface,
                  ),
                ),
              ),
            ),
            SizedBox(width: 48, child: trailing),
          ],
        ),
      ),
    );
  }
}

/// A 48pt round icon-only button.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.background,
    this.size = 22,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.9,
      semanticsLabel: label,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: background == null
            ? null
            : BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: size, color: color ?? AppColor.onSurface),
      ),
    );
  }
}

/// The filled terracotta call to action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.tonal = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;

  /// Soft container colours instead of the solid fill.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final fg = tonal ? AppColor.onPrimaryContainer : AppColor.onPrimary;
    return PressScale(
      onTap: onTap,
      enabled: enabled,
      scale: 0.98,
      haptic: true,
      semanticsLabel: label,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: Motion.hover,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.s20,
            vertical: Space.s15,
          ),
          decoration: BoxDecoration(
            color: tonal ? AppColor.primaryContainer : AppColor.primary,
            borderRadius: BorderRadius.circular(Radii.button),
            boxShadow: tonal || !enabled ? null : Elevation.button,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: Space.s8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ui(15, weight: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain text action under a primary button.
class QuietButton extends StatelessWidget {
  const QuietButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      semanticsLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: Layout.minTouchTarget),
        alignment: Alignment.center,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppColor.primary),
                const SizedBox(width: Space.s6),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: ui(
                      14,
                      weight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white rounded surface every list row and panel sits on.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.s16),
    this.color,
    this.radius = Radii.panel,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColor.surfaceBright,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: Elevation.timelineItem,
      ),
      child: child,
    );
  }
}

/// Glyph colours per tier for the small round badges in lists.
({Color bg, Color fg}) badgeColors(Tier tier) => switch (tier) {
  Tier.fresh => (bg: AppColor.tertiaryContainer, fg: AppColor.tertiary),
  Tier.calm => (bg: AppColor.surfaceContainer, fg: AppColor.primaryDim),
  Tier.soon => (bg: AppColor.primaryContainer, fg: AppColor.primary),
  Tier.late => (bg: AppColor.primaryContainer, fg: AppColor.primary),
};

/// A card glyph in a tinted circle.
class GlyphBadge extends StatelessWidget {
  const GlyphBadge({
    super.key,
    required this.iconKey,
    required this.bg,
    required this.fg,
    this.size = 44,
  });

  final String iconKey;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: CardGlyph(iconKey: iconKey, color: fg, size: size * 0.46),
    );
  }
}

/// Small bold section title (`Geçmiş`, `Önerilen kartlar`).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: ui(
                  15,
                  weight: FontWeight.w700,
                  color: AppColor.onSurface,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Push a full page with the platform's own transition (and, on iOS, the
/// edge swipe back).
Future<T?> pushPage<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      builder: (context) =>
          Scaffold(backgroundColor: AppColor.surface, body: builder(context)),
    ),
  );
}

/// One row in an action sheet.
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.destructive = false,
    this.enabled = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;
  final bool destructive;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColor.primary : AppColor.onSurface;
    return PressScale(
      onTap: onTap,
      enabled: enabled,
      scale: 0.98,
      semanticsLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s6),
        child: ExcludeSemantics(
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: destructive
                        ? AppColor.primaryContainer
                        : AppColor.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.item),
                  ),
                  child: Icon(icon, size: 21, color: fg),
                ),
                const SizedBox(width: Space.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: ui(15, weight: FontWeight.w700, color: fg),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail!,
                          style: ui(
                            12,
                            color: AppColor.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
