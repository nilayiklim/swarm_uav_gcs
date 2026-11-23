import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../theme.dart';
import '../uav_data.dart';
import '../widgets.dart';

/// KOMUT MERKEZİ – 3 İHA için kalkış / iniş / eve dön / durdur / sürdür simülasyonu + canlı terminal.
/// Terminal komutları MAVProxy tarzıdır; rtl/land/brake/resume kısayolları takım içi takma adlardır
/// (gerçek bağlantıda MAVLink komutlarına eşlenecek).

enum Ph { ground, takeoff, cruise, hold, rtl, land }

class _Sim {
  _Sim({this.arm = false, this.mode = 'STABILIZE', this.ph = Ph.ground, this.alt = 0});
  bool arm;
  String mode;
  Ph ph;
  double alt;
  double target = 0;
  double rtlT = 0;
  double speed = 0;
}

enum _K { sys, cmd, ok, warn, err }

class _Line {
  const _Line(this.time, this.u, this.k, this.text);
  final String time;
  final int u; // 0..2 İHA, -1 sistem
  final _K k;
  final String text;
}

class KomutPage extends StatefulWidget {
  const KomutPage({super.key});

  @override
  State<KomutPage> createState() => _KomutPageState();
}

class _KomutPageState extends State<KomutPage> with SingleTickerProviderStateMixin {
  final List<_Sim> _s = [
    _Sim(arm: true, mode: 'GUIDED', ph: Ph.cruise, alt: 37.7)..speed = 10.1,
    _Sim(arm: true, mode: 'GUIDED', ph: Ph.ground, alt: 0),
    _Sim(),
  ];
  final List<_Line> _log = [];
  int _tab = 3; // 0..2 İHA, 3 TÜMÜ
  int _sel = -1; // büyütülmüş kart
  final _ctl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final List<String> _hist = [];
  int _hi = 0;

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _t = 0;

  // İHA-3 otomatik gösterim (kullanıcı İHA-3'e komut verince durur)
  bool _demo = true;
  double _demoT = 0;
  int _demoStep = 0;
  static const _demoCmds = ['arm throttle', 'takeoff 30', 'rtl'];
  static const _demoAt = [2.0, 3.5, 16.0];

  @override
  void initState() {
    super.initState();
    _log.addAll(const [
      _Line('14:12:31', -1, _K.sys, 'SwarmGCS komut terminali · MAVProxy tarzı · yardım için "help"'),
      _Line('14:12:33', 0, _K.cmd, 'mode GUIDED'),
      _Line('14:12:33', 0, _K.ok, 'Mode GUIDED'),
      _Line('14:12:34', 1, _K.cmd, 'arm throttle'),
      _Line('14:12:35', 1, _K.ok, 'ARMED · kalkış bekleniyor'),
    ]);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ctl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _clock() {
    final sec = 14 * 3600 + 12 * 60 + 40 + _t.floor();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(sec ~/ 3600 % 24)}:${p(sec % 3600 ~/ 60)}:${p(sec % 60)}';
  }

