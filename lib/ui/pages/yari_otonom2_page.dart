import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// YARI OTONOM 2 – Şartname 5.2 "Yarı Otonom Sürü Kontrolü": sürü tek bir kumanda (joystick/RC) ile yönetilir.
///  • Sürü Hareket Modu: formasyon korunarak ileri/geri (pitch), sağ/sol (roll), irtifa (throttle),
///    sürü merkezi etrafında toplu dönüş (yaw; her İHA yönünü dinamik ayarlar).
///  • Manevra Modu: sürü merkezi sabit; pitch/roll ile formasyonun toplu eğilmesi, yaw ile rotasyon,
///    throttle ile toplu irtifa.
///  • Formasyon değişimi, kalkış ve iniş de kumandadan yapılır; her girdi sürü yazılımından geçip
///    tüm İHA'lara eş zamanlı iletilir.
/// Not: şu an tamamı simülasyondur (gerçek kumanda/MAVLink bağlantısı yok).
class YariOtonom2Page extends StatefulWidget {
  const YariOtonom2Page({super.key});

  @override
  State<YariOtonom2Page> createState() => _YariOtonom2PageState();
}

enum _Phase { havada, kalkis, inis, yerde }

/// Bir İHA'nın formasyon merkezine göre durumu: (r, f) yuva, (rr, ff, dz) eğimden sonra, (dx, dy) dünya ofseti (m).
class _G {
  const _G(this.r, this.f, this.rr, this.ff, this.dz, this.dx, this.dy);
  final double r, f, rr, ff, dz, dx, dy;
}

