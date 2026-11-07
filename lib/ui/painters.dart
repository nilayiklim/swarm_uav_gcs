import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'theme.dart';

// ───────────────────────── yardımcılar ─────────────────────────

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w, {StrokeCap cap = StrokeCap.butt}) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap;

double _rad(double deg) => deg * math.pi / 180;

/// Metni (cx, cy) merkezli (hizaya göre) çizer.
void drawText(Canvas c, String t, Offset at,
    {double size = 10,
    Color color = Colors.white,
    FontWeight w = FontWeight.w400,
    TextAlign align = TextAlign.center,
    double ls = 0}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(fontSize: size, color: color, fontWeight: w, letterSpacing: ls)),
    textDirection: TextDirection.ltr,
  )..layout();
  double dx = at.dx;
  if (align == TextAlign.center) {
    dx -= tp.width / 2;
  } else if (align == TextAlign.right || align == TextAlign.end) {
    dx -= tp.width;
  }
  tp.paint(c, Offset(dx, at.dy - tp.height / 2));
}

ui.Gradient _lin(Offset a, Offset b, List<Color> colors, [List<double>? stops]) =>
    ui.Gradient.linear(a, b, colors, stops);

/// Uçak silüeti (100x100 kutuda).
final Path _planePath = Path()
  ..moveTo(50, 6)
  ..lineTo(56, 40)
  ..lineTo(96, 62)
  ..lineTo(96, 70)
  ..lineTo(56, 58)
  ..lineTo(54, 84)
  ..lineTo(66, 92)
  ..lineTo(66, 97)
  ..lineTo(50, 93)
  ..lineTo(34, 97)
  ..lineTo(34, 92)
  ..lineTo(46, 84)
  ..lineTo(44, 58)
  ..lineTo(4, 70)
  ..lineTo(4, 62)
  ..lineTo(44, 40)
  ..close();

void drawPlane(Canvas c, Offset at, double rotDeg, double size, Color color) {
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(_rad(rotDeg));
  c.scale(size / 100);
  c.translate(-50, -50);
  c.drawPath(_planePath, _fill(color));
  c.restore();
}

/// viewBox (vw x vh) -> boyuta "slice" (kapla) yerleştirir.
void _sliceTo(Canvas c, Size s, double vw, double vh) {
  final k = math.max(s.width / vw, s.height / vh);
  c.translate((s.width - vw * k) / 2, (s.height - vh * k) / 2);
  c.scale(k);
}

/// viewBox (vw x vh) -> boyuta "meet" (sığdır) yerleştirir.
void _meetTo(Canvas c, Size s, double vw, double vh) {
  final k = math.min(s.width / vw, s.height / vh);
  c.translate((s.width - vw * k) / 2, (s.height - vh * k) / 2);
  c.scale(k);
}

// ───────────────────────── cam / çerçeve (160x160 gösterge) ─────────────────────────

void _bezel(Canvas c) {
  c.drawCircle(
    const Offset(80, 80),
    78,
    Paint()
      ..shader = _lin(const Offset(10, 10), const Offset(150, 150), [
        rgba(0x7C969E),
        rgba(0x2A4047),
        rgba(0x0D1A1E),
        rgba(0x3C565E),
        rgba(0x9DB5BB),
      ], const [
        0,
        .25,
        .55,
        .8,
        1
      ]),
  );
  c.drawCircle(const Offset(80, 80), 72, _fill(rgba(0x050B0D)));
}

void _glass(Canvas c) {
  c.drawCircle(
    const Offset(80, 80),
    68,
    Paint()
      ..shader = ui.Gradient.radial(const Offset(80, 80), 68, [rgba(0x000000, 0), rgba(0x000000, .55)], const [.72, 1]),
  );
  final glare = Path()
    ..moveTo(22, 62)
    ..arcToPoint(const Offset(138, 62), radius: const Radius.circular(62))
    ..quadraticBezierTo(80, 44, 22, 62)
    ..close();
  c.drawPath(
    glare,
    Paint()..shader = _lin(const Offset(0, 20), const Offset(0, 62), [rgba(0xFFFFFF, .28), rgba(0xFFFFFF, 0)]),
  );
  c.drawCircle(const Offset(80, 80), 68, _line(rgba(0x000000, .6), 1.5));
}

// ───────────────────────── pusula ─────────────────────────

