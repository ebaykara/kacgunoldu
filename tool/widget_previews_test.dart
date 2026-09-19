// Renders the home screen widgets' picker previews (the images Android shows
// in its widget list) with the app's own pieces — ring, glyphs, fonts,
// Kiremit colours — so they look like the real thing:
//
//   flutter test tool/widget_previews_test.dart
//
// Writes android/app/src/main/res/drawable-nodpi/widget_preview_{card,list}.png.
// Lives in tool/, so the normal `flutter test` run doesn't redraw them.
// Keep the layouts in step with res/layout/widget_card.xml / widget_list*.xml.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/logic.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';
import 'package:kac_gun_oldu/theme/typography.dart';
import 'package:kac_gun_oldu/widgets/card_glyph.dart';
import 'package:kac_gun_oldu/widgets/card_status.dart';
import 'package:kac_gun_oldu/widgets/rhythm_ring.dart';

const _today = '2026-09-18';
const _out = 'android/app/src/main/res/drawable-nodpi';

DecoratedCard _card(String name, String icon, int daysAgo, int every) => decorate(
  Card(id: name, name: name, icon: icon, recs: [shiftDays(_today, -daysAgo)], every: every),
  _today,
);

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = await File(f).readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('InstrumentSerif', ['assets/fonts/InstrumentSerif_400Regular.ttf']);
  await load('Archivo', [
    for (final w in ['400Regular', '500Medium', '600SemiBold', '700Bold']) 'assets/fonts/Archivo_$w.ttf',
  ]);
  final flutter = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  await load('MaterialIcons', ['$flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
}

/// The "Bugün yaptım" button: soft circle, or filled once done today.
Widget _done(DecoratedCard card, TierPalette p, double size) {
  final done = card.stats.days == 0 && card.card.recs.isNotEmpty;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: done ? p.ring : p.ink.withValues(alpha: 0.1)),
    child: Icon(Icons.check_rounded, size: size * 0.55, color: done ? p.bg : p.ink),
  );
}

Widget _ring(DecoratedCard card, TierPalette p, double size, double glyph) => RhythmRing(
  pct: card.stats.pct,
  ring: p.ring,
  track: p.track,
  ink: p.ink,
  label: '',
  reduceMotion: true,
  size: size,
  center: CardGlyph(iconKey: iconKeyOf(card.card), color: p.ink, size: glyph),
);

Text _status(DecoratedCard card, TierPalette p, double size) {
  final s = CardStatus.of(card);
  return Text(
    s.text,
    maxLines: 1,
    style: ui(size, weight: s.urgent ? FontWeight.w700 : FontWeight.w500, color: s.color(card.stats.tier, p)),
  );
}

Widget _cardWidget(DecoratedCard card) {
  final p = tiers[card.stats.tier]!;
  return Container(
    width: 170,
    height: 170,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(24)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [_ring(card, p, 40, 18), const Spacer(), _done(card, p, 36)]),
        const SizedBox(height: 10),
        Text(card.name, maxLines: 1, style: ui(14.5, weight: FontWeight.w600, color: p.ink)),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${card.stats.days}', style: display(44, color: p.ink, height: 1)),
            const SizedBox(width: 5),
            Text('gün oldu', style: ui(12, weight: FontWeight.w500, color: p.ink.withValues(alpha: 0.72))),
          ],
        ),
        _status(card, p, 12.5),
      ],
    ),
  );
}

Widget _row(DecoratedCard card) {
  final p = tiers[card.stats.tier]!;
  return Container(
    height: 56,
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        _ring(card, p, 36, 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name, maxLines: 1, style: ui(14, weight: FontWeight.w600, color: p.ink)),
              _status(card, p, 12),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${card.stats.days}', style: display(30, color: p.ink, height: 1)),
            Text('gün oldu', style: ui(10, weight: FontWeight.w500, color: p.ink.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(width: 10),
        _done(card, p, 34),
      ],
    ),
  );
}

Widget _listWidget(List<DecoratedCard> cards) {
  final late = cards.where((c) => c.stats.isLate).length;
  return Container(
    width: 340,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(24)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              const SizedBox(width: 4),
              Expanded(child: Text('Kaç gün oldu?', style: display(22, color: AppColor.onSurface, height: 1))),
              if (late > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(100)),
                  child: Text('$late kart gecikti', style: ui(11.5, weight: FontWeight.w700, color: AppColor.onPrimary)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        for (final c in cards) _row(c),
      ],
    ),
  );
}

Future<void> _render(WidgetTester tester, String name, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: RepaintBoundary(key: key, child: child)),
    ),
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    return image.toByteData(format: dart_ui.ImageByteFormat.png);
  });
  File('$_out/widget_preview_$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render widget previews', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _render(tester, 'card', _cardWidget(_card('Saçımı kestirdim', 'scissors', 29, 30)));
    await _render(
      tester,
      'list',
      _listWidget([
        _card('Bitkileri suladım', 'plant', 9, 4),
        _card('Saçımı kestirdim', 'scissors', 29, 30),
        _card('Spor yaptım', 'gym', 0, 3),
      ]),
    );
  });
}