Paint _fp(Color c) => Paint()..color = c;
Paint _sp(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

void _dashLine(Canvas c, Offset a, Offset b, Paint p, double on, double off) {
  final d = b - a;
  final len = d.distance;
  if (len == 0) return;
  final u = d / len;
  for (double x = 0; x < len; x += on + off) {
    c.drawLine(a + u * x, a + u * math.min(x + on, len), p);
  }
}

void _dashCircle(Canvas c, Offset ctr, double r, Paint p) {
  const n = 48;
  const step = 2 * math.pi / n;
  for (int i = 0; i < n; i++) {
    c.drawArc(Rect.fromCircle(center: ctr, radius: r), i * step, step * .45, false, p);
  }
}

class _YariOtonom2PageState extends State<YariOtonom2Page> with SingleTickerProviderStateMixin {
  // Formasyon yuvaları (r = sağa, f = ileri; metre). Sıra: İHA-1, İHA-2, İHA-3.
  static const _fs = <List<List<double>>>[
    [[-8, -4.8], [0, 4.8], [8, -4.8]], // Ok Başı: lider önde, kanatlar geride
    [[-8, 4.8], [0, -4.8], [8, 4.8]], // V: kanatlar önde yanlarda, biri geride ortada
    [[-8, 0], [0, 0], [8, 0]], // Çizgi: yan yana
  ];
  static const _fn = ['Ok Başı', 'V', 'Çizgi'];
  static const _slotNames = [
    ['SOL ARKA', 'ÖN · LİDER', 'SAĞ ARKA'],
    ['SOL ÖN', 'ARKA', 'SAĞ ÖN'],
    ['SOL', 'ORTA', 'SAĞ'],
  ];
  static const _zTakeoff = 37.6;

  int _mode = 0; // 0 Sürü Hareket Modu, 1 Manevra Modu
  int _form = 0; // 0 Ok Başı, 1 V, 2 Çizgi

  // kumanda çubukları (−1…+1)
  double _p = 0, _r = 0, _t = 0, _w = 0; // pitch, roll, throttle, yaw
  bool _dragL = false, _dragR = false;

  // sürü durumu
  double _cx = 18, _cy = 26, _z = _zTakeoff, _psi = 0, _th = 0, _ph = 0, _spd = 0, _dev = 0;
  _Phase _phase = _Phase.havada;
  List<List<double>> _sl = [for (final a in _fs[0]) [...a]];
  final List<Offset> _trail = [const Offset(18, 26)];
  double _trT = 0;

  String _toast = '';
  double _toastT = 0;

  late final Ticker _ticker;
  Duration _last = Duration.zero;

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

  void _say(String t) {
    _toast = t;
    _toastT = 3;
  }

  void _tick(Duration el) {
    final dt = ((el - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = el;
    _advance(dt);
    if (mounted) setState(() {});
  }

  void _advance(double dt) {
    // bırakılan çubuklar merkeze döner (yaylı kumanda)
    if (!_dragL) {
      final k = math.exp(-12 * dt);
      _t *= k;
      _w *= k;
      if (_t.abs() < .01) _t = 0;
      if (_w.abs() < .01) _w = 0;
    }
    if (!_dragR) {
      final k = math.exp(-12 * dt);
      _p *= k;
      _r *= k;
      if (_p.abs() < .01) _p = 0;
      if (_r.abs() < .01) _r = 0;
    }
    final air = _phase == _Phase.havada;
    const rad = math.pi / 180;
    double vx = 0, vy = 0, tp = 0, tr = 0;
    if (_phase == _Phase.kalkis) {
      _z += 4.2 * dt;
      if (_z >= _zTakeoff) {
        _z = _zTakeoff;
        _phase = _Phase.havada;
        _say('Sürü kalkışı tamamlandı · kumanda aktif');
      }
    } else if (_phase == _Phase.inis) {
      _z -= 3.6 * dt;
      if (_z <= 0) {
        _z = 0;
        _phase = _Phase.yerde;
        _say('Sürü indi · motorlar durdu');
      }
    } else if (air) {
      _z = (_z + _t * 4 * dt).clamp(3.0, 120.0).toDouble();
      _psi = (_psi + _w * 40 * dt + 360) % 360;
      if (_mode == 0) {
        final vf = _p * 8, vr = _r * 8;
        final s = math.sin(_psi * rad), c = math.cos(_psi * rad);
        vx = vr * c + vf * s;
        vy = -vr * s + vf * c;
        _cx += vx * dt;
        _cy += vy * dt;
      } else {
        tp = -_p * 25; // ileri çubuk = burun aşağı (negatif pitch)
        tr = _r * 25;
      }
    }
    // eğim (manevra): yumuşak takip
    final kk = 1 - math.exp(-6 * dt);
    _th += (tp - _th) * kk;
    _ph += (tr - _ph) * kk;
    if (_th.abs() < .02) _th = 0;
    if (_ph.abs() < .02) _ph = 0;
    final climb = _phase == _Phase.kalkis ? 4.2 : (_phase == _Phase.inis ? 3.6 : (air ? _t.abs() * 4 : 0.0));
    _spd = math.sqrt(vx * vx + vy * vy) + climb;
    // formasyon yuvaları hedefe akar
    double dev = 0;
    final tg = _fs[_form];
    final ks = 1 - math.exp(-2.4 * dt);
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        final dd = tg[i][j] - _sl[i][j];
        _sl[i][j] += dd * ks;
        dev = math.max(dev, dd.abs());
      }
    }
    if (dev < .02) _sl = [for (final a in tg) [...a]];
    _dev = dev;
    // iz
    _trT += dt;
    if (_trT > .2) {
      _trT = 0;
      final cur = Offset(_cx, _cy);
      if ((_trail.last - cur).distance > .4) {
        _trail.add(cur);
        if (_trail.length > 90) _trail.removeAt(0);
      }
    }
    if (_toastT > 0) _toastT -= dt;
  }

  List<_G> _geo() {
    const rad = math.pi / 180;
    final ps = math.sin(_psi * rad), pc = math.cos(_psi * rad);
    final th = _th * rad, ph = _ph * rad;
    return [
      for (final s in _sl)
        () {
          final r0 = s[0], f0 = s[1];
          final f1 = f0 * math.cos(th), z1 = f0 * math.sin(th); // pitch: yatay eksen etrafında eğim
          final r2 = r0 * math.cos(ph), z2 = z1 - r0 * math.sin(ph); // roll: ileri ekseni etrafında yatış
          final dx = r2 * pc + f1 * ps, dy = -r2 * ps + f1 * pc; // yaw: sürü yönüne göre dünya eksenleri
          return _G(r0, f0, r2, f1, z2, dx, dy);
        }(),
    ];
  }

  // ───── komutlar ─────
  void _setMode(int m) => setState(() {
        _mode = m;
        _say(m == 0 ? 'Sürü Hareket Modu' : 'Manevra Modu · merkez sabit');
      });

  void _pickForm(int k) => setState(() {
        if (_phase != _Phase.havada) {
          _say('Formasyon değişimi için önce kalkış');
        } else if (_form != k) {
          _form = k;
          _say('Kumandadan formasyon: ${_fn[k]}');
        }
      });

  void _takeoff() => setState(() {
        if (_phase == _Phase.yerde) {
          _phase = _Phase.kalkis;
          _say('Sürü kalkışa geçti');
        } else if (_phase == _Phase.inis) {
          _phase = _Phase.kalkis;
          _say('İniş iptal · sürü yükseliyor');
        } else {
          _say('Sürü zaten havada');
        }
      });

  void _land() => setState(() {
        if (_phase == _Phase.havada || _phase == _Phase.kalkis) {
          _phase = _Phase.inis;
          _say('Sürü iniş yapıyor');
        } else if (_phase == _Phase.yerde) {
          _say('Sürü zaten yerde');
        }
      });

  // ───── küçük bileşenler ─────
  Widget _chip(Widget c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: rgba(0x0C171A, .88),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: lc(0xFF3B5258)),
        ),
        child: c,
      );

  Widget _viewBox(Widget child) => Container(
        decoration: BoxDecoration(
          color: lc(0xFF0A1417),
          border: Border.all(color: lc(0xFF1E3237)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(2), child: child),
      );

  Widget _vtag(String t) => Positioned(left: 10, top: 8, child: Text(t, style: ts(9.5, color: C.label, ls: 1.4)));

  Widget _vleg() => Positioned(
        right: 10,
        bottom: 8,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 22, height: 0, decoration: BoxDecoration(border: Border(top: BorderSide(color: lc(0xFF5B7B84), width: 1.5)))),
          gap(6),
          Text('MERKEZ İRTİFASI', style: ts(9.5, color: C.label, ls: .8)),
        ]),
      );

  Widget _kv(String k, String v) => Text.rich(TextSpan(children: [
        TextSpan(text: '$k ', style: ts(10, color: C.label, ls: 1)),
        TextSpan(text: v, style: ts(11.5, w: FontWeight.w700)),
      ]));

  // ───── sol panel: sürü görünümü ─────
  Widget _views(List<_G> g) {
    final hdg = (_psi.round() % 360).toString().padLeft(3, '0');
    final homeD = math.sqrt(_cx * _cx + _cy * _cy).round();
    final pitchTxt = 'PITCH ${_th >= 0 ? '+' : '−'}${_th.abs().toStringAsFixed(1)}°';
    final rollTxt = 'ROLL ${_ph >= 0 ? '+' : '−'}${_ph.abs().toStringAsFixed(1)}°';
    return Row(children: [
      Expanded(
        flex: 170,
        child: _viewBox(Stack(fit: StackFit.expand, children: [
          CustomPaint(painter: _TopPainter(g: g, cx: _cx, cy: _cy, psi: _psi, w: _w, trail: List.of(_trail), z: _z)),
          _vtag('ÜSTTEN · KUZEY YUKARI'),
          Positioned(
            left: 10,
            top: 28,
            child: _chip(Row(mainAxisSize: MainAxisSize.min, children: [
              _kv('YÖN', '$hdg°'),
              gap(14),
              _kv('İRTİFA', '${_z.toStringAsFixed(1)} m'),
              gap(14),
              _kv('HIZ', '${_spd.toStringAsFixed(1)} m/s'),
              gap(14),
              _kv('HOME', '$homeD m'),
            ])),
          ),
          if (_phase == _Phase.yerde)
            Positioned.fill(
              child: Center(
                child: _chip(Text('SÜRÜ YERDE · KALKIŞ komutu bekleniyor', style: ts(13, color: C.amber, w: FontWeight.w700))),
              ),
            ),
          if (_toastT > 0) Positioned(left: 10, bottom: 10, child: _chip(Text(_toast, style: ts(12, color: C.green, w: FontWeight.w600)))),
        ])),
      ),
      gap(8),
      Expanded(
        flex: 100,
        child: Column(children: [
          Expanded(
            child: _viewBox(Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _SidePainter(g: g, z: _z, rot: -_th, rear: false)),
              _vtag('YANDAN · PITCH'),
              Positioned(right: 10, top: 7, child: Text(pitchTxt, style: ts(11.5, color: C.amber, w: FontWeight.w700, ls: .4))),
              _vleg(),
            ])),
          ),
          gap(8),
          Expanded(
            child: _viewBox(Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _SidePainter(g: g, z: _z, rot: _ph, rear: true)),
              _vtag('ARKADAN · ROLL'),
              Positioned(right: 10, top: 7, child: Text(rollTxt, style: ts(11.5, color: C.amber, w: FontWeight.w700, ls: .4))),
              _vleg(),
            ])),
          ),
        ]),
      ),
    ]);
  }

  // ───── sağ panel: kumanda ─────
  Widget _modeBtn(int m, String t, String sub) {
    final on = _mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(m),
        child: Container(
          height: 44,
          margin: EdgeInsets.only(left: m == 0 ? 0 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: on ? lc(0xFF17402F) : lc(0xFF18292E),
            border: Border.all(color: on ? C.green : lc(0xFF33505A)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t, style: ts(11.5, color: on ? C.green : C.text, w: FontWeight.w700, ls: 1)),
              gap(2),
              Text(sub, style: ts(10, color: on ? C.green : C.mut)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cmdBtn(String label, bool green, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 38,
            margin: EdgeInsets.only(left: green ? 0 : 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: green ? lc(0xFF17402F) : lc(0xFF18292E),
              border: Border.all(color: active ? C.amber : (green ? C.green : lc(0xFF33505A)), width: active ? 2 : 1),
            ),
            child: Text(label, style: ts(12, color: green ? C.green : C.text, w: FontWeight.w700, ls: 1.4)),
          ),
        ),
      );

  Widget _formTile(int i) {
    final on = _form == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickForm(i),
        child: Container(
          height: 62,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: on ? lc(0xFF17402F) : lc(0xFF18292E),
            border: Border.all(color: on ? C.green : lc(0xFF33505A), width: on ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 90, height: 36, child: CustomPaint(painter: FormationIconPainter(i, color: on ? C.green : C.text))),
              gap(2),
              Text(_fn[i], style: ts(11.5, color: on ? C.green : C.text)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final m0 = _mode == 0;
    final note = m0
        ? 'Normal bir İHA gibi: Pitch = ileri/geri, Roll = sağ/sol, Throttle = irtifa, Yaw = sürü merkezi etrafında toplu dönüş (her İHA yönünü dinamik ayarlar).'
        : 'Sürü merkezi sabit: Pitch = formasyonun yukarı/aşağı eğilmesi, Roll = sağa/sola yatış, Yaw = merkez etrafında rotasyon, Throttle = toplu irtifa.';
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _modeBtn(0, 'SÜRÜ HAREKET MODU', 'formasyon korunarak ötelenir'),
            _modeBtn(1, 'MANEVRA MODU', 'merkez sabit · eğim / dönüş'),
          ]),
          gap(6),
          SizedBox(height: 32, child: Text(note, style: ts(11, color: C.mut2, h: 1.3))),
          gap(4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Column(children: [
              _Pad(
                x: _w,
                y: _t,
                top: '▲ Yukarı',
                bottom: '▼ Aşağı',
                left: '↺ Sol',
                right: 'Sağ ↻',
                onMove: (x, y) {
                  _dragL = true;
                  _w = x;
                  _t = y;
                },
                onEnd: () => _dragL = false,
              ),
              gap(5),
              Text('THROTTLE · YAW', style: ts(10.5, color: C.label, ls: 1)),
            ]),
            Column(children: [
              _Pad(
                x: _r,
                y: _p,
                top: m0 ? '▲ İleri' : '▼ Aşağı eğ',
                bottom: m0 ? '▼ Geri' : '▲ Yukarı eğ',
                left: m0 ? '◀ Sol' : '◀ Yat',
                right: m0 ? 'Sağ ▶' : 'Yat ▶',
                onMove: (x, y) {
                  _dragR = true;
                  _r = x;
                  _p = y;
                },
                onEnd: () => _dragR = false,
              ),
              gap(5),
              Text('PITCH · ROLL', style: ts(10.5, color: C.label, ls: 1)),
            ]),
          ]),
          gap(8),
          Row(children: [
            _cmdBtn('▲ KALKIŞ · sürü', true, _phase == _Phase.kalkis, _takeoff),
            _cmdBtn('▼ İNİŞ · sürü', false, _phase == _Phase.inis, _land),
          ]),
          gap(8),
          Text('FORMASYON · KUMANDADAN', style: ts(10, color: C.label, ls: 1.2)),
          gap(5),
          Row(children: [_formTile(0), _formTile(1), _formTile(2)]),
        ],
      ),
    );
  }

  Tag _stateTag() {
    switch (_phase) {
      case _Phase.havada:
        return const Tag('● HAVADA · KUMANDA AKTİF', fontSize: 10, height: 22);
      case _Phase.kalkis:
        return const Tag('▲ KALKIŞ', kind: TagKind.amber, fontSize: 10, height: 22);
      case _Phase.inis:
        return const Tag('▼ İNİŞ', kind: TagKind.amber, fontSize: 10, height: 22);
      case _Phase.yerde:
        return const Tag('■ YERDE', kind: TagKind.amber, fontSize: 10, height: 22);
    }
  }

  // ───── alt sol: sürü tepkisi tablosu ─────
  static const _tw = [15, 7, 8, 10, 10, 10]; // esnek sütun payları (İHA sütunundan sonra)

  Widget _row(List<Widget> cells, {double h = 26, bool head = false}) => Container(
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: head
            ? null
            : BoxDecoration(
                color: lc(0xFF101C1F),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: lc(0xFF2A4046)),
              ),
        child: Row(children: [
          SizedBox(width: 62, child: cells[0]),
          for (int i = 1; i < cells.length; i++) Expanded(flex: _tw[i - 1], child: cells[i]),
        ]),
      );

  Widget _table(List<_G> g) {
    Widget hd(String t) => Text(t, maxLines: 1, overflow: TextOverflow.clip, style: ts(9.5, color: C.label, ls: 1.2));
    Widget tx(String t, {Color? color, FontWeight w = FontWeight.w400, double size = 12.5}) =>
        Text(t, maxLines: 1, overflow: TextOverflow.clip, style: ts(size, color: color, w: w));
    final hdg = '${(_psi.round() % 360).toString().padLeft(3, '0')}°';
    final tg = _fs[_form];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row([hd('İHA'), hd('YERİ'), hd('YÖN'), hd('İRTİFA'), hd('MERKEZE UZAKLIK'), hd('SLOT SAPMASI'), hd('DURUM')], h: 18, head: true),
        for (int i = 0; i < 3; i++)
          () {
            final dv = math.sqrt(math.pow(_sl[i][0] - tg[i][0], 2) + math.pow(_sl[i][1] - tg[i][1], 2));
            final onGround = _phase == _Phase.yerde;
            final trans = dv > .05;
            final col = onGround ? C.mut2 : (trans ? C.amber : C.green);
            final st = onGround ? '● YERDE' : (trans ? '● GEÇİŞTE' : '● SENKRON');
            return _row([
              tx('İHA-${i + 1}', w: FontWeight.w700),
              tx(_slotNames[_form][i]),
              tx(hdg),
              tx('${(_z + g[i].dz).toStringAsFixed(1)} m'),
              tx('${math.sqrt(g[i].rr * g[i].rr + g[i].ff * g[i].ff).toStringAsFixed(1)} m'),
              tx('${dv.toStringAsFixed(1)} m'),
              tx(st, color: col, w: FontWeight.w700, size: 11.5),
            ]);
          }(),
      ],
    );
  }

  // ───── alt sağ: kumanda girdisi → sürü yazılımı ─────
  Widget _chan(String name, double v, String hp, String hn) {
    final pct = '${v >= 0 ? '+' : '−'}${(v.abs() * 100).round()} %';
    final hint = v > .04 ? hp : (v < -.04 ? hn : '—');
    return SizedBox(
      height: 15,
      child: Row(children: [
        SizedBox(width: 66, child: Text(name, style: ts(10.5, color: C.label, w: FontWeight.w600, ls: .6))),
        Expanded(
          child: LayoutBuilder(builder: (context, b) {
            final mid = b.maxWidth / 2;
            final x = mid + v * mid;
            return SizedBox(
              height: 15,
              child: Stack(children: [
                Positioned(left: 0, right: 0, top: 4, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: lc(0xFF0A1417), borderRadius: BorderRadius.circular(3)))),
                Positioned(left: math.min(mid, x), top: 4, width: (x - mid).abs(), height: 7, child: DecoratedBox(decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(3)))),
                Positioned(left: mid - 1, top: 1, width: 2, height: 13, child: ColoredBox(color: C.mut)),
              ]),
            );
          }),
        ),
        gap(8),
        SizedBox(width: 46, child: Text(pct, textAlign: TextAlign.right, style: ts(11, w: FontWeight.w700))),
        gap(8),
        SizedBox(width: 92, child: Text(hint, maxLines: 1, overflow: TextOverflow.clip, style: ts(10.5, color: C.mut2))),
      ]),
    );
  }

  Widget _pipeBox(String t, {bool on = false}) => Expanded(
        child: Container(
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: on ? lc(0xFF17402F) : lc(0xFF101C1F),
            border: Border.all(color: on ? C.green : lc(0xFF2A4046)),
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(t, style: ts(10, color: on ? C.green : C.mut2, ls: .9))),
        ),
      );

  Widget _channels() {
    final m0 = _mode == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chan('PITCH', _p, m0 ? '▲ ileri' : '▼ aşağı eğ', m0 ? '▼ geri' : '▲ yukarı eğ'),
        gap(5),
        _chan('ROLL', _r, m0 ? '▶ sağ' : '▶ sağa yat', m0 ? '◀ sol' : '◀ sola yat'),
        gap(5),
        _chan('THROTTLE', _t, '▲ yukarı (irtifa)', '▼ aşağı (irtifa)'),
        gap(5),
        _chan('YAW', _w, '↻ sağa rotasyon', '↺ sola rotasyon'),
        gap(8),
        Row(children: [
          _pipeBox('KUMANDA'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('›', style: ts(16, color: C.green))),
          _pipeBox('SÜRÜ KONTROL YAZILIMI'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('›', style: ts(16, color: C.green))),
          _pipeBox('İHA-1 · İHA-2 · İHA-3', on: true),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _geo();
    final syncTag = _phase == _Phase.yerde ? 'MOTORLAR DURDU' : (_dev > .05 ? 'FORMASYON GEÇİŞİ' : '3 / 3 SENKRON');
    return PageFrame(
      title: 'SÜRÜ İHA // YARI OTONOM 2',
      statusRow: true,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 175,
                    child: Panel(
                      title: 'SÜRÜ GÖRÜNÜMÜ',
                      trailing: Tag(_mode == 0 ? 'SÜRÜ HAREKET MODU' : 'MANEVRA MODU', fontSize: 11, height: 22),
                      child: _views(g),
                    ),
                  ),
                  gap(8),
                  Expanded(
                    flex: 100,
                    child: Panel(title: 'KUMANDA · RC / JOYSTICK', trailing: _stateTag(), child: _controls()),
                  ),
                ],
              ),
            ),
            gap(8),
            SizedBox(
              height: 172,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 175,
                    child: Panel(
                      title: 'SÜRÜ TEPKİSİ · EŞ ZAMANLI',
                      trailing: Tag(syncTag, fontSize: 10, height: 22),
                      child: _table(g),
                    ),
                  ),
                  gap(8),
                  Expanded(
                    flex: 100,
                    child: Panel(
                      title: 'KUMANDA GİRDİSİ → SÜRÜ YAZILIMI',
                      trailing: Tag(_mode == 0 ? 'HAREKET' : 'MANEVRA', fontSize: 10, height: 22),
                      child: _channels(),
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

// ───────────────────────── kumanda çubuğu ─────────────────────────

class _Pad extends StatelessWidget {
  const _Pad({
    required this.x,
    required this.y,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.onMove,
    required this.onEnd,
  });
  final double x, y;
  final String top, bottom, left, right;
  final void Function(double x, double y) onMove;
  final VoidCallback onEnd;
  static const double size = 140;

  void _upd(Offset p) {
    var nx = ((p.dx / size) - .5) / .38;
    var ny = -((p.dy / size) - .5) / .38;
    final q = math.sqrt(nx * nx + ny * ny);
    if (q > 1) {
      nx /= q;
      ny /= q;
    }
    onMove(nx.clamp(-1.0, 1.0).toDouble(), ny.clamp(-1.0, 1.0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    Widget lb(String t) => Text(t, style: ts(8.5, color: C.label, ls: .5));
    return Listener(
      onPointerDown: (e) => _upd(e.localPosition),
      onPointerMove: (e) => _upd(e.localPosition),
      onPointerUp: (_) => onEnd(),
      onPointerCancel: (_) => onEnd(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: lc(0xFF0C171A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lc(0xFF2A4046)),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _PadPainter(x, y))),
          Positioned(top: 3, left: 0, right: 0, child: Center(child: lb(top))),
          Positioned(bottom: 3, left: 0, right: 0, child: Center(child: lb(bottom))),
          Positioned(left: 5, top: size / 2 - 17, child: lb(left)),
          Positioned(right: 5, top: size / 2 - 17, child: lb(right)),
        ]),
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter(this.x, this.y);
  final double x, y;

  @override
  void paint(Canvas c, Size s) {
    final mid = Offset(s.width / 2, s.height / 2);
    final line = _sp(lc(0xFF2A4046), 1);
    c.drawLine(Offset(mid.dx, 14), Offset(mid.dx, s.height - 14), line);
    c.drawLine(Offset(14, mid.dy), Offset(s.width - 14, mid.dy), line);
    _dashCircle(c, mid, 44, _sp(lc(0xFF33505A), 1));
    final k = Offset(mid.dx + x * s.width * .38, mid.dy - y * s.height * .38);
    c.drawCircle(
      k,
      21,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.4),
          colors: [lc(0xFF5BE0A0), lc(0xFF1F7A52)],
        ).createShader(Rect.fromCircle(center: k, radius: 21)),
    );
    c.drawCircle(k, 21, _sp(C.green, 2));
  }

  @override
  bool shouldRepaint(covariant _PadPainter o) => true;
}

// ───────────────────────── görünümler ─────────────────────────

/// Üstten görünüm: kuzey yukarı, sürü merkezi ekranın ortasında (kamera sürüyü izler).
class _TopPainter extends CustomPainter {
  _TopPainter({required this.g, required this.cx, required this.cy, required this.psi, required this.w, required this.trail, required this.z});
  final List<_G> g;
  final double cx, cy, psi, w, z;
  final List<Offset> trail;

  @override
  void paint(Canvas c, Size s) {
    final k = 7 * s.height / 414; // piksel / metre
    final o = Offset(s.width / 2, s.height / 2);
    Offset sc(double wx, double wy) => Offset(o.dx + (wx - cx) * k, o.dy - (wy - cy) * k);

    // 10 m'lik ızgara (dünyaya sabit, sürü ilerledikçe kayar)
    final grid = _sp(rgba(0x8BA0A5, .18), 1);
    final step = 10 * k;
    for (double x = (o.dx - cx * k) % step; x < s.width; x += step) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (double y = (o.dy + cy * k) % step; y < s.height; y += step) {
      c.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    // mesafe halkaları
    final ring = _sp(lc(0xFF2A4046), 1);
    _dashCircle(c, o, 10 * k, ring);
    _dashCircle(c, o, 20 * k, ring);
    drawText(c, '10 m', Offset(o.dx + 4, o.dy - 10 * k - 8), size: 9.5, color: C.label, align: TextAlign.left);
    drawText(c, '20 m', Offset(o.dx + 4, o.dy - 20 * k - 8), size: 9.5, color: C.label, align: TextAlign.left);

    // iz
    if (trail.length > 1) {
      final path = Path()..moveTo(sc(trail[0].dx, trail[0].dy).dx, sc(trail[0].dx, trail[0].dy).dy);
      for (int i = 1; i < trail.length; i++) {
        final p = sc(trail[i].dx, trail[i].dy);
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(o.dx, o.dy);
      c.drawPath(path, _sp(rgba(0x4DB2FF, .55), 2)..strokeJoin = StrokeJoin.round);
    }

    // HOME (görüş dışındaysa kenara yapışır)
    final h0 = sc(0, 0);
    final h = Offset(h0.dx.clamp(22.0, s.width - 22).toDouble(), h0.dy.clamp(22.0, s.height - 22).toDouble());
    c.drawCircle(h, 12, _fp(const Color(0xFF0A1A20)));
    c.drawCircle(h, 12, _sp(C.disarm, 2.2));
    drawText(c, 'H', h, size: 12, w: FontWeight.w800);

    // formasyon bağlantısı
    final pos = [for (final d in g) Offset(o.dx + d.dx * k, o.dy - d.dy * k)];
    final link = _sp(rgba(0x4DB2FF, .7), 2);
    _dashLine(c, pos[0], pos[1], link, 7, 6);
    _dashLine(c, pos[1], pos[2], link, 7, 6);

    // yaw oku (merkez etrafında dönüş)
    final wa = w.abs();
    if (wa > .03) {
      final r = 12 * k;
      final a = _sp(C.amber.withValues(alpha: math.min(1.0, wa * 2)), 3);
      const s0 = -math.pi / 2 - 50 * math.pi / 180;
      c.drawArc(Rect.fromCircle(center: o, radius: r), s0, 100 * math.pi / 180, false, a);
      final cw = w > 0;
      final ang = cw ? s0 + 100 * math.pi / 180 : s0;
      final p = o + Offset(math.cos(ang), math.sin(ang)) * r;
      final dir = cw ? Offset(-math.sin(ang), math.cos(ang)) : Offset(math.sin(ang), -math.cos(ang));
      final rad = Offset(math.cos(ang), math.sin(ang));
      final head = Path()
        ..moveTo(p.dx + dir.dx * 9, p.dy + dir.dy * 9)
        ..lineTo(p.dx + rad.dx * 5, p.dy + rad.dy * 5)
        ..lineTo(p.dx - rad.dx * 5, p.dy - rad.dy * 5)
        ..close();
      c.drawPath(head, _fp(C.amber.withValues(alpha: math.min(1.0, wa * 2))));
    }

    // sürü yönü oku
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(psi * math.pi / 180);
    final hp = _sp(C.green.withValues(alpha: .75), 2);
    _dashLine(c, Offset(0, -13.1 * k), Offset(0, -17.4 * k), hp, 3, 4);
    c.drawLine(Offset(-6, -16.6 * k), Offset(0, -18 * k), hp);
    c.drawLine(Offset(6, -16.6 * k), Offset(0, -18 * k), hp);
    c.restore();

    // İHA'lar + etiketler (isim, irtifa)
    for (int i = 0; i < 3; i++) {
      drawPlane(c, pos[i], psi, 42 * k / 7, C.green);
    }
    for (int i = 0; i < 3; i++) {
      final lc0 = Offset(pos[i].dx, pos[i].dy - 44 * k / 7);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lc0, width: 56, height: 30), const Radius.circular(2)), _fp(const Color(0xE60A1A20)));
      drawText(c, 'İHA-${i + 1}', Offset(lc0.dx, lc0.dy - 6.5), size: 10.5, w: FontWeight.w700);
      drawText(c, '${(z + g[i].dz).toStringAsFixed(1)} m', Offset(lc0.dx, lc0.dy + 7), size: 10, w: FontWeight.w600, color: const Color(0xFF3FE883));
    }

    // merkez işareti
    final mk = _sp(rgba(0xE8EEF0, .8), 1.6);
    c.drawCircle(o, 8, mk);
    c.drawLine(o + const Offset(-13, 0), o + const Offset(13, 0), mk);
    c.drawLine(o + const Offset(0, -13), o + const Offset(0, 13), mk);

    // kuzey işareti + ölçek
    final n = Offset(s.width - 36, 40);
    c.drawCircle(n, 17, _fp(const Color(0xCC0A1A20)));
    c.drawCircle(n, 17, _sp(lc(0xFF3B5258), 1));
    c.drawPath(
      Path()
        ..moveTo(n.dx, n.dy - 11)
        ..lineTo(n.dx + 5, n.dy + 5)
        ..lineTo(n.dx, n.dy + 2)
        ..lineTo(n.dx - 5, n.dy + 5)
        ..close(),
      _fp(const Color(0xFFE8EEF0)),
    );
    drawText(c, 'K', Offset(n.dx, n.dy - 25), size: 10, w: FontWeight.w700, color: C.mut2);
    final sb = _sp(C.mut2, 1.5);
    final bx = s.width - 14 - 10 * k, by = s.height - 22;
    c.drawLine(Offset(bx, by), Offset(bx + 10 * k, by), sb);
    c.drawLine(Offset(bx, by - 5), Offset(bx, by + 5), sb);
    c.drawLine(Offset(bx + 10 * k, by - 5), Offset(bx + 10 * k, by + 5), sb);
    drawText(c, '10 m', Offset(bx + 5 * k, by - 11), size: 10, color: C.mut2);
  }

  @override
  bool shouldRepaint(covariant _TopPainter o) => true;
}

