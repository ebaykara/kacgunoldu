import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'ui.dart';

/// A ready-made card to start from.
class Suggestion {
  const Suggestion(this.name, this.icon, this.every);

  final String name;
  final String icon;
  final int every;
}

List<Suggestion> get suggestions => [
  for (final (name, icon, every) in S.suggestions) Suggestion(name, icon, every),
];

/// First run, or after every card is gone: a friendly start instead of a
/// blank grid. Rises and fades in over .3s.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.reduceMotion,
    required this.onCreate,
    required this.onSuggestion,
  });

  final bool reduceMotion;
  final VoidCallback onCreate;
  final ValueChanged<Suggestion> onSuggestion;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.reduceMotion ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _controller.value)),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.s22,
          media.padding.top + Space.s22,
          Space.s22,
          media.padding.bottom + Space.s22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: CustomPaint(
                  size: const Size(200, 150),
                  painter: _PlantPainter(AppColor.current.id),
                ),
              ),
            ),
            const SizedBox(height: Space.s22),
            Semantics(
              header: true,
              child: Text(
                S.emptyTitle,
                textAlign: TextAlign.center,
                style: display(27, color: AppColor.onSurface, height: 1.16),
              ),
            ),
            const SizedBox(height: Space.s12),
            Text(
              S.emptyBody,
              textAlign: TextAlign.center,
              style: ui(13.5, color: AppColor.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: Space.s22),
            PrimaryButton(
              label: S.emptyCta,
              icon: Icons.add_rounded,
              onTap: widget.onCreate,
            ),
            const SizedBox(height: 30),
            SectionTitle(S.suggestedCards),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = math.max(0.0, (constraints.maxWidth - Space.s12) / 2);
                return Wrap(
                  spacing: Space.s12,
                  runSpacing: Space.s12,
                  children: [
                    for (final s in suggestions)
                      SizedBox(
                        width: w,
                        child: PressScale(
                          onTap: () => widget.onSuggestion(s),
                          semanticsLabel: s.name,
                          child: Panel(
                            padding: const EdgeInsets.all(Space.s12),
                            radius: Radii.tile,
                            child: ExcludeSemantics(
                              child: Row(
                                children: [
                                  GlyphBadge(
                                    iconKey: s.icon,
                                    bg: AppColor.primaryContainer,
                                    fg: AppColor.primary,
                                    size: 34,
                                  ),
                                  const SizedBox(width: Space.s8),
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      maxLines: 2,
                                      style: ui(
                                        12,
                                        weight: FontWeight.w600,
                                        color: AppColor.onSurface,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A terracotta pot with a sprouting plant on a thin ground line.
class _PlantPainter extends CustomPainter {
  const _PlantPainter(this.themeId);

  /// Repaint when the theme changes; the colours come from [AppColor].
  final String themeId;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final ground = size.height - 8;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, ground), width: 120, height: 10),
      Paint()..color = AppColor.surfaceContainerHover,
    );
    canvas.drawLine(
      Offset(cx - 90, ground),
      Offset(cx + 90, ground),
      Paint()
        ..color = AppColor.outlineVariant
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Leaves fanning out of the pot.
    final stem = Paint()
      ..color = AppColor.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final leafDark = Paint()..color = AppColor.tertiary;
    final leafLight = Paint()..color = Color.lerp(AppColor.tertiary, AppColor.surfaceBright, 0.25)!;
    final vein = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.2;
    final top = ground - 52;

    void leaf(double angle, double length, Paint paint) {
      canvas.save();
      canvas.translate(cx, top);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * 0.32, -length * 0.5, 0, -length)
        ..quadraticBezierTo(-length * 0.32, -length * 0.5, 0, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(Offset.zero, Offset(0, -length * 0.8), vein);
      canvas.restore();
    }

    canvas.drawLine(Offset(cx, top), Offset(cx, top - 38), stem);
    leaf(-math.pi / 3.2, 44, leafLight);
    leaf(math.pi / 3.2, 44, leafLight);
    leaf(-math.pi / 7, 56, leafDark);
    leaf(math.pi / 7, 56, leafDark);
    leaf(0, 64, leafDark);

    // Pot: tapered body under a rim.
    final potTop = ground - 54;
    final body = Path()
      ..moveTo(cx - 30, potTop + 10)
      ..lineTo(cx + 30, potTop + 10)
      ..lineTo(cx + 22, ground - 1)
      ..quadraticBezierTo(cx + 21, ground + 1, cx + 18, ground + 1)
      ..lineTo(cx - 18, ground + 1)
      ..quadraticBezierTo(cx - 21, ground + 1, cx - 22, ground - 1)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColor.primary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 34, potTop, 68, 13),
        const Radius.circular(4),
      ),
      Paint()..color = AppColor.primaryLight,
    );
    canvas.drawLine(
      Offset(cx - 19, potTop + 17),
      Offset(cx - 15, ground - 8),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PlantPainter old) => old.themeId != themeId;
}
