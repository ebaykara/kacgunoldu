import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:ne_zaman/domain/card.dart';
import 'package:ne_zaman/domain/date.dart';
import 'package:ne_zaman/domain/logic.dart';
import 'package:ne_zaman/theme/tokens.dart';
import 'package:ne_zaman/widgets/card_tile.dart';

const today = '2026-09-18';

Card card(String name, List<int> offsets) => Card(
      id: name,
      name: name,
      recs: offsets.map((o) => shiftDays(today, -o)).toList(),
    );

Future<void> pumpTile(WidgetTester tester, Card c, {double width = 177}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: CardTile(
              card: decorate(c, today),
              onTap: () {},
              reduceMotion: true,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a calm card stays close to the design minimum height', (tester) async {
    // typical 10, seven days since -> calm, no tag crowding the name.
    await pumpTile(tester, card('Saçımı kestirdim', [7, 17, 27, 37]));
    final height = tester.getSize(find.byType(CardTile)).height;

    // The design calls for a 168pt floor. Allow a little slack for a wrapped
    // name, but a card that has ballooned past ~200 means the big number's
    // line box is not being compressed the way `line-height: .86` compresses
    // it in the mock.
    expect(height, greaterThanOrEqualTo(Layout.cardMinHeight));
    expect(height, lessThan(200));
  });

  testWidgets('shows the day count, the interval and no overdue tag', (tester) async {
    await pumpTile(tester, card('Bitkileri suladım', [5, 9, 12, 16]));

    expect(find.text('5'), findsOneWidget);
    expect(find.text('gün'), findsOneWidget);
    expect(find.text('13 Eylül ~4 günde bir'), findsOneWidget);
    // typical 4, five days since -> one day past the usual interval.
    expect(find.text('+1 gün'), findsOneWidget);
    expect(find.textContaining('geç'), findsNothing);
  });

  testWidgets('an overdue card explains itself in the tag', (tester) async {
    await pumpTile(tester, card('Spor salonuna gittim', [11, 14, 18, 20, 23]));

    // The tag says *why*, and the ring carries the same number.
    expect(find.text('8 gün geç'), findsOneWidget);
    expect(find.text('+8 gün'), findsOneWidget);
  });

  testWidgets('a three-digit day count stays on one line', (tester) async {
    await pumpTile(tester, card('Diş hekimine gittim', [214, 400, 592]));

    expect(find.text('214'), findsOneWidget);
    // Wrapping the digits would double the card's height; scaling keeps it at
    // the design's 168pt floor.
    expect(tester.getSize(find.byType(CardTile)).height, lessThan(200));
  });

  testWidgets('a card with no records reads as new', (tester) async {
    await pumpTile(tester, const Card(id: 'x', name: 'Yeni kart', recs: []));

    expect(find.text('Henüz işaretlenmedi'), findsOneWidget);
    expect(find.text('yeni'), findsOneWidget);
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
}