class CompassPainter extends CustomPainter {
  CompassPainter(this.heading);
  final double heading;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 160, size.height / 160);
    _bezel(c);
    c.drawCircle(const Offset(80, 80), 68, _fill(rgba(0x0B1417)));

    // dönen kadran
    c.save();
    c.translate(80, 80);
    c.rotate(_rad(-heading));
    c.translate(-80, -80);
    for (int a = 0; a < 360; a += 5) {
      final len = a % 30 == 0 ? 9.0 : (a % 10 == 0 ? 6.0 : 3.5);
      final sa = math.sin(_rad(a.toDouble()));
      final ca = -math.cos(_rad(a.toDouble()));
      c.drawLine(
        Offset(80 + 66 * sa, 80 + 66 * ca),
        Offset(80 + (66 - len) * sa, 80 + (66 - len) * ca),
        _line(a % 30 == 0 ? C.text : rgba(0x7F989E), a % 30 == 0 ? 1.4 : 1),
      );
    }
    const labs = <int, String>{
      0: 'N', 90: 'E', 180: 'S', 270: 'W',
      30: '3', 60: '6', 120: '12', 150: '15', 210: '21', 240: '24', 300: '30', 330: '33',
    };
    labs.forEach((a, t) {
      final sa = math.sin(_rad(a.toDouble()));
      final ca = -math.cos(_rad(a.toDouble()));
      final p = Offset(80 + 48 * sa, 80 + 48 * ca);
      final cardinal = t == 'N' || t == 'E' || t == 'S' || t == 'W';
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(_rad(a.toDouble()));
      drawText(c, t, Offset.zero,
          size: cardinal ? 13 : 9,
          w: FontWeight.w700,
          color: t == 'N' ? C.red : (cardinal ? C.text : rgba(0x9FB4BA)));
      c.restore();
    });
    c.restore();

    c.drawCircle(const Offset(80, 80), 24, _line(rgba(0x27424A), 1));
    c.drawPath(
      Path()
        ..moveTo(80, 52)
        ..lineTo(84, 62)
        ..lineTo(76, 62)
        ..close(),
      _fill(C.red),
    );
    final plane = Path()
      ..moveTo(80, 62)
      ..lineTo(83, 78)
      ..lineTo(96, 86)
      ..lineTo(96, 89)
      ..lineTo(83, 85)
      ..lineTo(82, 96)
      ..lineTo(87, 99)
      ..lineTo(87, 101)
      ..lineTo(80, 99.5)
      ..lineTo(73, 101)
      ..lineTo(73, 99)
      ..lineTo(78, 96)
      ..lineTo(77, 85)
      ..lineTo(64, 89)
      ..lineTo(64, 86)
      ..lineTo(77, 78)
      ..close();
    c.drawPath(plane, _fill(C.green));
    c.drawPath(plane, _line(rgba(0x06210F), .6));
    final box = RRect.fromRectAndRadius(const Rect.fromLTWH(62, 104, 36, 16), const Radius.circular(2));
    c.drawRRect(box, _fill(rgba(0x050B0D)));
    c.drawRRect(box, _line(C.green, 1));
    drawText(c, '${heading.round()}°', const Offset(80, 112), size: 11, color: C.green, w: FontWeight.w700);
    c.drawPath(
      Path()
        ..moveTo(80, 13)
        ..lineTo(75, 7)
        ..lineTo(85, 7)
        ..close(),
      _fill(C.text),
    );
    _glass(c);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CompassPainter o) => o.heading != heading;
}

// ───────────────────────── yapay ufuk ─────────────────────────

void paintHorizon(Canvas c, double rollDeg, double pitchDeg) {
  _bezel(c);
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: const Offset(80, 80), radius: 68)));
  final r = _rad(-rollDeg);

  c.save();
  c.translate(80, 80);
  c.rotate(r);
  c.translate(-80, -80);
  c.translate(0, pitchDeg * 2.2);
  c.drawRect(
    const Rect.fromLTWH(-80, -120, 320, 200),
    Paint()..shader = _lin(const Offset(0, -120), const Offset(0, 80), [rgba(0x1F6C9E), rgba(0x63B8E8)]),
  );
  c.drawRect(
    const Rect.fromLTWH(-80, 80, 320, 200),
    Paint()..shader = _lin(const Offset(0, 80), const Offset(0, 280), [rgba(0xB07A3E), rgba(0x4E3219)]),
  );
  c.drawLine(const Offset(-80, 80), const Offset(240, 80), _line(Colors.white, 1.6));
  for (final p in const [-20, -10, 10, 20]) {
    final y = 80 - p * 2.2;
    final w = p.abs() == 10 ? 22.0 : 30.0;
    c.drawLine(Offset(80 - w / 2, y), Offset(80 + w / 2, y), _line(Colors.white, 1.3));
    drawText(c, '${p.abs()}', Offset(80 - w / 2 - 3, y), size: 8, align: TextAlign.right);
    drawText(c, '${p.abs()}', Offset(80 + w / 2 + 3, y), size: 8, align: TextAlign.left);
  }
  for (final p in const [-15, -5, 5, 15]) {
    final y = 80 - p * 2.2;
    c.drawLine(Offset(72, y), Offset(88, y), _line(rgba(0xFFFFFF, .8), 1));
  }
  c.restore();

  c.save();
  c.translate(80, 80);
  c.rotate(r);
  c.translate(-80, -80);
  for (final a in const [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]) {
    final big = a == 0 || a.abs() >= 30;
    final len = big ? 9.0 : 5.0;
    final sa = math.sin(_rad(a.toDouble()));
    final ca = -math.cos(_rad(a.toDouble()));
    c.drawLine(Offset(80 + 66 * sa, 80 + 66 * ca), Offset(80 + (66 - len) * sa, 80 + (66 - len) * ca),
        _line(C.text, 1.3));
  }
  c.drawPath(
    Path()
      ..moveTo(80, 14)
      ..lineTo(75, 6)
      ..lineTo(85, 6)
      ..close(),
    _fill(C.amber),
  );
  c.restore();
  c.restore();

  c.drawPath(
    Path()
      ..moveTo(80, 12)
      ..lineTo(76, 4)
      ..lineTo(84, 4)
      ..close(),
    _fill(C.text),
  );
  final wing = _line(C.amber, 3.2)..strokeJoin = StrokeJoin.round;
  c.drawPath(
    Path()
      ..moveTo(36, 82)
      ..lineTo(64, 82)
      ..lineTo(72, 90),
    wing,
  );
  c.drawPath(
    Path()
      ..moveTo(124, 82)
      ..lineTo(96, 82)
      ..lineTo(88, 90),
    wing,
  );
  c.drawCircle(const Offset(80, 82), 2.6, _fill(C.amber));
  _glass(c);
}

