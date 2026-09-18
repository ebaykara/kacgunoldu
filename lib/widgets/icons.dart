import 'package:flutter/widgets.dart';

/// The tab glyphs, the FAB `+` and the trash action, redrawn from the mock as
/// [CustomPainter]s so they stay crisp at any size and take the tier ink colour.
///
/// They stand in for `square.grid.2x2` / `list.bullet.indent` (SF Symbols) and
/// `grid_view` / `timeline` (Material Symbols) — swap in the system icon set if
/// the target platform ships one.

class GridIcon extends StatelessWidget {
  const GridIcon({super.key, required this.color, this.active = false, this.size = 22});

  final Color color;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _GridPainter(color: color, active: active),
      );
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 22;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * scale;
    final fill = Paint()..color = color;

    void square(double x, double y, bool filled) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scale, y * scale, 7 * scale, 7 * scale),
        Radius.circular(2.2 * scale),
      );
      if (filled) canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, stroke);
    }

    square(3, 3, active);
    square(12, 3, false);
    square(3, 12, false);
    square(12, 12, active);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color || old.active != active;
}

class TimelineIcon extends StatelessWidget {
  const TimelineIcon({super.key, required this.color, this.active = false, this.size = 22});

  final Color color;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _TimelinePainter(color: color, active: active),
      );
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 22;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * scale
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    canvas.drawLine(Offset(5.5 * scale, 3.5 * scale), Offset(5.5 * scale, 18.5 * scale), stroke);
    if (active) canvas.drawCircle(Offset(5.5 * scale, 7.5 * scale), 2.4 * scale, fill);
    canvas.drawCircle(Offset(5.5 * scale, 7.5 * scale), 2.4 * scale, stroke);
    canvas.drawCircle(Offset(5.5 * scale, 15 * scale), 2.4 * scale, stroke);
    canvas.drawLine(Offset(11 * scale, 7.5 * scale), Offset(18 * scale, 7.5 * scale), stroke);
    canvas.drawLine(Offset(11 * scale, 15 * scale), Offset(16 * scale, 15 * scale), stroke);
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => old.color != color || old.active != active;
}

class PlusIcon extends StatelessWidget {
  const PlusIcon({super.key, required this.color, this.size = 17});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PlusPainter(color),
      );
}

class _PlusPainter extends CustomPainter {
  _PlusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 17;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8.5 * scale, 1.6 * scale), Offset(8.5 * scale, 15.4 * scale), stroke);
    canvas.drawLine(Offset(1.6 * scale, 8.5 * scale), Offset(15.4 * scale, 8.5 * scale), stroke);
  }

  @override
  bool shouldRepaint(_PlusPainter old) => old.color != color;
}

class TrashIcon extends StatelessWidget {
  const TrashIcon({super.key, required this.color, this.size = 17});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _TrashPainter(color),
      );
}

class _TrashPainter extends CustomPainter {
  _TrashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 17;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Lid
    canvas.drawLine(Offset(3 * s, 4.6 * s), Offset(14 * s, 4.6 * s), stroke);
    // Handle
    final handle = Path()
      ..moveTo(6.4 * s, 4.6 * s)
      ..lineTo(6.4 * s, 3.2 * s)
      ..quadraticBezierTo(6.4 * s, 2.2 * s, 7.4 * s, 2.2 * s)
      ..lineTo(9.6 * s, 2.2 * s)
      ..quadraticBezierTo(10.6 * s, 2.2 * s, 10.6 * s, 3.2 * s)
      ..lineTo(10.6 * s, 4.6 * s);
    canvas.drawPath(handle, stroke);
    // Body
    final body = Path()
      ..moveTo(4.2 * s, 4.6 * s)
      ..lineTo(4.8 * s, 13.8 * s)
      ..quadraticBezierTo(4.9 * s, 15.1 * s, 6.2 * s, 15.1 * s)
      ..lineTo(11.8 * s, 15.1 * s)
      ..quadraticBezierTo(13.1 * s, 15.1 * s, 13.2 * s, 13.8 * s)
      ..lineTo(13.8 * s, 4.6 * s);
    canvas.drawPath(body, stroke);
    // Ribs
    canvas.drawLine(Offset(7 * s, 7.5 * s), Offset(7 * s, 11.9 * s), stroke);
    canvas.drawLine(Offset(10 * s, 7.5 * s), Offset(10 * s, 11.9 * s), stroke);
  }

  @override
  bool shouldRepaint(_TrashPainter old) => old.color != color;
}

/// The chevron on the overdue pill: `>` when closed, `^` when the filtered
/// view is showing.
class ChevronIcon extends StatelessWidget {
  const ChevronIcon({super.key, required this.color, required this.open, this.size = 9});

  final Color color;
  final bool open;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _ChevronPainter(color: color, open: open),
      );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter({required this.color, required this.open});

  final Color color;
  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 9;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (open) {
      path
        ..moveTo(1.6 * s, 5.6 * s)
        ..lineTo(4.5 * s, 2.7 * s)
        ..lineTo(7.4 * s, 5.6 * s);
    } else {
      path
        ..moveTo(3 * s, 1.6 * s)
        ..lineTo(5.9 * s, 4.5 * s)
        ..lineTo(3 * s, 7.4 * s);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color || old.open != open;
}

/// Head and shoulders, for an avatar with no name yet.
class PersonIcon extends StatelessWidget {
  const PersonIcon({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PersonPainter(color),
      );
}

class _PersonPainter extends CustomPainter {
  _PersonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 18;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(9 * s, 6 * s), 3.3 * s, stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(9 * s, 17 * s), width: 13 * s, height: 11 * s),
      3.14159,
      3.14159,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(_PersonPainter old) => old.color != color;
}
