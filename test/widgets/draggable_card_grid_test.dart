import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/card.dart';
import 'package:kac_gun_oldu/domain/date.dart';
import 'package:kac_gun_oldu/domain/logic.dart';
import 'package:kac_gun_oldu/widgets/card_tile.dart';
import 'package:kac_gun_oldu/widgets/draggable_card_grid.dart';

const today = '2026-09-18';

DecoratedCard deck(String name, List<int> offsets) => decorate(
      Card(
        id: name,
        name: name,
        recs: offsets.map((o) => shiftDays(today, -o)).toList(),
      ),
      today,
    );

void main() {
  late List<List<String>> reorders;
  late List<String> taps;

  setUp(() {
    reorders = [];
    taps = [];
  });

  Future<void> pumpGrid(WidgetTester tester, List<DecoratedCard> cards) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DraggableCardGrid(
              cards: cards,
              columnWidth: 177,
              onTapCard: (c) => taps.add(c.id),
              onReorder: reorders.add,
              recordPulseId: null,
              recordPulseNonce: null,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final cards = [
    deck('bir', [1]),
    deck('iki', [2]),
    deck('üç', [3]),
    deck('dört', [4]),
  ];

  testWidgets('a plain tap opens the card instead of starting a drag', (tester) async {
    await pumpGrid(tester, cards);

    await tester.tap(find.text('iki'));
    await tester.pumpAndSettle();

    expect(taps, ['iki']);
    expect(reorders, isEmpty);
  });

  testWidgets('long-press and drag moves a card and reports the new order', (tester) async {
    await pumpGrid(tester, cards);

    // Pick up the last card and carry it over the first one.
    final gesture = await tester.startGesture(tester.getCenter(find.text('dört')));
    await tester.pump(const Duration(milliseconds: 400)); // past the 350ms hold
    await gesture.moveTo(tester.getCenter(find.text('bir')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reorders, hasLength(1));
    expect(reorders.single.first, 'dört');
    // Nothing was lost or duplicated along the way.
    expect(reorders.single.toSet(), {'bir', 'iki', 'üç', 'dört'});
    expect(reorders.single, hasLength(4));
  });

  testWidgets('a long press that never moves leaves the order untouched', (tester) async {
    await pumpGrid(tester, cards);

    final gesture = await tester.startGesture(tester.getCenter(find.text('iki')));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();

    // The drag still "completes", but with the order it started in.
    expect(reorders, hasLength(1));
    expect(reorders.single, ['bir', 'iki', 'üç', 'dört']);
    // And it must not be mistaken for a tap.
    expect(taps, isEmpty);
  });

  testWidgets('dragging the first card to the end reverses nothing else', (tester) async {
    await pumpGrid(tester, cards);

    final gesture = await tester.startGesture(tester.getCenter(find.text('bir')));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveTo(tester.getCenter(find.text('dört')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reorders.single, ['iki', 'üç', 'dört', 'bir']);
  });

  testWidgets('a lifted card keeps its size in the grid, not its content height', (
    tester,
  ) async {
    // The long name makes the row taller than the short card's own content.
    await pumpGrid(tester, [
      deck('kısa', [1]),
      deck('Çok uzun bir kart adı ki iki üç satıra sarsın diye yazıldı', [2]),
    ]);
    final cell = tester.getSize(find.byType(CardTile).first);

    final gesture = await tester.startGesture(tester.getCenter(find.text('kısa')));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveBy(const Offset(0, 5));
    await tester.pump();

    final lifted = find.byWidgetPredicate((w) => w is CardTile && w.isDragging);
    expect(lifted, findsOneWidget);
    expect(tester.getSize(lifted), cell);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