/// Yandan (pitch) ve arkadan (roll) görünüm: merkez irtifası kesikli çizgi, zemin yaklaşınca yükselir.
class _SidePainter extends CustomPainter {
  _SidePainter({required this.g, required this.z, required this.rot, required this.rear});
  final List<_G> g;
  final double z, rot;
  final bool rear;

  @override
  void paint(Canvas c, Size s) {
    final sc = math.max(s.width / 280, s.height / 200);
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale(sc);
    c.translate(-140, -100);

    final gy = (100 + z * 7).clamp(0.0, 400.0).toDouble();
    c.drawRect(Rect.fromLTWH(0, gy, 280, 260), _fp(rgba(0x3B5258, .35)));
    c.drawLine(Offset(0, gy), Offset(280, gy), _sp(lc(0xFF8BA0A5), 2));
    _dashLine(c, const Offset(0, 100), const Offset(280, 100), _sp(lc(0xFF2A4046), 1), 4, 5);

    final pts = <Offset>[];
    for (final d in g) {
      pts.add(rear
          ? Offset(140 + d.rr * 10.5 + d.ff * 3, 100 - d.dz * 7 - d.ff * 1.4)
          : Offset(140 + d.ff * 14 + d.rr * 3, 100 - d.dz * 7 - d.rr * 1.4));
    }
    final sorted = [...pts]..sort((a, b) => a.dx.compareTo(b.dx));
    final link = _sp(rgba(0x4DB2FF, .75), 1.6);
    _dashLine(c, sorted[0], sorted[1], link, 5, 4);
    _dashLine(c, sorted[1], sorted[2], link, 5, 4);

    for (int i = 0; i < 3; i++) {
      if (rear) {
        c.save();
        c.translate(pts[i].dx, pts[i].dy);
        c.rotate(rot * math.pi / 180);
        drawRearQuad(c, 0, 0, .85, 1, C.green);
        c.restore();
      } else {
        drawSideQuad(c, pts[i], .95, rot, C.green);
      }
      drawText(c, '${i + 1}', Offset(pts[i].dx, pts[i].dy - (rear ? 19 : 17)), size: 10, w: FontWeight.w700, color: C.text);
    }
    if (!rear) {
      final a = _sp(C.mut2, 1.4);
      c.drawLine(const Offset(14, 176), const Offset(40, 176), a);
      c.drawLine(const Offset(34, 171), const Offset(40, 176), a);
      c.drawLine(const Offset(34, 181), const Offset(40, 176), a);
      drawText(c, 'İLERİ', const Offset(46, 177), size: 9.5, color: C.mut2, align: TextAlign.left, ls: 1);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _SidePainter o) => true;
}
