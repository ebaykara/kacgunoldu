import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/logic.dart';
import 'package:kac_gun_oldu/theme/tokens.dart';
import 'package:kac_gun_oldu/widgets/card_tile.dart';
import 'package:kac_gun_oldu/widgets/draggable_card_grid.dart';

const today = '2026-09-18';

Card card(String name, List<int> offsets) => Card(
      id: name,
      name: name,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
    );

/// Mirrors exactly how the grid houses a card (`draggable_card_grid.dart`):
/// an `Expanded` cell of a stretched `Row` inside `IntrinsicHeight`. That is
/// what gives CardTile's spaceBetween column a bounded height to push the
/// count down with — a layout the app actually uses.
Future<void> pumpTile(WidgetTester tester, Card c, {double width = 177}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CardTile(card: decorate(c, today), onTap: () {}, reduceMotion: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Where a text's alphabetic baseline lands on screen, through any
/// FittedBox scaling.
double baselineY(WidgetTester tester, Finder f) {
  final box = tester.renderObject<RenderBox>(f);
  final text = tester.widget<Text>(f);
  final painter = TextPainter(
    text: TextSpan(text: text.data, style: text.style),
    textDirection: TextDirection.ltr,
  )..layout();
  final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  painter.dispose();
  return box.localToGlobal(Offset(0, baseline)).dy;
}

/// The test environment draws every glyph as a 1em square; the real faces
/// are loaded so widths, baselines and "does it fit" match the phone.
Future<void> loadRealFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = await File('assets/fonts/$f').readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('InstrumentSerif', ['InstrumentSerif_400Regular.ttf']);
  await load('Archivo', [
    'Archivo_400Regular.ttf',
    'Archivo_500Medium.ttf',
    'Archivo_600SemiBold.ttf',
    'Archivo_700Bold.ttf',
    'Archivo_800ExtraBold.ttf',
  ]);
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('a card stays near the design minimum height', (tester) async {
    await pumpTile(tester, card('Saçımı kestirdim', [7, 17, 27, 37]));
    final height = tester.getSize(find.byType(CardTile)).height;
    expect(height, greaterThanOrEqualTo(Layout.cardMinHeight));
    expect(height, lessThan(230));
  });

  testWidgets('the count and status line sit at the bottom edge', (tester) async {
    await pumpTile(tester, card('Saçımı kestirdim', [7, 17, 27, 37]));
    final cardBottom = tester.getRect(find.byType(CardTile)).bottom;
    final statusBottom = tester.getRect(find.text('3 gün kaldı')).bottom;
    // The card pads its content by 15pt at the bottom.
    expect(cardBottom - statusBottom, lessThan(18));
  });

  testWidgets('one number only: the day count, then one status line', (tester) async {
    await pumpTile(tester, card('Bitkileri suladım', [5, 9, 12, 16]));

    expect(find.text('5'), findsOneWidget);
    expect(find.text('gün oldu'), findsOneWidget);
    // typical 4, five days since -> one day past it.
    expect(find.text('1 gün geçti'), findsOneWidget);
    // No date stamp repeating what the count already says, no text in the
    // ring, no overdue tag.
    expect(find.textContaining('Eylül'), findsNothing);
    expect(find.text('+1'), findsNothing);
    expect(find.textContaining('gecikti'), findsNothing);
  });

  testWidgets('the status line covers every state', (tester) async {
    await pumpTile(tester, card('a', [7, 17, 27, 37])); // typical 10
    expect(find.text('3 gün kaldı'), findsOneWidget);

    await pumpTile(tester, card('b', [4, 8, 12, 16])); // due today
    expect(find.text('Bugün sırası'), findsOneWidget);

    await pumpTile(tester, card('c', [11, 14, 18, 20, 23])); // typical 3
    expect(find.text('8 gün geçti'), findsOneWidget);

    await pumpTile(tester, card('d', [3, 10])); // one gap: no rhythm yet
    expect(find.text('Ritim öğreniliyor'), findsOneWidget);
  });

  testWidgets('"gün oldu" sits on the number\'s baseline', (tester) async {
    await pumpTile(tester, card('Bitkileri suladım', [5, 9, 12, 16]));
    expect(
      baselineY(tester, find.text('gün oldu')),
      closeTo(baselineY(tester, find.text('5')), 1.5),
    );
  });

  testWidgets('a three-digit count stays one line, beside its unit', (tester) async {
    await pumpTile(tester, card('Diş hekimine gittim', [214, 400, 592]));

    expect(find.text('214'), findsOneWidget);
    expect(find.text('gün oldu'), findsOneWidget);
    expect(
      baselineY(tester, find.text('gün oldu')),
      closeTo(baselineY(tester, find.text('214')), 1.5),
    );
    // Wrapping the digits would balloon the card.
    expect(tester.getSize(find.byType(CardTile)).height, lessThan(230));
  });

  testWidgets('shows the glyph guessed from the name', (tester) async {
    await pumpTile(tester, card('Spor salonuna gittim', [11, 14, 18, 20, 23]));
    expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);
  });

  testWidgets('a card with no records shows a dash, not a zero', (tester) async {
    await pumpTile(tester, const Card(id: 'x', name: 'Yeni kart', recs: []));
    expect(find.text('—'), findsOneWidget);
    expect(find.text('kayıt yok'), findsOneWidget);
    expect(find.text('Henüz işaretlenmedi'), findsOneWidget);
  });

  testWidgets('the whole tile is one button with the ring spelled out', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTile(tester, card('Spor salonuna gittim', [11, 14, 18, 20, 23]));
    expect(
      find.bySemanticsLabel(
        RegExp(r'Spor salonuna gittim, 11 gün önce, geç\. her zamanki aralığı 8 gün aştı'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('two cards in a grid row share one height and one count line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 366,
              child: DraggableCardGrid(
                cards: [
                  // A long name that wraps beside a short one.
                  decorate(card('Arabanın yağını değiştirdim', [46, 80, 118]), today),
                  decorate(card('Yüzdüm', [5, 9, 12, 16]), today),
                ],
                columnWidth: 177,
                onTapCard: (_) {},
                onReorder: (_) {},
                recordPulseId: null,
                recordPulseNonce: null,
                reduceMotion: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tiles = find.byType(CardTile);
    expect(tester.getSize(tiles.at(0)).height, tester.getSize(tiles.at(1)).height);
    expect(
      baselineY(tester, find.text('46')),
      closeTo(baselineY(tester, find.text('5')), 1.5),
    );
  });
}
