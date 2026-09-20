import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/icon_guess.dart';
import '../l10n/strings.dart';

/// Every glyph a card can wear, in the order the picker shows them.
///
/// Material's outlined set covers all but the tooth, which is drawn by hand
/// ([_ToothPainter]) so the dentist card reads at a glance.
const cardGlyphs = <String, IconData?>{
  'gym': Icons.fitness_center_rounded,
  'swim': Icons.pool_rounded,
  'run': Icons.directions_run_rounded,
  'bike': Icons.directions_bike_rounded,
  'bed': Icons.bed_outlined,
  'scissors': Icons.content_cut_rounded,
  'tooth': null,
  'doctor': Icons.medical_services_outlined,
  'pill': Icons.medication_outlined,
  'plant': Icons.local_florist_outlined,
  'fridge': Icons.kitchen_outlined,
  'clean': Icons.cleaning_services_outlined,
  'laundry': Icons.local_laundry_service_outlined,
  'bath': Icons.bathtub_outlined,
  'phone': Icons.call_outlined,
  'car': Icons.directions_car_outlined,
  'book': Icons.menu_book_outlined,
  'pet': Icons.pets_outlined,
  'cart': Icons.shopping_cart_outlined,
  'coffee': Icons.local_cafe_outlined,
  'music': Icons.music_note_outlined,
  'money': Icons.payments_outlined,
  'mail': Icons.mail_outline_rounded,
  'heart': Icons.favorite_border_rounded,
  'home': Icons.home_outlined,
  'spark': Icons.auto_awesome_outlined,
};

/// Screen-reader names for the picker, in the interface's language.
Map<String, String> get glyphLabels => S.glyphLabels;

/// The glyph key a card actually shows: the picked one, or a guess.
String iconKeyOf(Card card) {
  final picked = card.icon;
  if (picked != null && cardGlyphs.containsKey(picked)) return picked;
  return guessIcon(card.name);
}

class CardGlyph extends StatelessWidget {
  const CardGlyph({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 18,
  });

  final String iconKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconKey == 'tooth') {
      return ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _ToothPainter(color),
        ),
      );
    }
    final data = cardGlyphs[iconKey] ?? cardGlyphs[defaultIconKey]!;
    return Icon(data, size: size, color: color);
  }
}

class _ToothPainter extends CustomPainter {
  _ToothPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(7.2 * s, 3.4 * s)
      ..cubicTo(4.4 * s, 3.4 * s, 3 * s, 5.6 * s, 3.4 * s, 8.6 * s)
      ..cubicTo(3.8 * s, 11.4 * s, 5.2 * s, 12.6 * s, 5.8 * s, 15.4 * s)
      ..cubicTo(6.4 * s, 18.4 * s, 6.8 * s, 21 * s, 8.4 * s, 21 * s)
      ..cubicTo(10.2 * s, 21 * s, 10.2 * s, 15.6 * s, 12 * s, 15.6 * s)
      ..cubicTo(13.8 * s, 15.6 * s, 13.8 * s, 21 * s, 15.6 * s, 21 * s)
      ..cubicTo(17.2 * s, 21 * s, 17.6 * s, 18.4 * s, 18.2 * s, 15.4 * s)
      ..cubicTo(18.8 * s, 12.6 * s, 20.2 * s, 11.4 * s, 20.6 * s, 8.6 * s)
      ..cubicTo(21 * s, 5.6 * s, 19.6 * s, 3.4 * s, 16.8 * s, 3.4 * s)
      ..cubicTo(14.8 * s, 3.4 * s, 13.6 * s, 4.6 * s, 12 * s, 4.6 * s)
      ..cubicTo(10.4 * s, 4.6 * s, 9.2 * s, 3.4 * s, 7.2 * s, 3.4 * s)
      ..close();
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ToothPainter old) => old.color != color;
}