class HorizonPainter extends CustomPainter {
  HorizonPainter(this.roll, this.pitch);
  final double roll;
  final double pitch;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 160, s.height / 160);
    paintHorizon(c, roll, pitch);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant HorizonPainter o) => o.roll != roll || o.pitch != pitch;
}

// ───────────────────────── irtifa şeridi (kompakt, 100x160) ─────────────────────────

class AltTapePainter extends CustomPainter {
  AltTapePainter(this.value);
  final double value;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 160);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 6, 80, 148), const Radius.circular(4)), _fill(rgba(0x3C565E)));
    final face = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 8, 76, 144), const Radius.circular(3));
    c.drawRRect(face, Paint()..shader = _lin(const Offset(12, 0), const Offset(88, 0), [rgba(0x0A1417), rgba(0x16282D)]));
    c.save();
    c.clipRRect(face);
    for (int v = 20; v <= 55; v++) {
      final y = 80 + (value - v) * 3.6;
      if (v % 5 == 0) {
        c.drawLine(Offset(30, y), Offset(v % 10 == 0 ? 44 : 38, y), _line(rgba(0x9FB4BA), 1.2));
        if (v % 10 == 0) drawText(c, '$v', Offset(26, y), size: 10, color: rgba(0xC8D6DA), align: TextAlign.right);
      } else {
        c.drawLine(Offset(30, y), Offset(34, y), _line(rgba(0x5B7B84), 1));
      }
    }
    c.drawRect(
      const Rect.fromLTWH(12, 8, 76, 144),
      Paint()
        ..shader = _lin(const Offset(0, 8), const Offset(0, 152), [
          rgba(0x0A1214),
          rgba(0x0A1214, 0),
          rgba(0x0A1214, 0),
          rgba(0x0A1214)
        ], const [
          0,
          .25,
          .75,
          1
        ]),
    );
    c.drawLine(const Offset(12, 80), const Offset(88, 80), _line(rgba(0x3FD97F, .25), 1));
    c.restore();
    final p = Path()
      ..moveTo(50, 70)
      ..lineTo(84, 70)
      ..lineTo(84, 90)
      ..lineTo(50, 90)
      ..lineTo(44, 80)
      ..close();
    c.drawPath(p, _fill(rgba(0x050B0D)));
    c.drawPath(p, _line(C.green, 1.2));
    drawText(c, value.toStringAsFixed(1), const Offset(68, 80), size: 12, color: C.green, w: FontWeight.w700);
    drawText(c, 'ALT m', const Offset(48, 17), size: 8, color: rgba(0x7F989E), ls: .8);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant AltTapePainter o) => o.value != value;
}

// ───────────────────────── Tek İHA büyük ufuk paneli (440x404) ─────────────────────────

class BigAttitudePainter extends CustomPainter {
  BigAttitudePainter({this.roll = -2.1, this.pitch = 1.4, this.heading = 112});
  final double roll;
  final double pitch;
  final double heading;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    _meetTo(c, size, 440, 404);

    // ufuk
    c.save();
    c.translate(116, 34);
    c.scale(1.9);
    paintHorizon(c, roll, pitch);
    c.restore();

