import 'package:flutter/material.dart';
import '../painters.dart';
import '../swarm_map.dart';
import '../theme.dart';
import '../uav_data.dart';
import '../widgets.dart';

/// ANA SAYFA – büyük etkileşimli sürü haritası + seçili İHA için detaylı HUD.
/// (İHA telemetri kutucukları tüm sayfalarda en üstte, bkz. UavStrip.)
class KontrolPage extends StatefulWidget {
  const KontrolPage({super.key});

  @override
  State<KontrolPage> createState() => _KontrolPageState();
}

class _KontrolPageState extends State<KontrolPage> {
  int _sel = 0;

  Widget _ro(String label, String value, {Color? color}) => Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: C.cardLine),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1417), Color(0xFF10201F)],
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ts(9.5, color: C.label, w: FontWeight.w600, ls: 1.2)),
              gap(2),
              Text(value, style: ts(16, color: color ?? C.text, w: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _tab(int i) {
    final on = i == _sel;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () => setState(() => _sel = i),
        child: Tag('İHA-${i + 1}', kind: on ? TagKind.on : TagKind.normal, height: 26, fontSize: 11),
      ),
    );
  }

  Widget _hud() {
    final u = kUavs[_sel];
    return Panel(
      title: 'HUD',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [for (int i = 0; i < kUavs.length; i++) _tab(i)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 440 / 404,
            child: CustomPaint(painter: BigAttitudePainter(roll: u.roll, pitch: u.pitch, heading: u.heading)),
          ),
          gap(8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      Expanded(child: Center(child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: CompassPainter(u.heading))))),
                      gap(3),
                      Text('HDG · ${u.heading.toStringAsFixed(0)}°', style: ts(9.5, color: C.label, w: FontWeight.w600, ls: .8)),
                    ],
                  ),
                ),
                gap(8),
                Expanded(
                  flex: 11,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('YER HIZI', '${u.speed.toStringAsFixed(1)} m/s')),
                          gap(6),
                          Expanded(child: _ro('DİKEY HIZ', '${u.vspeed >= 0 ? '+' : '−'}${u.vspeed.abs().toStringAsFixed(1)} m/s')),
                        ]),
                      ),
                      gap(6),
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('İRTİFA', '${u.alt.toStringAsFixed(1)} m')),
                          gap(6),
                          Expanded(child: _ro('BATARYA', '${u.pct}% · ${u.bat.toStringAsFixed(1)}V', color: u.pctColor)),
                        ]),
                      ),
                      gap(6),
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('ROLL', '${u.roll >= 0 ? '+' : '−'}${u.roll.abs().toStringAsFixed(1)}°')),
                          gap(6),
                          Expanded(child: _ro('PITCH', '${u.pitch >= 0 ? '+' : '−'}${u.pitch.abs().toStringAsFixed(1)}°')),
                        ]),
                      ),
                      gap(6),
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('GPS', '${u.gps} uydu')),
                          gap(6),
                          Expanded(child: _ro('HDOP', u.hdop.toStringAsFixed(1))),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'SÜRÜ İHA // ANA SAYFA',
      simple: true,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 68,
              child: Panel(
                title: 'SÜRÜ KONUMU & HARİTA',
                child: KeepDark(child: SwarmMap(selected: _sel, onSelect: (i) => setState(() => _sel = i))),
              ),
            ),
            gap(8),
            Expanded(flex: 32, child: KeepDark(child: _hud())),
          ],
        ),
      ),
    );
  }
}
