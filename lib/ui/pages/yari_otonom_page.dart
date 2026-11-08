import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// YARI OTONOM – Mission Planner tarzı harita.
/// 1) İHA'ya tıkla  2) Haritada sağ tık (dokunmatikte uzun bas)  3) "Buraya Uç".
/// Hedef verilen İHA animasyonla hedefe gider; mesafe ve yön üstteki kutuda görünür.
class YariOtonomPage extends StatefulWidget {
  const YariOtonomPage({super.key});

  @override
  State<YariOtonomPage> createState() => _YariOtonomPageState();
}

class _YariOtonomPageState extends State<YariOtonomPage> with SingleTickerProviderStateMixin {
  static const _w = 1000.0, _h = 345.0;
  static const _home = Offset(70, 205);
  static const _mPerUnit = .44;

  final List<Offset> _pos = [const Offset(330, 110), const Offset(470, 255), const Offset(610, 110)];
  final List<double> _hdg = [120, 30, 30];
  final List<Offset?> _target = [null, null, null];
  int _sel = 0;
  Offset? _menuAt; // ekran konumu
  Offset? _menuWorld; // harita koordinatı
  double _zoom = 1;
  String _toast = '';
  double _toastT = 0;
  Offset _cursor = const Offset(500, 172);

  int _form = 0;
  final List<double> _par = [10, 10, 1.0, 1.0]; // yaw hızı, yaw ivmesi, hız, ivme

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration el) {
    final dt = ((el - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = el;
    _t += dt;
    for (int i = 0; i < 3; i++) {
      final tg = _target[i];
      if (tg == null) continue;
      final d = tg - _pos[i];
      final dist = d.distance;
      if (dist < 3) {
        _target[i] = null;
        _say('İHA-${i + 1} hedefe ulaştı');
        continue;
      }
      _hdg[i] = math.atan2(d.dx, -d.dy) * 180 / math.pi;
      _pos[i] += d / dist * math.min(dist, 55 * dt);
    }
    if (_toastT > 0) _toastT -= dt;
    if (mounted) setState(() {});
  }

  void _say(String t) {
    _toast = t;
    _toastT = 3;
  }

  // ───── koordinat dönüşümü ─────
  double _k(Size s) => math.max(s.width / _w, s.height / _h) * _zoom;
  Offset _toWorld(Offset p, Size s) => (p - Offset(s.width / 2, s.height / 2)) / _k(s) + const Offset(_w / 2, _h / 2);

  int _hit(Offset w) {
    for (int i = 0; i < 3; i++) {
      if ((w - _pos[i]).distance < 34) return i;
    }
    return -1;
  }

  void _openMenu(Offset local, Size s) {
    setState(() {
      _menuAt = local;
      _menuWorld = _toWorld(local, s);
    });
  }

  void _menuAction(String a) {
    final w = _menuWorld!;
    setState(() {
      _menuAt = null;
      switch (a) {
        case 'fly':
        case 'flyalt':
          _target[_sel] = w;
          _say('İHA-${_sel + 1}: ${a == 'fly' ? 'Buraya Uç' : 'İrtifa ile Buraya Uç (40 m)'} → hedef ayarlandı');
          break;
        case 'takeoff':
          _say('İHA-${_sel + 1}: Kalkış komutu gönderildi (TakeOff 30 m)');
          break;
        case 'home':
          _say('Ev noktası bu konuma alındı (Set Home Here)');
          break;
      }
    });
  }

  String _dist(Offset a, Offset b) => '${((a - b).distance * _mPerUnit).round()} m';

  Widget _chip(Widget c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: rgba(0x0C171A, .88),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF3B5258)),
        ),
        child: c,
      );

  Widget _step(String n, String t, bool done, {String? bold}) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done ? C.green : C.amber),
            child: Text(done ? '✓' : n, style: ts(11, color: C.dark, w: FontWeight.w800)),
          ),
          gap(6),
          Text(t, style: ts(12, color: done ? C.text : C.amber)),
          if (bold != null) Text(bold, style: ts(12, color: C.blue, w: FontWeight.w700)),
        ]),
      );

  Widget _zb(String t, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rgba(0x0C171A, .88),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF3B5258)),
          ),
          child: Text(t, style: ts(16)),
        ),
      );

  Widget _map() {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final tg = _target[_sel];
      final p = _pos[_sel];
      final hasT = tg != null;
      final bearing = hasT ? ((math.atan2(tg.dx - p.dx, -(tg.dy - p.dy)) * 180 / math.pi) + 360) % 360 : 0.0;
      return KeepDark(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: MouseRegion(
            onHover: (e) => _cursor = _toWorld(e.localPosition, size),
            child: Listener(
              onPointerDown: (e) {
                if (e.buttons == kSecondaryMouseButton) _openMenu(e.localPosition, size);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  final w = _toWorld(d.localPosition, size);
                  final h = _hit(w);
                  setState(() {
                    _menuAt = null;
                    if (h >= 0) _sel = h;
                  });
                },
                onLongPressStart: (d) => _openMenu(d.localPosition, size),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _MapPainter(pos: List.of(_pos), hdg: List.of(_hdg), target: List.of(_target), sel: _sel, zoom: _zoom, t: _t, menuWorld: _menuWorld, showMenuMark: _menuAt != null),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _chip(Row(mainAxisSize: MainAxisSize.min, children: [
                        _step('1', 'İHA seç: ', true, bold: 'İHA-${_sel + 1}'),
                        _step('2', 'Haritada sağ tık', _menuAt != null || hasT),
                        _step('3', 'Buraya Uç', hasT),
                      ])),
                    ),
                    Positioned(
                      left: 12,
                      top: 56,
                      child: _chip(Text.rich(TextSpan(style: ts(11.5), children: [
                        TextSpan(text: 'HOME\'a ', style: ts(11.5, color: C.mut)),
                        TextSpan(text: '${_dist(p, _home)}   '),
                        TextSpan(text: 'Hedefe ', style: ts(11.5, color: C.mut)),
                        TextSpan(text: hasT ? '${bearing.round().toString().padLeft(3, '0')}° / ${_dist(p, tg)}' : '—'),
                      ]))),
                    ),
                    Positioned(
                      left: 12,
                      top: 106,
                      child: Column(children: [
                        _zb('+', () => setState(() => _zoom = math.min(2.5, _zoom + .25))),
                        gap(6),
                        _zb('−', () => setState(() => _zoom = math.max(1, _zoom - .25))),
                        gap(6),
                        _zb('⌖', () => setState(() => _zoom = 1)),
                      ]),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: SizedBox(width: 72, height: 72, child: CustomPaint(painter: RadarPainter())),
                    ),
                    Positioned(
                      right: 96,
                      top: 14,
                      child: Row(children: [
                        for (final t in const ['⟷ Mesafe ölç', '⛰ Arazi profili', '▱ Alan']) ...[
                          GestureDetector(onTap: () => setState(() => _say('$t: yakında')), child: _chip(Text(t, style: ts(11)))),
                          gap(6),
                        ],
                      ]),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _chip(Text.rich(TextSpan(children: [
                        TextSpan(text: 'Lat ${(37.8712 + (_h / 2 - _cursor.dy) * 0.00001).toStringAsFixed(6)}   Lon ${(32.4981 + (_cursor.dx - _w / 2) * 0.00001).toStringAsFixed(6)}   Alt 1021 m (SRTM)   ·   HDOP 1.1   ·   Uydu 11   ·   ', style: ts(11.5, color: const Color(0xFFB9CBCF), mono: true)),
                        TextSpan(text: 'GUIDED', style: ts(11.5, color: C.amber, w: FontWeight.w700, ls: 1)),
                      ]))),
                    ),
                    if (_toastT > 0)
                      Positioned(
                        right: 14,
                        bottom: 12,
                        child: _chip(Text(_toast, style: ts(12, color: C.green, w: FontWeight.w600))),
                      ),
                    if (_menuAt != null)
                      Positioned(
                        left: math.min(_menuAt!.dx, size.width - 250),
                        top: math.min(_menuAt!.dy, size.height - 130),
                        child: Container(
                          width: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C171A),
                            border: Border.all(color: const Color(0xFF3B5258)),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: rgba(0x000000, .5), blurRadius: 14)],
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            _mi('Buraya Uç  (Fly to here)', 'fly', first: true),
                            _mi('İrtifa ile Buraya Uç  (Fly to here Alt)', 'flyalt'),
                            _mi('Kalkış  (TakeOff)', 'takeoff'),
                            _mi('Ev Noktası Yap  (Set Home Here)', 'home'),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _mi(String t, String a, {bool first = false}) => InkWell(
        onTap: () => _menuAction(a),
        child: Container(
          height: 28,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: first ? const Color(0xFF1F4D3A) : null,
            border: first ? null : const Border(top: BorderSide(color: Color(0xFF2A4046))),
          ),
          child: Text(t, style: ts(12.5, w: first ? FontWeight.w700 : FontWeight.w500, color: first ? const Color(0xFFEFFFF6) : const Color(0xFFD5E0E2))),
        ),
      );

  Widget _formTile(int i, String label) {
    final on = _form == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _form = i),
        child: Container(
          margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: on ? const Color(0xFF17402F) : const Color(0xFF18292E),
            border: Border.all(color: on ? C.green : const Color(0xFF33505A), width: on ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 58, height: 38, child: CustomPaint(painter: FormationIconPainter(i, color: on ? C.green : C.text))),
              gap(6),
              Text(label, style: ts(14, color: on ? C.green : C.text)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _param(int i, String label, String unit, double step, double min, double max) {
    final v = _par[i];
    Widget btn(String t, double d) => GestureDetector(
          onTap: () => setState(() => _par[i] = (v + d).clamp(min, max).toDouble()),
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF33505A)), borderRadius: BorderRadius.circular(2)),
            child: Text(t, style: ts(15)),
          ),
        );
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
        decoration: BoxDecoration(color: C.dark, borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0xFF27393F))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: ts(12.5, color: C.mut)),
            gap(4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              btn('−', -step),
              gap(8),
              Text('${v == v.roundToDouble() && step >= 1 ? v.toInt() : v.toStringAsFixed(1)}$unit', style: ts(17, w: FontWeight.w700)),
              gap(8),
              btn('+', step),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'SÜRÜ İHA // YARI OTONOM',
      statusRow: true,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Panel(
                title: 'SÜRÜ KONUMU & HARİTA',
                trailing: const Tag('ARDUPILOT · GUIDED · MAVLINK', fontSize: 11, height: 22),
                child: _map(),
              ),
            ),
            gap(8),
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Panel(
                      title: 'FORMASYON SEÇİCİ',
                      child: Row(children: [_formTile(0, 'V Formasyon'), _formTile(1, 'Ok Formasyon'), _formTile(2, 'Çizgi Formasyon')]),
                    ),
                  ),
                  gap(8),
                  Expanded(
                    child: Panel(
                      title: 'HAREKET PARAMETRELERİ',
                      child: Row(children: [
                        _param(0, 'Yaw Hızı', '°/s', 1, 1, 90),
                        _param(1, 'Yaw İvmesi', '°/s²', 1, 1, 90),
                        _param(2, 'Hız', ' m/s', .5, .5, 20),
                        _param(3, 'İvme', ' m/s²', .5, .5, 10),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.pos, required this.hdg, required this.target, required this.sel, required this.zoom, required this.t, required this.menuWorld, required this.showMenuMark});
  final List<Offset> pos;
  final List<double> hdg;
  final List<Offset?> target;
  final int sel;
  final double zoom;
  final double t;
  final Offset? menuWorld;
  final bool showMenuMark;

  Paint _f(Color c) => Paint()..color = c;
  Paint _s(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _poly(Canvas c, List<double> pts, Color col) {
    final p = Path()..moveTo(pts[0], pts[1]);
    for (int i = 2; i < pts.length; i += 2) {
      p.lineTo(pts[i], pts[i + 1]);
    }
    p.close();
    c.drawPath(p, _f(col));
  }

  void _label(Canvas c, String t, Offset at, {Color color = Colors.white, double size = 12.5, bool bg = true}) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
    if (bg) c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, tp.width + 14, 20), const Radius.circular(2)), _f(rgba(0x050B0D, .85)));
    tp.paint(c, Offset(at.dx + (bg ? 7 : 0), at.dy + (bg ? 3 : 0)));
  }

  @override
  void paint(Canvas c, Size s) {
    const w = 1000.0, h = 345.0;
    final k = math.max(s.width / w, s.height / h) * zoom;
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale(k);
    c.translate(-w / 2, -h / 2);
    // arazi (640x360 sembolü 1000x345'e ölçeklenir)
    c.save();
    c.scale(1.5625, .9583);
    c.drawRect(const Rect.fromLTWH(0, 0, 640, 360), _f(const Color(0xFF6E6A48)));
    _poly(c, [0, 0, 250, 0, 180, 140, 0, 190], const Color(0xFF7B7652));
    _poly(c, [250, 0, 640, 0, 640, 120, 420, 150, 180, 140], const Color(0xFF5E6844));
    _poly(c, [0, 190, 180, 140, 420, 150, 330, 360, 0, 360], const Color(0xFF827B55));
    _poly(c, [420, 150, 640, 120, 640, 360, 330, 360], const Color(0xFF66684A));
    c.drawPath(Path()..moveTo(-10, 300)..cubicTo(150, 230, 260, 190, 360, 120)..cubicTo(460, 50, 560, 20, 660, -10), _s(rgba(0xCBBE9A, .75), 9));
    c.drawPath(Path()..moveTo(180, 360)..cubicTo(230, 280, 300, 250, 330, 190), _s(rgba(0xCBBE9A, .6), 6));
    c.drawRect(const Rect.fromLTWH(600, 0, 40, 360), _f(const Color(0xFF8F9696)));
    for (final t in const [Offset(520, 210), Offset(548, 236), Offset(500, 248), Offset(90, 70), Offset(116, 92)]) {
      c.drawCircle(t, 13, _f(rgba(0x3E5A34, .8)));
    }
    c.restore();
    c.drawRect(const Rect.fromLTWH(-200, -200, 1400, 750), _f(rgba(0x0A1417, .42)));
    final grid = _s(rgba(0xFFFFFF, .07), 1);
    for (double x = -180; x < 1200; x += 45) {
      c.drawLine(Offset(x, -200), Offset(x, 550), grid);
    }
    for (double y = -180; y < 550; y += 45) {
      c.drawLine(Offset(-200, y), Offset(1200, y), grid);
    }
    // HOME
    c.drawCircle(const Offset(70, 205), 16, _f(const Color(0xFF0A1417)));
    c.drawCircle(const Offset(70, 205), 16, _s(C.disarm, 2.5));
    drawText(c, 'H', const Offset(70, 205), size: 14, w: FontWeight.w800);
    // formasyon çizgileri
    final dash = _s(rgba(0x4DB2FF, .7), 2);
    for (final pair in const [[0, 1], [1, 2]]) {
      _dashed(c, pos[pair[0]], pos[pair[1]], dash, 7, 6);
    }
    // hedef çizgileri
    for (int i = 0; i < 3; i++) {
      final tg = target[i];
      if (tg == null) continue;
      _dashed(c, pos[i], tg, _s(C.amber, 3), 3, 7);
      final pulse = 1 + .12 * math.sin(t * 5);
      c.drawCircle(tg, 26 * pulse, _f(rgba(0xF5B73D, .10)));
      c.drawCircle(tg, 26 * pulse, _s(rgba(0xF5B73D, .6), 1));
      c.drawCircle(tg, 15, _s(C.amber, 1.6));
      final a = _s(C.amber, 2);
      c.drawLine(tg + const Offset(0, -24), tg + const Offset(0, -12), a);
      c.drawLine(tg + const Offset(0, 12), tg + const Offset(0, 24), a);
      c.drawLine(tg + const Offset(-24, 0), tg + const Offset(-12, 0), a);
      c.drawLine(tg + const Offset(12, 0), tg + const Offset(24, 0), a);
      c.drawCircle(tg, 3.5, _f(C.amber));
      final d = ((tg - pos[i]).distance * .44).round();
      _label(c, '$d m · ~${(d / 10).round()} s', tg + const Offset(-52, -48), color: C.amber, size: 11);
    }
    if (showMenuMark && menuWorld != null) {
      c.drawCircle(menuWorld!, 12, _s(rgba(0xE8EEF0, .7), 2));
      c.drawLine(menuWorld! + const Offset(-10, 0), menuWorld! + const Offset(10, 0), _s(rgba(0xE8EEF0, .7), 2));
      c.drawLine(menuWorld! + const Offset(0, -10), menuWorld! + const Offset(0, 10), _s(rgba(0xE8EEF0, .7), 2));
    }
    // seçili halka
    final sp = pos[sel];
    c.drawCircle(sp, 40, _f(rgba(0x4DB2FF, .10)));
    c.drawCircle(sp, 40, _s(C.blue, 2));
    c.drawCircle(sp, 48, _s(rgba(0x4DB2FF, .4), 1));
    for (int i = 0; i < 3; i++) {
      drawPlane(c, pos[i], hdg[i], 56, C.green);
      _label(c, 'İHA-${i + 1}', pos[i] + const Offset(26, -32));
    }
    // WP etiketleri
    for (final e in const [['WP-01', 105.0, 239.0], ['WP-03', 825.0, 39.0], ['WP-02', 845.0, 109.0]]) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(e[1] as double, e[2] as double, 70, 22), const Radius.circular(2));
      c.drawRRect(r, _f(const Color(0xFF223940)));
      c.drawRRect(r, _s(const Color(0xFF3B5258), 1));
      drawText(c, e[0] as String, Offset((e[1] as double) + 35, (e[2] as double) + 11), size: 11, color: const Color(0xFFC8D6D9), ls: 1.1);
    }
    c.restore();
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p, double on, double off) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final u = d / len;
    for (double x = 0; x < len; x += on + off) {
      c.drawLine(a + u * x, a + u * math.min(x + on, len), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) => true;
}