    // sol: irtifa şeridi
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 56, 68, 268), const Radius.circular(4)), _fill(rgba(0x3C565E)));
    final face = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 58, 64, 264), const Radius.circular(3));
    c.drawRRect(face, _fill(rgba(0x0A1417)));
    c.save();
    c.clipRRect(face);
    const vals = [150, 100, 50, 0, -50, -100];
    for (int k = 0; k < vals.length; k++) {
      final y = 80.0 + k * 40;
      c.drawLine(Offset(44, y), Offset(58, y), _line(rgba(0xC8D6D9), 1.4));
      drawText(c, '${vals[k]}', Offset(38, y), size: 12, color: rgba(0xC8D6D9), align: TextAlign.right);
      if (k < vals.length - 1) {
        for (int j = 1; j < 5; j++) {
          c.drawLine(Offset(44, y + j * 8), Offset(51, y + j * 8), _line(rgba(0x5B7B84), 1));
        }
      }
    }
    c.drawRect(
      const Rect.fromLTWH(8, 58, 64, 264),
      Paint()
        ..shader = _lin(const Offset(0, 58), const Offset(0, 322), [
          rgba(0x0A1417),
          rgba(0x0A1417, 0),
          rgba(0x0A1417, 0),
          rgba(0x0A1417)
        ], const [
          0,
          .22,
          .78,
          1
        ]),
    );
    c.restore();
    c.drawLine(const Offset(8, 200), const Offset(72, 200), _line(rgba(0x3FD97F, .3), 1));
    final marker = Path()
      ..moveTo(40, 190)
      ..lineTo(70, 190)
      ..lineTo(70, 210)
      ..lineTo(40, 210)
      ..lineTo(34, 200)
      ..close();
    c.drawPath(marker, _fill(rgba(0x050B0D)));
    c.drawPath(marker, _line(C.green, 1.4));
    drawText(c, '0', const Offset(55, 200), size: 13, color: C.green, w: FontWeight.w700);
    drawText(c, 'ALT m', const Offset(40, 66), size: 8, color: rgba(0x7F989E), ls: 1.2);

    // alt: yön şeridi (ufukla aynı eksende)
    const cx = 268.0;
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(142, 352, 252, 44), const Radius.circular(4)), _fill(rgba(0x3C565E)));
    final hf = RRect.fromRectAndRadius(const Rect.fromLTWH(144, 354, 248, 40), const Radius.circular(3));
    c.drawRRect(hf, _fill(rgba(0x0A1417)));
    c.save();
    c.clipRRect(hf);
    for (int d = heading.round() - 16; d <= heading.round() + 16; d++) {
      final x = cx + (d - heading) * 9;
      final big = d % 5 == 0;
      c.drawLine(Offset(x, 362), Offset(x, big ? 372 : 368), _line(big ? C.text : rgba(0x5B7B84), 1.3));
      if (big) drawText(c, '${(d + 360) % 360}', Offset(x, 385), size: 12, color: rgba(0xC8D6D9));
    }
    c.drawRect(
      const Rect.fromLTWH(144, 354, 248, 40),
      Paint()
        ..shader = _lin(const Offset(144, 0), const Offset(392, 0), [
          rgba(0x0A1417),
          rgba(0x0A1417, 0),
          rgba(0x0A1417, 0),
          rgba(0x0A1417)
        ], const [
          0,
          .2,
          .8,
          1
        ]),
    );
    c.restore();
    c.drawLine(const Offset(cx, 354), const Offset(cx, 362), _line(C.green, 2));
    final hb = RRect.fromRectAndRadius(const Rect.fromLTWH(cx - 25, 357, 50, 19), const Radius.circular(2));
    c.drawRRect(hb, _fill(rgba(0x050B0D)));
    c.drawRRect(hb, _line(C.green, 1.2));
    drawText(c, '${heading.round()}°', const Offset(cx, 366.5), size: 13, color: C.green, w: FontWeight.w700);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant BigAttitudePainter o) => o.roll != roll || o.pitch != pitch || o.heading != heading;
}

// ───────────────────────── 3B joystick (200x200) ─────────────────────────

class JoystickPainter extends CustomPainter {
  JoystickPainter(this.dx, this.dy);
  final double dx;
  final double dy;

  Path _poly(List<double> pts) {
    final p = Path()..moveTo(pts[0], pts[1]);
    for (int i = 2; i < pts.length; i += 2) {
      p.lineTo(pts[i], pts[i + 1]);
    }
    return p..close();
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 200, size.height / 200);

    final base = _poly(const [52, 28, 148, 28, 176, 56, 176, 152, 148, 180, 52, 180, 24, 152, 24, 56]);
    c.drawPath(
      base,
      Paint()..shader = _lin(const Offset(0, 28), const Offset(0, 180), [rgba(0x3A5760), rgba(0x1F353B), rgba(0x0C1618)], const [0, .5, 1]),
    );
    c.drawPath(base, _line(rgba(0x4E7580), 1.5));
    c.drawPath(_poly(const [58, 36, 142, 36, 168, 60, 168, 148, 142, 172, 58, 172, 32, 148, 32, 60]), _line(rgba(0x0A1214, .8), 2));

    final recess = RRect.fromRectAndRadius(const Rect.fromLTWH(46, 58, 108, 108), const Radius.circular(14));
    c.drawRRect(recess, Paint()..shader = _lin(const Offset(46, 58), const Offset(154, 166), [rgba(0x050B0D), rgba(0x16282D)]));
    c.drawRRect(recess, _line(rgba(0x0A1214), 2));
    c.drawRRect(recess, _line(rgba(0x2F4F58, .9), 1));

    final railV = RRect.fromRectAndRadius(const Rect.fromLTWH(90, 62, 20, 100), const Radius.circular(10));
    final railH = RRect.fromRectAndRadius(const Rect.fromLTWH(50, 102, 100, 20), const Radius.circular(10));
    for (final r in [railV, railH]) {
      c.drawRRect(r, _fill(rgba(0x070F11)));
      c.drawRRect(r, _line(rgba(0x27424A), 1));
    }
    final g = _line(rgba(0x3FD97F, .55), 1.3);
    c.drawLine(const Offset(62, 112), const Offset(67, 112), g);
    c.drawLine(const Offset(133, 112), const Offset(138, 112), g);
    c.drawLine(const Offset(100, 74), const Offset(100, 79), g);
    c.drawLine(const Offset(100, 145), const Offset(100, 150), g);

    final tick = _line(rgba(0x5B7B84), 1.2);
    for (final x in const [70.0, 85.0, 100.0, 115.0, 130.0]) {
      final l = x == 100 ? 8.0 : 6.0;
      c.drawLine(Offset(x, 40), Offset(x, 40 + l), tick);
      c.drawLine(Offset(x, 170), Offset(x, 170 - l), tick);
    }
    drawText(c, '▲', const Offset(100, 19), size: 9, color: rgba(0x7F9AA1), w: FontWeight.w700);
    drawText(c, '▼', const Offset(100, 193), size: 9, color: rgba(0x7F9AA1), w: FontWeight.w700);