  void _say(int u, String t, [_K k = _K.ok]) {
    _log.add(_Line(_clock(), u, k, t));
    if (_log.length > 400) _log.removeAt(0);
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  // ───────────── Simülasyon ─────────────

  void _tick(Duration el) {
    final dt = ((el - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = el;
    _t += dt;
    var changed = false;
    for (int u = 0; u < 3; u++) {
      final s = _s[u];
      switch (s.ph) {
        case Ph.takeoff:
          s.alt = math.min(s.target, s.alt + 4 * dt);
          s.speed = math.min(10.1, s.speed + 3 * dt);
          if (s.alt >= s.target) {
            s.ph = Ph.cruise;
            _say(u, 'Reached target altitude');
            changed = true;
          }
          break;
        case Ph.cruise:
          s.speed = math.min(10.1, s.speed + 3 * dt);
          break;
        case Ph.hold:
          s.speed = math.max(0, s.speed - 4 * dt);
          break;
        case Ph.rtl:
          s.rtlT += dt;
          s.speed = 10.1;
          if (s.rtlT > 7) {
            s.ph = Ph.land;
            s.mode = 'LAND';
            _say(u, 'Home üzerinde · iniş başlıyor');
            _say(u, 'Mode LAND · iniş', _K.warn);
            changed = true;
          }
          break;
        case Ph.land:
          s.alt = math.max(0, s.alt - 2.5 * dt);
          s.speed = math.max(0, s.speed - 2 * dt);
          if (s.alt <= 0) {
            s.ph = Ph.ground;
            s.arm = false;
            s.mode = 'STABILIZE';
            s.speed = 0;
            _say(u, 'Landed · DISARMED');
            changed = true;
          }
          break;
        case Ph.ground:
          s.speed = 0;
          break;
      }
    }
    if (_demo) {
      _demoT += dt;
      while (_demoStep < _demoCmds.length && _demoT >= _demoAt[_demoStep]) {
        _say(2, _demoCmds[_demoStep], _K.cmd);
        _exec(2, _demoCmds[_demoStep]);
        _demoStep++;
        changed = true;
      }
      if (_demoT > 42) {
        _demoT = 0;
        _demoStep = 0;
      }
    }
    if (changed) _scrollEnd();
    if (mounted) setState(() {});
  }

  /// Tek İHA'ya komut uygular.
  void _exec(int u, String line) {
    final s = _s[u];
    final p = line.trim().toLowerCase().split(RegExp(r'\s+'));
    if (p.isEmpty || p[0].isEmpty) return;
    void ok(String m) => _say(u, m, _K.ok);
    void err(String m) => _say(u, m, _K.err);

    switch (p[0]) {
      case 'arm':
        if (s.arm) {
          ok('Zaten ARMED');
        } else {
          s.arm = true;
          ok('ARMED · kalkış bekleniyor');
        }
        break;
      case 'disarm':
        if (s.ph != Ph.ground) {
          err('Disarm reddedildi: İHA havada');
        } else {
          s.arm = false;
          ok('DISARMED');
        }
        break;
      case 'mode':
        if (p.length < 2) {
          err('Kullanım: mode <GUIDED|LOITER|RTL|LAND|STABILIZE|AUTO>');
        } else {
          s.mode = p[1].toUpperCase();
          if (s.mode == 'RTL') {
            s.ph = Ph.rtl;
            s.rtlT = 0;
          } else if (s.mode == 'LAND') {
            s.ph = Ph.land;
          } else if (s.mode == 'LOITER' && s.ph != Ph.ground) {
            s.ph = Ph.hold;
          }
          ok('Mode ${s.mode}');
        }
        break;
      case 'takeoff':
      case 'kalkis':
        if (!s.arm) {
          err('PreArm: ARM edilmedi');
        } else if (s.ph != Ph.ground) {
          err('Zaten havada');
        } else {
          final n = p.length > 1 ? double.tryParse(p[1]) : null;
          s.target = (n ?? 30).clamp(5, 120).toDouble();
          s.mode = 'GUIDED';
          s.ph = Ph.takeoff;
          ok('Takeoff to ${s.target.toStringAsFixed(1)} m');
        }
        break;
      case 'rtl':
        if (s.ph == Ph.ground) {
          err('İHA yerde');
        } else {
          s.mode = 'RTL';
          s.ph = Ph.rtl;
          s.rtlT = 0;
          ok('Mode RTL · eve dönülüyor');
        }
        break;
      case 'land':
        if (s.ph == Ph.ground) {
          err('İHA yerde');
        } else {
          s.mode = 'LAND';
          s.ph = Ph.land;
          _say(u, 'Mode LAND · iniş', _K.warn);
        }
        break;
      case 'brake':
      case 'stop':
      case 'loiter':
        if (s.ph == Ph.ground) {
          err('İHA yerde');
        } else {
          s.mode = 'LOITER';
          s.ph = Ph.hold;
          _say(u, 'Mode LOITER · durduruldu', _K.warn);
        }
        break;
      case 'resume':
      case 'continue':
        if (s.ph == Ph.hold) {
          s.mode = 'GUIDED';
          s.ph = Ph.cruise;
          ok('Mode GUIDED · görev sürdürülüyor');
        } else {
          err('Duraklatılmış görev yok');
        }
        break;
      case 'status':
        _say(u, 'ARM=${s.arm ? "EVET" : "HAYIR"} MOD=${s.mode} FAZ=${s.ph.name} ALT=${s.alt.toStringAsFixed(1)} m HIZ=${s.speed.toStringAsFixed(1)} m/s', _K.sys);
        break;
      default:
        err('Bilinmeyen komut: ${p[0]}   (help yazın)');
    }
  }

  void _submit(String raw) {
    final line = raw.trim();
    _ctl.clear();
    _focus.requestFocus();
    if (line.isEmpty) return;
    _hist.add(line);
    _hi = _hist.length;
    final p = line.toLowerCase().split(RegExp(r'\s+'));
    final targets = _tab == 3 ? [0, 1, 2] : [_tab];
    if (p[0] == 'clear') {
      _log.clear();
    } else if (p[0] == 'help') {
      _say(-1, 'arm throttle · disarm · mode <X> · takeoff <m> · rtl · land · brake · resume · status · clear · target <1|2|3|all>', _K.sys);
    } else if (p[0] == 'target') {
      final a = p.length > 1 ? p[1] : '';
      final n = int.tryParse(a);
      if (a == 'all') {
        _tab = 3;
      } else if (n != null && n >= 1 && n <= 3) {
        _tab = n - 1;
      } else {
        _say(-1, 'Kullanım: target <1|2|3|all>', _K.err);
      }
    } else {
      if (targets.contains(2)) _demo = false; // kullanıcı İHA-3'e komut verince gösterim durur
      for (final u in targets) {
        _say(u, line, _K.cmd);
        _exec(u, line);
      }
    }
    setState(() {});
    _scrollEnd();
  }

  void _key(KeyEvent e) {
    if (e is! KeyDownEvent || _hist.isEmpty) return;
    if (e.logicalKey == LogicalKeyboardKey.arrowUp && _hi > 0) {
      _hi--;
      _ctl.text = _hist[_hi];
      _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      _hi = math.min(_hi + 1, _hist.length);
      _ctl.text = _hi < _hist.length ? _hist[_hi] : '';
      _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
    }
  }

  void _btn(int u, String cmd) {
    if (u == 2) _demo = false;
    _say(u, cmd, _K.cmd);
    _exec(u, cmd);
    setState(() {});
    _scrollEnd();
  }

  // ───────────── Arayüz ─────────────

  static const _phases = ['YERDE', 'ARM', 'KALKIŞ', 'UÇUŞ', 'EVE DÖN', 'İNİŞ'];

  int _phaseIndex(_Sim s) => switch (s.ph) {
        Ph.ground => s.arm ? 1 : 0,
        Ph.takeoff => 2,
        Ph.cruise || Ph.hold => 3,
        Ph.rtl => 4,
        Ph.land => 5,
      };

  Widget _phaseChip(String t, bool on) => Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: on ? rgba(0x3FD97F, .12) : lc(0xFF18292E),
          border: Border.all(color: on ? C.green : lc(0xFF2B4147)),
        ),
        child: Text(t, style: ts(9.5, color: on ? C.green : C.mut, ls: .8, w: on ? FontWeight.w700 : FontWeight.w400)),
      );

  Widget _card(int u, {required bool mini}) {
    final s = _s[u];
    final info = kUavs[u];
    final pi = _phaseIndex(s);
    final head = Row(
      children: [
        Text(info.name, style: ts(mini ? 15 : 17, w: FontWeight.w700, ls: 1)),
        gap(8),
        Text('${info.pct}%', style: ts(mini ? 14 : 16, color: info.pctColor, w: FontWeight.w700)),
        gap(8),
        Tag(s.arm ? 'ARMED' : 'DISARMED', kind: s.arm ? TagKind.on : TagKind.normal, height: 22, fontSize: 10),
        gap(6),
        Tag(s.mode, kind: s.mode == 'GUIDED' ? TagKind.normal : (s.mode == 'RTL' || s.mode == 'LAND' ? TagKind.red : TagKind.amber), height: 22, fontSize: 10),
        const Spacer(),
        for (int i = 0; i < _phases.length; i++) _phaseChip(_phases[i], i == pi),
      ],
    );
    Widget b(String l, String cmd, BtnKind k) => MetalButton(l, kind: k, height: 44, fontSize: 12, ls: 1.2, hPad: 4, onTap: () => _btn(u, cmd));
    Widget grid() => Column(
          children: [
            Expanded(child: Row(children: [Expanded(child: b('ARM', 'arm throttle', BtnKind.green)), gap(6), Expanded(child: b('KALKIŞ', 'takeoff 30', BtnKind.green))])),
            gap(6),
            Expanded(child: Row(children: [Expanded(child: b('SÜRÜYE KAT', 'resume', BtnKind.normal)), gap(6), Expanded(child: b('DURDUR', 'brake', BtnKind.amber))])),
            gap(6),
            Expanded(child: Row(children: [Expanded(child: b('EVE DÖN', 'rtl', BtnKind.redTint)), gap(6), Expanded(child: b('İNİŞ', 'land', BtnKind.redTint))])),
          ],
        );
    final scene = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          KeepDark(child: CustomPaint(painter: _ScenePainter(s, _t, u))),
          Positioned(
            left: 8,
            top: 6,
            child: Text.rich(TextSpan(style: ts(11, color: D.mut, mono: true), children: [
              const TextSpan(text: 'ALT '),
              TextSpan(text: '${s.alt.toStringAsFixed(1)} m', style: ts(11, color: D.text, w: FontWeight.w700, mono: true)),
              const TextSpan(text: '   HIZ '),
              TextSpan(text: '${s.speed.toStringAsFixed(1)} m/s', style: ts(11, color: D.text, w: FontWeight.w700, mono: true)),
            ])),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: () => setState(() => _sel = _sel == u ? -1 : u),
      child: Panel(
        padding: EdgeInsets.fromLTRB(12, mini ? 6 : 10, 12, mini ? 6 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            gap(mini ? 4 : 8),
            Expanded(
              child: mini
                  ? scene
                  : Row(children: [Expanded(flex: 6, child: scene), gap(8), Expanded(flex: 4, child: grid())]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineW(_Line l) {
    // Terminal her iki temada da koyu kalır: renkler [D] paletinden.
    final tm = ts(12.5, color: D.mut, mono: true);
    final who = l.u < 0 ? '' : 'uav${l.u + 1}';
    switch (l.k) {
      case _K.sys:
        return Text('${l.time}  ${l.text}', style: ts(12.5, color: D.mut, mono: true));
      case _K.cmd:
        return Text.rich(TextSpan(children: [
          TextSpan(text: '${l.time}  ', style: tm),
          TextSpan(text: '$who> ', style: ts(12.5, color: D.green, mono: true)),
          TextSpan(text: l.text, style: ts(12.5, color: D.text, mono: true)),
        ]));
      default:
        final col = l.k == _K.ok ? D.green : (l.k == _K.warn ? D.amber : D.red);
        return Text.rich(TextSpan(children: [
          TextSpan(text: '${l.time}  ', style: tm),
          TextSpan(text: '$who  ', style: ts(12.5, color: D.mut2, mono: true)),
          TextSpan(text: l.text, style: ts(12.5, color: col, mono: true)),
        ]));
    }
  }

  Widget _terminal() {
    final lines = _tab == 3 ? _log : _log.where((l) => l.u == _tab || l.u < 0).toList();
    final names = ['İHA-1', 'İHA-2', 'İHA-3', 'TÜMÜ'];
    final light = isLight;
    // Terminal açık temada da koyu bir "ada"dır; widget renkleri [D] paletinden gelir.
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: D.termLine))),
          child: Row(children: [
            Text('KOMUT TERMİNALİ', style: ts(13.5, color: D.text, w: FontWeight.w700, ls: 1.2)),
            gap(12),
            for (int i = 0; i < 4; i++)
              GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tag(names[i], kind: _tab == i ? TagKind.on : TagKind.normal, height: 28, fontSize: 11.5, ls: 1, dark: true),
                ),
              ),
            const Spacer(),
            const Tag('● MAVLink bağlı', kind: TagKind.on, height: 28, fontSize: 11.5, ls: .4, dark: true),
          ]),
        ),
        Expanded(
          child: Container(
            color: D.term,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: ListView.builder(
              controller: _scroll,
              itemCount: lines.length,
              itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: _lineW(lines[i])),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(color: D.term, border: Border(top: BorderSide(color: D.termLine))),
          child: Row(
            children: [
              Text('${_tab == 3 ? "tümü" : "uav${_tab + 1}"}>', style: ts(13.5, color: D.green, mono: true, w: FontWeight.w700)),
              gap(8),
              Expanded(
                child: Focus(
                  onKeyEvent: (node, e) {
                    _key(e);
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _ctl,
                    focusNode: _focus,
                    onSubmitted: _submit,
                    style: ts(13.5, color: D.text, mono: true),
                    cursorColor: D.green,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'komut yazın…  ör. takeoff 20',
                      hintStyle: ts(13.5, color: D.mut, mono: true),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (light) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1519),
          borderRadius: BorderRadius.circular(8),
          boxShadow: L.shadow,
        ),
        child: inner,
      );
    }
    return Panel(padding: EdgeInsets.zero, child: inner);
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'SÜRÜ İHA // KOMUT MERKEZİ',
      body: ValueListenableBuilder<bool>(
        valueListenable: raceMode,
        builder: (context, race, _) {
          if (race) {
            return const LockedNotice(
              title: 'KOMUT MERKEZİ KİLİTLİ',
              lines: [
                'Yarışma Modu aktif: İHA başına manuel komut, terminal ve simülasyon devre dışıdır.',
                'Görev tüm sürü için tek "GÖREVİ BAŞLAT" komutuyla, otonom olarak yürütülür.',
                'Komut Merkezi yalnızca "TEST / SİMÜLASYON MODU"nda kullanılabilir.',
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    children: [
                      for (int u = 0; u < 3; u++) ...[
                        if (u > 0) gap(8),
                        Expanded(flex: _sel == -1 ? 10 : (_sel == u ? 24 : 6), child: _card(u, mini: _sel != -1 && _sel != u)),
                      ],
                    ],
                  ),
                ),
                gap(8),
                Expanded(flex: 10, child: _terminal()),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Yandan görünüşlü sahne: gökyüzü, uzak dağlar (paralaks), pist, gölge ve uçak.
class _ScenePainter extends CustomPainter {
  _ScenePainter(this.s, this.t, this.id);
  final _Sim s;
  final double t;
  final int id;

  @override
  void paint(Canvas c, Size z) {
    final w = z.width, h = z.height;
    final gy = h * .8; // zemin çizgisi
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lc(0xFF16323F), lc(0xFF2B5560), lc(0xFF5E8A8C)]).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // bulutlar
    final cl = Paint()..color = rgba(0xFFFFFF, .07);
    for (int i = 0; i < 3; i++) {
      final x = ((i * w * .45 - t * 6) % (w + 120)) - 60;
      c.drawOval(Rect.fromCenter(center: Offset(x, h * (.25 + i * .08)), width: 90, height: 14), cl);
    }
    c.drawCircle(Offset(w * .82, h * .2), h * .06, Paint()..color = rgba(0xF6E3B0, .8));
    final moving = s.speed > .5 && s.ph != Ph.ground;
    final sp = moving ? s.speed : 0.0;
    _mountains(c, w, gy, h * .22, t * sp * 3, rgba(0x28464C), 0.9);
    _mountains(c, w, gy, h * .14, t * sp * 7, rgba(0x1E3A3F), 1.7);
    c.drawRect(Rect.fromLTWH(0, gy, w, h - gy), Paint()..color = rgba(0x1B2E2A));
    // pist
    final rw = (h - gy) * .55;
    c.drawRect(Rect.fromLTWH(0, gy + 2, w, rw), Paint()..color = rgba(0x2B3438));
    final dash = Paint()..color = rgba(0xE8EEF0, .7);
    final off = (t * sp * 22) % 56;
    for (double x = -56 + off; x < w; x += 56) {
      c.drawRect(Rect.fromLTWH(x, gy + 2 + rw / 2 - 1, 28, 2), dash);
    }
    drawTextSmall(c, 'HOME', Offset(w * .18 - (moving ? 0 : 0), gy + 2 + rw + 8));
    // çok rotorlu İHA
    final alt = s.alt;
    final yPlane = gy - 10 - (alt / 60).clamp(0.0, 1.0) * (gy - h * .28);
    final xPlane = w * (s.ph == Ph.ground ? .3 : .5);
    final shW = 52 * (1 - (alt / 120).clamp(0.0, .6));
    c.drawOval(Rect.fromCenter(center: Offset(xPlane, gy + 2 + rw * .5), width: shW, height: 6), Paint()..color = rgba(0x000000, .35));
    if (alt > 2) {
      c.drawLine(Offset(xPlane, yPlane + 10), Offset(xPlane, gy), Paint()..color = rgba(0xFFFFFF, .08));
    }
    double tilt = 0;
    if (s.ph == Ph.takeoff) tilt = -12;
    if (s.ph == Ph.land) tilt = 7;
    if (s.ph == Ph.rtl) tilt = -3;
    final bob = moving ? math.sin(t * 3 + id) * 1.5 : 0.0;
    c.save();
    c.translate(xPlane, yPlane + bob);
    c.rotate(tilt * math.pi / 180);
    if (moving) {
      final wl = Paint()
        ..color = rgba(0xFFFFFF, .18)
        ..strokeWidth = 1;
      for (int i = 0; i < 3; i++) {
        final xx = -50 - ((t * 120 + i * 40) % 80);
        c.drawLine(Offset(xx, -6 + i * 6), Offset(xx - 24, -6 + i * 6), wl);
      }
    }
    _plane(c, math.min(h * .32, 120), s.arm);
    c.restore();
  }

  void drawTextSmall(Canvas c, String t, Offset at) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontSize: 9, color: rgba(0x8BA0A5), letterSpacing: 1)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, at);
  }

  void _mountains(Canvas c, double w, double gy, double mh, double scroll, Color col, double freq) {
    final p = Path()..moveTo(0, gy);
    for (double x = 0; x <= w + 8; x += 8) {
      final u = (x + scroll) * .012 * freq;
      p.lineTo(x, gy - mh * (.55 + .3 * math.sin(u) + .15 * math.sin(u * 2.3 + 1)));
    }
    p.lineTo(w, gy);
    p.close();
    c.drawPath(p, Paint()..color = col);
  }

  /// Çok rotorlu (quadcopter) İHA – yandan görünüm, genişlik ≈ len.
  void _plane(Canvas c, double len, bool armed) {
    c.scale(len / 100);
    final body = Paint()..color = lc(0xFFDCE4E6);
    final dark = Paint()..color = lc(0xFF8CA0A5);
    final arm = Paint()
      ..color = lc(0xFF6F8388)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // iniş takımı
    final leg = Paint()
      ..color = lc(0xFF8CA0A5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-14, 8), const Offset(-20, 20), leg);
    c.drawLine(const Offset(14, 8), const Offset(20, 20), leg);
    c.drawLine(const Offset(-26, 20), const Offset(-14, 20), leg);
    c.drawLine(const Offset(14, 20), const Offset(26, 20), leg);
    // kollar
    c.drawLine(const Offset(-10, -2), const Offset(-42, -10), arm);
    c.drawLine(const Offset(10, -2), const Offset(42, -10), arm);
    // gövde
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -8, 32, 16), const Radius.circular(6)), body);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-9, 2, 18, 6), const Radius.circular(2)), dark);
    c.drawCircle(const Offset(10, -1), 3, Paint()..color = lc(0xFF4DB2FF));
    // motor + pervane
    final ang = armed ? (DateTime.now().millisecondsSinceEpoch / 30) : 0.0;
    final pr = Paint()
      ..color = rgba(0xFFFFFF, armed ? .35 : .85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final ph = armed ? 16 * math.sin(ang) : 16.0;
    for (final x in const [-42.0, 42.0]) {
      c.drawRect(Rect.fromLTWH(x - 3, -14, 6, 5), dark);
      c.drawLine(Offset(x - ph, -16), Offset(x + ph, -16), pr);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter o) => true;
}
