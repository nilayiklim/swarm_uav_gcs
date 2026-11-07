import 'package:flutter/material.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// TEK İHA KONTROL – tek bir İHA için detaylı kontrol ve ön uçuş denetimleri.
class TekIhaPage extends StatelessWidget {
  const TekIhaPage({super.key});

  Widget _tab(String name, String info, Color ic, bool on) {
    return Expanded(
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: on ? C.green : const Color(0xFF27393F)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on ? const [Color(0xFF1A4A38), Color(0xFF10301F)] : const [Color(0xFF1B3238), Color(0xFF13242A)],
          ),
          boxShadow: on ? [BoxShadow(color: rgba(0x3FD97F, .2), blurRadius: 16)] : null,
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$name  ', style: ts(14, w: FontWeight.w600, ls: 1.1)),
          TextSpan(text: info, style: ts(14, color: ic, ls: 1.1)),
        ])),
      ),
    );
  }

  Widget _big(String label, String v, String u) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.8)),
          Text.rich(TextSpan(children: [
            TextSpan(text: v, style: ts(46, w: FontWeight.w300, ls: -.9, h: 1.05)),
            TextSpan(text: u, style: ts(22, color: const Color(0xFFC8D6D9))),
          ])),
        ],
      );

  Widget _kv(String k, String v, Color vc) => Text.rich(TextSpan(children: [
        TextSpan(text: '$k ', style: ts(15)),
        TextSpan(text: v, style: ts(15, color: vc, w: FontWeight.w700)),
      ]));

  Widget _ro(String l, String v, [String? sub]) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l, style: ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.8)),
          Text.rich(TextSpan(children: [
            TextSpan(text: v, style: ts(30, w: FontWeight.w600)),
            if (sub != null) TextSpan(text: ' $sub', style: ts(16, color: C.mut)),
          ])),
        ],
      );

  Widget _cmd(String t, Color c, {bool dim = false}) => Expanded(
        child: Column(
          children: [
            Dot(color: c, size: 18, glow: !dim),
            gap(6),
            Text(t, style: ts(14, color: dim ? C.mut : C.text)),
          ],
        ),
      );

  Widget _check(String t, {bool warn = false}) => Expanded(
        child: Row(
          children: [
            Dot(color: warn ? C.amber : C.green, size: 10),
            gap(8),
            Flexible(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final numbers = Panel(
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(child: _big('BATARYA', '88', '%')),
            gap(18),
            Expanded(child: _big('İRTİFA', '37.7', 'm')),
          ]),
          gap(10),
          Row(children: [
            Expanded(child: _big('HIZ', '10.1', 'm/s')),
            gap(18),
            Expanded(child: _big('YKİ UZAKLIK', '42', 'm')),
          ]),
          gap(14),
          Row(children: [
            Expanded(child: _kv('MOD:', 'GUIDED', C.green)),
            Expanded(child: _kv('GPS:', '12 Uydu HDOP 0.8', C.green)),
          ]),
          gap(6),
          Row(children: [
            Expanded(child: _kv('EKF & TİTREŞİM:', 'NORMAL', C.green)),
            Expanded(child: _kv('Son Veri:', '0.3s', C.text)),
          ]),
        ],
      ),
    );

    final controls = Panel(
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('Kalkış İrtifası: 10m', style: ts(16)),
            const Spacer(),
            const SizedBox(width: 92, child: FieldBox('10m', unit: '⇅', fontSize: 16)),
          ]),
          gap(10),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF101C1F),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: C.cardLine),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: .34,
                    child: Container(color: rgba(0x3FD97F, .25)),
                  ),
                  Center(child: Text('HOLD-TO-CONFIRM', style: ts(12.5, color: C.mut2, ls: 1.6))),
                ],
              ),
            ),
          ),
          gap(10),
          Row(children: const [
            Expanded(child: MetalButton('ARM / DISARM', height: 44, fontSize: 11, ls: 1, hPad: 4)),
            SizedBox(width: 8),
            Expanded(child: MetalButton('KALKIŞ', height: 44, fontSize: 11.5, ls: 1.2, hPad: 4)),
            SizedBox(width: 8),
            Expanded(child: MetalButton('İNİŞ', height: 44, fontSize: 11.5, ls: 1.2, hPad: 4)),
          ]),
          gap(8),
          Row(children: const [
            Expanded(flex: 1, child: MetalButton('RTL', height: 44, fontSize: 11.5, ls: 1.2, hPad: 4)),
            SizedBox(width: 8),
            Expanded(flex: 2, child: MetalButton('DURDUR / SÜRDÜR', height: 44, fontSize: 11.5, ls: 1.2, hPad: 4)),
          ]),
        ],
      ),
    );

    final status = Panel(
      title: 'COMMAND STATUS',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cmd('Gönderildi', C.green),
          _cmd('Alındı', C.green),
          _cmd('Uygulanıyor', C.amber),
          _cmd('Hata', const Color(0xFF2D4046), dim: true),
        ],
      ),
    );

    final attitude = Panel(
      child: Row(
        children: [
          Expanded(child: CustomPaint(painter: BigAttitudePainter())),
          SizedBox(
            width: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ro('ROLL', '−2.1°'),
                gap(20),
                _ro('PITCH', '+1.4°'),
                gap(20),
                _ro('HEADING', '112°', 'DOĞU'),
              ],
            ),
          ),
        ],
      ),
    );

    final prearm = Panel(
      title: 'ARDUPILOT PRE-ARM GÜVENLİK KONTROLLERİ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [_check('GPS'), _check('EKF'), _check('IMU')]),
          gap(12),
          Row(children: [_check('Pusula'), _check('Barometre'), _check('Batarya')]),
          gap(12),
          Row(children: [_check('RC / Link'), _check('SD Kart'), _check('Güvenlik anahtarı', warn: true)]),
          const Spacer(),
          Text('Tüm maddeler yeşil olmadan “KALKIŞ” kilitli kalır.', style: ts(13.5, color: C.mut)),
        ],
      ),
    );

    final cam = Panel(
      title: 'İHA-1 CANLI KAMERA YAYINI',
      expand: false,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: RunwayPainter()),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: rgba(0x000000, .75), borderRadius: BorderRadius.circular(2)),
                  child: Text('16:9', style: ts(12.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final log = Panel(
      title: 'İHA-1 GÖREV KAYDI',
      trailing: Text('● CANLI/LİVE', style: ts(12, color: C.green, w: FontWeight.w600)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LogLine('[14:12:01] Telemetri aktif', color: C.green),
          const LogLine('[14:12:05] Formasyon korundu (V-Tipi)'),
          const LogLine('[14:12:05] Formasyon korundu'),
          const LogLine('[14:13:09] Telemetri aktif'),
          const LogLine('[14:12:20] Formasyon korundu'),
          const LogLine('[14:12:10] Waypoint WP-02 geçildi'),
          const Spacer(),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF101C1F),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF33505A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('İHA-1 GÖREV KAYDI', style: ts(14, ls: 1)), Text('▾', style: ts(14, color: C.mut))],
            ),
          ),
        ],
      ),
    );

    return PageFrame(
      title: 'SÜRÜ İHA // TEK İHA KONTROL',
      bar: EmVariant.redTint,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(children: [
              _tab('İHA-1', '[88% ARMED]', C.green, true),
              gap(8),
              _tab('İHA-2', '[76%]', C.mut, false),
              gap(8),
              _tab('İHA-3', '[64%]', C.red, false),
            ]),
            gap(8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 105,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [numbers, gap(8), controls, gap(8), Expanded(child: status)],
                    ),
                  ),
                  gap(8),
                  Expanded(
                    flex: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Expanded(flex: 3, child: attitude), gap(8), Expanded(flex: 2, child: prearm)],
                    ),
                  ),
                  gap(8),
                  Expanded(
                    flex: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [cam, gap(8), Expanded(child: log)],
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