    // tutamak
    final sx = 100 + dx;
    final sy = 112 + dy;
    final bx = sx;
    final by = sy - 34;
    c.save();
    c.translate(sx + 6, sy + 8);
    c.scale(1, .45);
    c.drawCircle(Offset.zero, 20, Paint()..shader = ui.Gradient.radial(Offset.zero, 20, [rgba(0x000000, .55), rgba(0x000000, 0)]));
    c.restore();
    c.drawCircle(Offset(sx, sy), 13, _fill(rgba(0x0A1214)));
    c.drawCircle(Offset(sx, sy), 13, _line(rgba(0x3A5760), 1));
    final shaft = Path()
      ..moveTo(sx - 7, sy)
      ..lineTo(sx + 7, sy)
      ..lineTo(bx + 5, by + 6)
      ..lineTo(bx - 5, by + 6)
      ..close();
    c.drawPath(
      shaft,
      Paint()..shader = _lin(Offset(sx - 7, 0), Offset(sx + 7, 0), [rgba(0x4A5C62), rgba(0xC9D6DA), rgba(0x3A494E)], const [0, .45, 1]),
    );
    c.drawCircle(Offset(bx + 2, by + 3), 22, _fill(rgba(0x000000, .25)));
    c.drawCircle(
      Offset(bx, by),
      22,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(bx - 6.6, by - 8.8),
          35.2,
          [rgba(0xE6FFF0), rgba(0x5FF0A0), rgba(0x1E9A55), rgba(0x0A4023)],
          const [0, .25, .7, 1],
        ),
    );
    c.drawCircle(Offset(bx, by), 22, _line(rgba(0x0A4023), 1.5));
    c.save();
    c.translate(bx - 7, by - 10);
    c.rotate(_rad(-25));
    c.drawOval(const Rect.fromLTWH(-7, -4, 14, 8), _fill(rgba(0xFFFFFF, .6)));
    c.restore();
    c.restore();
  }

  @override
  bool shouldRepaint(covariant JoystickPainter o) => o.dx != dx || o.dy != dy;
}

// ───────────────────────── Kontrol haritası (900x520) ─────────────────────────

