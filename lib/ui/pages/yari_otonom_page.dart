import 'package:flutter/material.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// YARI OTONOM – joystick ile sürü kontrolü, formasyon seçici ve hareket parametreleri.
class YariOtonomPage extends StatelessWidget {
  const YariOtonomPage({super.key});

  Widget _rd(String l, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0D191C),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF27424A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l, style: ts(10, color: C.mut, ls: .6)),
            Text(v, style: ts(14, color: C.green, w: FontWeight.w700)),
          ],
        ),
      );

  Widget _stick(String title, double dx, double dy, String l1, String v1, String l2, String v2) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, maxLines: 1, style: ts(12, color: const Color(0xFFCFE0E3), w: FontWeight.w600, ls: 1)),
        gap(4),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: JoystickPainter(dx, dy))),
          ),
        ),
        gap(2),
        Row(children: [Expanded(child: _rd(l1, v1)), gap(4), Expanded(child: _rd(l2, v2))]),
      ],
    );
  }

  Widget _tr(List<String> c, {Color? batColor, bool head = false}) {
    TextStyle st(int i) {
      if (head) return ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.6);
      if (i == 1 && batColor != null) return ts(14, color: batColor);
      if (i == 3) return ts(14, color: C.green);
      return ts(14);
    }

    const flex = [3, 3, 2, 3];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
      child: Row(
        children: [for (int i = 0; i < c.length; i++) Expanded(flex: flex[i], child: Text(c[i], style: st(i)))],
      ),
    );
  }

  Widget _uav(String n, double v, Color c) => GCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(n, style: ts(15, w: FontWeight.w700)),
                Text('● LIVE', style: ts(12, color: C.green, w: FontWeight.w600)),
              ],
            ),
            gap(6),
            Container(
              height: 5,
              color: const Color(0xFF0E181B),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: v, child: Container(color: c)),
            ),
          ],
        ),
      );

  Widget _fm(int k, String label, bool on) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: on ? C.green : const Color(0xFF33505A)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on ? const [Color(0xFF17402F), Color(0xFF102A20)] : const [Color(0xFF203A41), Color(0xFF18292E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 58, height: 38, child: CustomPaint(painter: FormationIconPainter(k))),
            gap(4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13.5, color: on ? C.green : C.text)),
          ],
        ),
      );

  Widget _pm(String l, String v) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: C.cardLine),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1417), Color(0xFF10201F)],
            ),
          ),
          child: Column(
            children: [
              Text(l, style: ts(11.5, color: C.mut2)),
              gap(2),
              Text(v, style: ts(15.5, w: FontWeight.w700)),
            ],
          ),
        ),
      );

  Widget _key(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$k   ', style: ts(13.5, w: FontWeight.w700, color: C.text)),
          TextSpan(text: v, style: ts(13.5, color: const Color(0xFFC8D6D9))),
        ])),
      );

  @override
  Widget build(BuildContext context) {
    final joystick = Panel(
      title: 'JOYSTICK DENETİMİ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF123325),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF2E8F5A)),
            ),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'JOYSTICK AKTİF', style: ts(14, color: C.green, w: FontWeight.w700)),
                TextSpan(text: ' (Sinyal Kesilirse:\nSürü Havada Sabit Bekler / Hover)', style: ts(14, h: 1.45)),
              ]),
              textAlign: TextAlign.center,
            ),
          ),
          gap(10),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _stick('THR / YAW', 0, 0, 'THR', '50%', 'YAW', '0°')),
                gap(6),
                Expanded(child: _stick('ROLL / PITCH', 8, -12, 'ROLL', '+4°', 'PITCH', '+6°')),
              ],
            ),
          ),
        ],
      ),
    );

    final map = Panel(
      title: 'SÜRÜ KONUMU & HARİTA',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: FormationMapPainter())),
            const Positioned(
              left: 12,
              top: 12,
              child: Tag('Merkez Kayması: 0.1m | Hedeften Sapma: 0.2m', fontSize: 13, ls: 0, height: 26),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: SizedBox(width: 84, height: 84, child: CustomPaint(painter: RadarPainter())),
            ),
          ],
        ),
      ),
    );

    final summary = Panel(
      title: 'SÜRÜ ÖZETİ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tr(const ['İHA', 'BATARYA', 'UYDU', 'DURUM'], head: true),
          _tr(const ['İHA-1', '88 %', '12', 'BAĞLI']),
          _tr(const ['İHA-2', '76 %', '11', 'BAĞLI']),
          _tr(const ['İHA-3', '64 %', '11', 'BAĞLI'], batColor: C.red),
          PanelTitle('GÖREV KAYDI', topGap: 14, trailing: Text('● CANLI/LİVE', style: ts(12, color: C.green, w: FontWeight.w600))),
          const LogLine('[14:12:01] Telemetri aktif', color: C.green),
          const LogLine('[14:12:05] Formasyon korundu (V-Tipi)'),
          const LogLine('[14:12:05] Formasyon korundu'),
          const LogLine('[14:12:02] Formasyon sapması (V-Tipi)', color: C.amber),
          const LogLine('[14:12:20] Formasyon korundu'),
          const LogLine('[14:12:10] Waypoint WP-02 geçildi'),
        ],
      ),
    );

    final uavs = Panel(
      title: 'İHA LİSTESİ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _uav('İHA-1', .88, C.green),
          gap(8),
          _uav('İHA-2', .76, C.green),
          gap(8),
          _uav('İHA-3', .64, C.red),
        ],
      ),
    );

    final formation = Panel(
      title: 'FORMASYON SEÇİCİ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _fm(0, 'V Formasyon', true)),
                gap(8),
                Expanded(child: _fm(1, 'Ok Formasyon', false)),
                gap(8),
                Expanded(child: _fm(2, 'Çizgi Formasyon', false)),
                gap(8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Ajanlar arası mesafe (m)', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13)),
                        gap(8),
                        const FakeSlider(.42),
                        gap(6),
                        Text('15.0 m', textAlign: TextAlign.center, style: ts(15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PanelTitle('HAREKET PARAMETRELERİ', topGap: 6),
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _pm('Yaw Hızı', '10°/s'),
                gap(8),
                _pm('Yaw İvmesi', '10°/s²'),
                gap(8),
                _pm('Hız', '1.0 m/s'),
                gap(8),
                _pm('İvme', '1.0 m/s²'),
              ],
            ),
          ),
        ],
      ),
    );

    final keys = Panel(
      title: 'TUŞ ATAMALARI',
      trailing: const Tag('AÇ ▾', height: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _key('W / S', 'ileri / geri'),
          _key('A / D', 'sol / sağ'),
          _key('↑ / ↓', 'yükseklik'),
          _key('← / →', 'dönüş (yaw)'),
        ],
      ),
    );

    return PageFrame(
      title: 'SÜRÜ İHA // YARI OTONOM',
      bar: EmVariant.yari,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 24, child: joystick),
                  gap(8),
                  Expanded(flex: 52, child: map),
                  gap(8),
                  Expanded(flex: 24, child: summary),
                ],
              ),
            ),
            gap(8),
            SizedBox(
              height: 250,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 24, child: uavs),
                  gap(8),
                  Expanded(flex: 52, child: formation),
                  gap(8),
                  Expanded(flex: 24, child: keys),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