class MapPainter extends CustomPainter {
  void _chip(Canvas c, String t, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 11, color: rgba(0xC8D6D9), letterSpacing: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: tp.width + 20, height: 22), const Radius.circular(2));
    c.drawRRect(r, Paint()..shader = _lin(r.outerRect.topCenter, r.outerRect.bottomCenter, [rgba(0x264047), rgba(0x1A2D32)]));
    c.drawRRect(r, _line(rgba(0x3B5258), 1));
    tp.paint(c, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    _sliceTo(c, s, 900, 520);
    c.drawRect(const Rect.fromLTWH(0, 0, 900, 520), _fill(rgba(0x0A1417)));
    final grid = _line(rgba(0x101E22), 1);
    for (double x = 0; x <= 900; x += 45) {
      c.drawLine(Offset(x, 0), Offset(x, 520), grid);
    }
    for (double y = 0; y <= 520; y += 45) {
      c.drawLine(Offset(0, y), Offset(900, y), grid);
    }
    c.drawPath(
      Path()
        ..moveTo(430, 110)
        ..lineTo(575, 80)
        ..lineTo(610, 330)
        ..lineTo(450, 365)
        ..close(),
      _fill(rgba(0x2A6B4C, .2)),
    );
    c.drawPath(
      Path()
        ..moveTo(215, 440)
        ..lineTo(655, 372)
        ..lineTo(735, 175),
      _line(rgba(0x3B5258), 2.5),
    );
    final route = _line(rgba(0x3FD97F, .75), 2.5);
    c.drawPath(
      Path()
        ..moveTo(240, 175)
        ..lineTo(400, 255)
        ..lineTo(490, 345),
      route,
    );
    c.drawPath(
      Path()
        ..moveTo(490, 345)
        ..lineTo(555, 240)
        ..lineTo(735, 175),
      route,
    );
    c.drawLine(const Offset(215, 440), const Offset(478, 228), _line(rgba(0x6C8A8F), 2.5));

    // QR kutusu
    final qr = RRect.fromRectAndRadius(const Rect.fromLTWH(385, 238, 32, 32), const Radius.circular(5));
    c.drawRRect(qr, _fill(rgba(0xC8D6D9)));
    c.drawRRect(qr, _line(rgba(0x0A1417), 2));
    final dark = _fill(rgba(0x0A1417));
    for (final r in const [
      Rect.fromLTWH(391, 244, 8, 8),
      Rect.fromLTWH(403, 244, 8, 8),
      Rect.fromLTWH(391, 256, 8, 8),
      Rect.fromLTWH(404, 257, 6, 6),
    ]) {
      c.drawRect(r, dark);
    }

    drawPlane(c, const Offset(478, 228), -35, 48, rgba(0xCDBB9B));
    drawPlane(c, const Offset(555, 242), 42, 52, C.green);
    drawPlane(c, const Offset(492, 348), 20, 52, C.red);
    drawText(c, 'İHA-1', const Offset(528, 210), size: 13, w: FontWeight.w600);
    drawText(c, 'İHA-2', const Offset(600, 258), size: 13, w: FontWeight.w600);
    drawText(c, 'İHA-3', const Offset(540, 368), size: 13, w: FontWeight.w600, color: rgba(0xFF8480));

    _chip(c, 'WP-01', const Offset(240, 175));
    _chip(c, 'WP-03', const Offset(735, 175));
    _chip(c, 'WP-02', const Offset(655, 372));
    _chip(c, 'WP-00', const Offset(215, 440));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ───────────────────────── Yarı otonom haritası (900x460) ─────────────────────────

class FormationMapPainter extends CustomPainter {
  void _chip(Canvas c, String t, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 11, color: rgba(0xC8D6D9), letterSpacing: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: tp.width + 20, height: 22), const Radius.circular(2));
    c.drawRRect(r, Paint()..shader = _lin(r.outerRect.topCenter, r.outerRect.bottomCenter, [rgba(0x264047), rgba(0x1A2D32)]));
    c.drawRRect(r, _line(rgba(0x3B5258), 1));
    tp.paint(c, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p) {
    final len = (b - a).distance;
    final dir = (b - a) / len;
    double d = 0;
    while (d < len) {
      final e = math.min(d + 7, len);
      c.drawLine(a + dir * d, a + dir * e, p);
      d += 13;
    }
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    _sliceTo(c, s, 900, 460);
    c.drawRect(const Rect.fromLTWH(0, 0, 900, 460), _fill(rgba(0x0A1417)));
    final grid = _line(rgba(0x101E22), 1);
    for (double x = 0; x <= 900; x += 45) {
      c.drawLine(Offset(x, 0), Offset(x, 460), grid);
    }
    for (double y = 0; y <= 460; y += 45) {
      c.drawLine(Offset(0, y), Offset(900, y), grid);
    }
    c.drawPath(
      Path()
        ..moveTo(430, 100)
        ..lineTo(575, 70)
        ..lineTo(610, 300)
        ..lineTo(450, 335)
        ..close(),
      _fill(rgba(0x2A6B4C, .18)),
    );
    final dash = _line(rgba(0x4DB2FF, .8), 2.5);
    _dashed(c, const Offset(270, 150), const Offset(470, 330), dash);
    _dashed(c, const Offset(470, 330), const Offset(650, 150), dash);
    drawPlane(c, const Offset(270, 150), 30, 56, C.green);
    drawPlane(c, const Offset(470, 330), 30, 56, C.green);
    drawPlane(c, const Offset(650, 150), 30, 56, C.green);
    c.drawCircle(const Offset(470, 215), 14, _line(C.text, 2));
    c.drawLine(const Offset(458, 215), const Offset(482, 215), _line(C.text, 2));
    c.drawLine(const Offset(470, 203), const Offset(470, 227), _line(C.text, 2));
    drawText(c, 'İHA-1', const Offset(318, 136), size: 13, w: FontWeight.w600);
    drawText(c, 'İHA-2', const Offset(518, 344), size: 13, w: FontWeight.w600);
    drawText(c, 'İHA-3', const Offset(698, 136), size: 13, w: FontWeight.w600);
    drawText(c, 'Merkez', const Offset(515, 201), size: 13, color: C.mut2, w: FontWeight.w600);
    _chip(c, 'WP-01', const Offset(85, 360));
    _chip(c, 'WP-03', const Offset(740, 118));
    _chip(c, 'WP-02', const Offset(660, 296));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class RadarPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 84, s.height / 84);
    c.drawCircle(const Offset(42, 42), 38, _fill(rgba(0x0A1417)));
    c.drawCircle(const Offset(42, 42), 38, _line(C.green, 2));
    c.drawCircle(const Offset(42, 42), 22, _line(rgba(0x27424A), 1));
    c.drawPath(
      Path()
        ..moveTo(42, 42)
        ..lineTo(42, 8)
        ..arcToPoint(const Offset(66, 18), radius: const Radius.circular(34))
        ..close(),
      _fill(rgba(0x3FD97F, .35)),
    );
    drawText(c, 'RADAR', const Offset(42, 42), size: 11, color: C.green, w: FontWeight.w700);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class FormationIconPainter extends CustomPainter {
  FormationIconPainter(this.kind, {this.color = C.green});
  final int kind; // 0 V, 1 ok, 2 çizgi
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 58, s.height / 38);
    final l = _line(color, 2);
    final f = _fill(color);
    if (kind == 0) {
      c.drawPath(
        Path()
          ..moveTo(8, 6)
          ..lineTo(29, 30)
          ..lineTo(50, 6),
        l,
      );
      for (final o in const [Offset(8, 6), Offset(29, 30), Offset(50, 6)]) {
        c.drawCircle(o, 4.5, f);
      }
    } else if (kind == 1) {
      c.drawLine(const Offset(8, 19), const Offset(46, 19), l);
      c.drawLine(const Offset(46, 19), const Offset(34, 8), l);
      c.drawLine(const Offset(46, 19), const Offset(34, 30), l);
      for (final o in const [Offset(8, 19), Offset(34, 8), Offset(34, 30)]) {
        c.drawCircle(o, 4.5, f);
      }
    } else {
      c.drawLine(const Offset(8, 19), const Offset(50, 19), l);
      for (final o in const [Offset(8, 19), Offset(29, 19), Offset(50, 19)]) {
        c.drawCircle(o, 4.5, f);
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant FormationIconPainter o) => o.kind != kind || o.color != color;
}

// ───────────────────────── kamera görüntüleri (örnek) ─────────────────────────

class TerrainPainter extends CustomPainter {
  TerrainPainter({this.planePos, this.planeRot = 0, this.planeSize = 80});
  final Offset? planePos;
  final double planeRot;
  final double planeSize;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    _sliceTo(c, s, 640, 360);
    c.drawRect(const Rect.fromLTWH(0, 0, 640, 360), _fill(rgba(0x6E6A48)));
    Path poly(List<double> p) {
      final path = Path()..moveTo(p[0], p[1]);
      for (int i = 2; i < p.length; i += 2) {
        path.lineTo(p[i], p[i + 1]);
      }
      return path..close();
    }

    c.drawPath(poly(const [0, 0, 250, 0, 180, 140, 0, 190]), _fill(rgba(0x7B7652)));
    c.drawPath(poly(const [250, 0, 640, 0, 640, 120, 420, 150, 180, 140]), _fill(rgba(0x5E6844)));
    c.drawPath(poly(const [0, 190, 180, 140, 420, 150, 330, 360, 0, 360]), _fill(rgba(0x827B55)));
    c.drawPath(poly(const [420, 150, 640, 120, 640, 360, 330, 360]), _fill(rgba(0x66684A)));
    c.drawPath(
      Path()
        ..moveTo(-10, 300)
        ..cubicTo(150, 230, 260, 190, 360, 120)
        ..cubicTo(460, 50, 560, 20, 660, -10),
      _line(rgba(0xCBBE9A, .75), 9),
    );
    c.drawPath(
      Path()
        ..moveTo(180, 360)
        ..cubicTo(230, 280, 300, 250, 330, 190),
      _line(rgba(0xCBBE9A, .6), 6),
    );
    c.drawRect(const Rect.fromLTWH(600, 0, 40, 360), _fill(rgba(0x8F9696)));
    final tree = _fill(rgba(0x3E5A34, .8));
    for (final t in const [
      [520.0, 210.0, 16.0],
      [548.0, 236.0, 13.0],
      [500.0, 248.0, 11.0],
      [90.0, 70.0, 13.0],
      [116.0, 92.0, 10.0]
    ]) {
      c.drawCircle(Offset(t[0], t[1]), t[2], tree);
    }
    if (planePos != null) drawPlane(c, planePos!, planeRot, planeSize, rgba(0x3C5C78));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant TerrainPainter o) => false;
}

class RunwayPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    _sliceTo(c, s, 640, 360);
    c.drawRect(const Rect.fromLTWH(0, 0, 640, 360),
        Paint()..shader = _lin(const Offset(0, 0), const Offset(0, 360), [rgba(0x7C93A1), rgba(0xB9C6CC)]));
    c.drawRect(const Rect.fromLTWH(0, 150, 640, 210), _fill(rgba(0x5C6350)));
    c.drawPath(
      Path()
        ..moveTo(285, 150)
        ..lineTo(355, 150)
        ..lineTo(560, 360)
        ..lineTo(80, 360)
        ..close(),
      _fill(rgba(0x53575A)),
    );
    final dash = _line(rgba(0xD8D8D0, .7), 3);
    for (double y = 156; y < 360; y += 26) {
      c.drawLine(Offset(320, y), Offset(320, math.min(y + 14, 360)), dash);
    }
    drawPlane(c, const Offset(320, 255), 0, 100, rgba(0x3C5C78));
    final b = _line(C.green, 3);
    for (final o in const [
      [240.0, 195.0, 1.0, 1.0],
      [400.0, 195.0, -1.0, 1.0],
      [240.0, 305.0, 1.0, -1.0],
      [400.0, 305.0, -1.0, -1.0]
    ]) {
      c.drawLine(Offset(o[0], o[1]), Offset(o[0] + 22 * o[2], o[1]), b);
      c.drawLine(Offset(o[0], o[1]), Offset(o[0], o[1] + 22 * o[3]), b);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class QrCameraPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    _sliceTo(c, s, 800, 450);
    c.drawRect(const Rect.fromLTWH(0, 0, 800, 450), _fill(rgba(0x17302B)));
    c.drawRect(const Rect.fromLTWH(0, 0, 800, 170), _fill(rgba(0x1F3F46)));
    c.drawPath(
      Path()
        ..moveTo(0, 170)
        ..lineTo(140, 120)
        ..lineTo(260, 165)
        ..lineTo(420, 100)
        ..lineTo(560, 160)
        ..lineTo(700, 120)
        ..lineTo(800, 150)
        ..lineTo(800, 450)
        ..lineTo(0, 450)
        ..close(),
      _fill(rgba(0x244B3C)),
    );
    c.drawPath(
      Path()
        ..moveTo(0, 300)
        ..quadraticBezierTo(200, 250, 400, 290)
        ..quadraticBezierTo(600, 330, 800, 270)
        ..lineTo(800, 450)
        ..lineTo(0, 450)
        ..close(),
      _fill(rgba(0x1C3A2F)),
    );
    c.drawRect(const Rect.fromLTWH(330, 215, 140, 140), _fill(rgba(0xE8EEF0, .92)));
    final k = _fill(rgba(0x0A1214));
    for (final r in const [
      Rect.fromLTWH(345, 230, 40, 40),
      Rect.fromLTWH(415, 230, 40, 40),
      Rect.fromLTWH(345, 300, 40, 40),
      Rect.fromLTWH(395, 250, 14, 14),
      Rect.fromLTWH(415, 300, 14, 14),
      Rect.fromLTWH(437, 322, 18, 18),
      Rect.fromLTWH(395, 285, 14, 14),
    ]) {
      c.drawRect(r, k);
    }
    c.drawRect(const Rect.fromLTWH(322, 207, 156, 156), _line(C.green, 3));
    final b = _line(C.green, 6);
    c.drawPath(
      Path()
        ..moveTo(322, 235)
        ..lineTo(322, 207)
        ..lineTo(350, 207)
        ..moveTo(450, 207)
        ..lineTo(478, 207)
        ..lineTo(478, 235)
        ..moveTo(478, 335)
        ..lineTo(478, 363)
        ..lineTo(450, 363)
        ..moveTo(350, 363)
        ..lineTo(322, 363)
        ..lineTo(322, 335),
      b,
    );
    final x = _line(rgba(0xE8EEF0, .5), 1);
    c.drawLine(const Offset(400, 150), const Offset(400, 300), x);
    c.drawLine(const Offset(325, 225), const Offset(475, 225), x);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class ThumbPainter extends CustomPainter {
  ThumbPainter(this.variant);
  final int variant;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _fill(rgba(0x17302B)));
    final skyH = s.height * (.38 + variant * .06);
    c.drawRect(Rect.fromLTWH(0, 0, s.width, skyH), _fill(rgba(0x1F3F46)));
    final p = Path()
      ..moveTo(0, s.height * (.68 + variant * .04))
      ..quadraticBezierTo(s.width * .35, s.height * .48, s.width * .62, s.height * .66)
      ..quadraticBezierTo(s.width * .85, s.height * .74, s.width, s.height * .6)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p, _fill(variant == 1 ? rgba(0x1C3A2F) : rgba(0x244B3C)));
  }

  @override
  bool shouldRepaint(covariant ThumbPainter o) => o.variant != variant;
}

class QrTilePainter extends CustomPainter {
  QrTilePainter({this.dim = false});
  final bool dim;
  @override
  void paint(Canvas c, Size s) {
    final bg = dim ? rgba(0xE8EEF0, .3) : rgba(0xE8EEF0, .92);
    c.drawRect(Offset.zero & s, _fill(bg));
    final k = _fill(rgba(0x0A1214, dim ? .35 : .95));
    final u = s.width / 6;
    for (int y = 0; y < 6; y++) {
      for (int x = 0; x < 6; x++) {
        final on = ((x * 7 + y * 3 + x * y) % 3) != 0 || (x < 2 && y < 2);
        if (on) c.drawRect(Rect.fromLTWH(x * u, y * u, u * .85, u * .85), k);
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrTilePainter o) => o.dim != dim;
}

// ───────────────────────── Telemetri grafiği (560x290 koordinat sistemi) ─────────────────────────

class ChartLine {
  const ChartLine(this.color, this.pts);
  final Color color;
  final List<Offset> pts;
}

class ChartThreshold {
  const ChartThreshold(this.y, this.color, this.label, {this.labelAbove = true});
  final double y;
  final Color color;
  final String label;
  final bool labelAbove;
}

class LineChartPainter extends CustomPainter {
  LineChartPainter({
    required this.yLabels,
    required this.lines,
    this.thresholds = const [],
    this.xLabels = const ['08:00', '10:00', '12:00', '14:00', '16:00'],
  });

  final List<String> yLabels; // 6 adet, yukarıdan aşağıya
  final List<ChartLine> lines;
  final List<ChartThreshold> thresholds;
  final List<String> xLabels;

  @override
  void paint(Canvas c, Size s) {
    final kx = s.width / 560;
    final ky = s.height / 290;
    Offset p(double x, double y) => Offset(x * kx, y * ky);

    final grid = _line(rgba(0x243A40), 1);
    for (int i = 0; i < 6; i++) {
      final y = 40.0 + i * 42;
      c.drawLine(p(60, y), p(540, y), grid);
      drawText(c, yLabels[i], p(52, y), size: 11, color: C.mut2, align: TextAlign.right);
    }
    const xs = [60.0, 180.0, 300.0, 420.0, 530.0];
    for (int i = 0; i < xs.length && i < xLabels.length; i++) {
      drawText(c, xLabels[i], p(xs[i], 270), size: 11, color: C.mut2);
    }
    for (final t in thresholds) {
      final paint = _line(t.color, 1.6);
      double x = 60;
      while (x < 540) {
        c.drawLine(p(x, t.y), p(math.min(x + 7, 540), t.y), paint);
        x += 12;
      }
      drawText(c, t.label, p(536, t.y + (t.labelAbove ? -9 : 9)), size: 10.5, color: t.color, align: TextAlign.right);
    }
    for (final l in lines) {
      final path = Path()..moveTo(l.pts.first.dx * kx, l.pts.first.dy * ky);
      for (int i = 1; i < l.pts.length; i++) {
        path.lineTo(l.pts[i].dx * kx, l.pts[i].dy * ky);
      }
      c.drawPath(
        path,
        _line(l.color, 2.4)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
