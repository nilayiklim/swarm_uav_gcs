import 'package:flutter/material.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// TELEMETRİ – anlık değerler, zaman grafikleri ve ham veri bölümleri.
class TelemetriPage extends StatelessWidget {
  const TelemetriPage({super.key});

  Widget _kpi(String label, String v, String u, Color c, int tint,
      {String? sub, String? tag, double vs = 42}) {
    return Expanded(
      child: GCard(
        tint: rgba(tint, .16),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(label, style: ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.8)),
              const Spacer(),
              if (tag != null) Tag(tag, height: 22, fontSize: 11.5, ls: .4),
            ]),
            Expanded(
              child: Center(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: v, style: ts(vs, color: c, w: FontWeight.w300, ls: -.5)),
                  TextSpan(text: u, style: ts(18, color: c)),
                ])),
              ),
            ),
            if (sub != null) Text(sub, textAlign: TextAlign.center, style: ts(13, color: C.mut)),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    Widget it(String n, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 18, height: 3, color: c),
          gap(6),
          Text(n, style: ts(12.5)),
        ]);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [it('İHA-1', C.green), gap(16), it('İHA-2', C.blue), gap(16), it('İHA-3', C.amber)],
    );
  }

  Widget _chart(String title, CustomPainter painter) => Expanded(
        child: Panel(
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _legend(),
              gap(6),
              Expanded(child: CustomPaint(painter: painter)),
            ],
          ),
        ),
      );

  Widget _acc(String t) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF2A4046)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF183137), Color(0xFF12232A)],
            ),
          ),
          child: Row(children: [
            Text('▸', style: ts(13, color: C.mut)),
            gap(12),
            Text(t, style: ts(15.5)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const green = C.green;
    const blue = C.blue;
    const amber = C.amber;

    final battery = LineChartPainter(
      yLabels: const ['100%', '80%', '60%', '40%', '20%', '0%'],
      thresholds: const [
        ChartThreshold(187, amber, '30% Uyarı'),
        ChartThreshold(208, Color(0xFFFF7A75), '20% Kritik', labelAbove: false),
      ],
      lines: const [
        ChartLine(green, [Offset(60, 40), Offset(150, 82), Offset(240, 118), Offset(330, 152), Offset(420, 178), Offset(480, 194), Offset(540, 204)]),
        ChartLine(blue, [Offset(60, 40), Offset(150, 88), Offset(240, 126), Offset(330, 160), Offset(420, 184), Offset(480, 198), Offset(540, 208)]),
        ChartLine(amber, [Offset(60, 40), Offset(150, 78), Offset(240, 114), Offset(330, 148), Offset(420, 174), Offset(480, 190), Offset(540, 200)]),
      ],
    );

    final alt = LineChartPainter(
      yLabels: const ['50', '40', '30', '20', '10', '0'],
      lines: const [
        ChartLine(green, [Offset(60, 250), Offset(90, 170), Offset(120, 128), Offset(160, 118), Offset(200, 96), Offset(240, 112), Offset(280, 86), Offset(320, 104), Offset(360, 70), Offset(400, 98), Offset(440, 84), Offset(480, 74), Offset(540, 82)]),
        ChartLine(blue, [Offset(60, 250), Offset(90, 176), Offset(120, 140), Offset(160, 132), Offset(200, 120), Offset(240, 136), Offset(280, 114), Offset(320, 130), Offset(360, 108), Offset(400, 122), Offset(440, 110), Offset(480, 118), Offset(540, 106)]),
        ChartLine(amber, [Offset(60, 250), Offset(90, 182), Offset(120, 150), Offset(160, 140), Offset(200, 150), Offset(240, 128), Offset(280, 152), Offset(320, 138), Offset(360, 160), Offset(400, 134), Offset(440, 150), Offset(480, 128), Offset(540, 142)]),
      ],
    );

    final dist = LineChartPainter(
      yLabels: const ['25', '20', '15', '10', '5', '0'],
      thresholds: const [ChartThreshold(208, Color(0xFFFF7A75), '5.0m Eşitlik / Güvenlik')],
      lines: const [
        ChartLine(green, [Offset(60, 110), Offset(100, 150), Offset(140, 96), Offset(180, 134), Offset(220, 150), Offset(260, 112), Offset(300, 98), Offset(340, 138), Offset(380, 150), Offset(420, 120), Offset(460, 104), Offset(500, 92), Offset(540, 76)]),
        ChartLine(blue, [Offset(60, 150), Offset(100, 120), Offset(140, 160), Offset(180, 100), Offset(220, 126), Offset(260, 152), Offset(300, 132), Offset(340, 108), Offset(380, 128), Offset(420, 152), Offset(460, 130), Offset(500, 116), Offset(540, 124)]),
        ChartLine(amber, [Offset(60, 130), Offset(100, 100), Offset(140, 126), Offset(180, 150), Offset(220, 110), Offset(260, 92), Offset(300, 120), Offset(340, 148), Offset(380, 112), Offset(420, 96), Offset(460, 118), Offset(500, 140), Offset(540, 128)]),
      ],
    );

    return PageFrame(
      title: 'SÜRÜ İHA // TELEMETRİ',
      battery: '1015',
      bar: EmVariant.telemetri,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text('Anlık değerler:', style: ts(13.5, color: C.mut)),
              gap(12),
              const Tag('İHA-1', kind: TagKind.on, height: 32, fontSize: 12.5),
              gap(8),
              const Tag('İHA-2', height: 32, fontSize: 12.5),
              gap(8),
              const Tag('İHA-3', height: 32, fontSize: 12.5),
            ]),
            gap(8),
            SizedBox(
              height: 116,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kpi('BATARYA', '88', '%', C.green, 0xB5E61D, tag: '15.8V · 8.0A', vs: 46),
                  gap(8),
                  _kpi('İRTİFA', '37.8', 'm', C.blue, 0x22D3EE),
                  gap(8),
                  _kpi('HIZ', '9.2', 'm/s', C.amber, 0xF59E0B),
                  gap(8),
                  _kpi('GPS', '12', ' Uydu', C.green, 0x3FD97F, sub: '3D FIX · HDOP 0.8'),
                  gap(8),
                  _kpi('YÖN', '112°', '', C.text, 0x2DD4BF, sub: 'DOĞU'),
                ],
              ),
            ),
            gap(8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _chart('BATARYA (%)', battery),
                  gap(8),
                  _chart('İRTİFA (m)', alt),
                  gap(8),
                  _chart('İHA ARASI EN KÜÇÜK MESAFE (m)', dist),
                ],
              ),
            ),
            gap(8),
            SizedBox(
              height: 152,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _acc('Attitude & IMU Ham Veri Özeti'),
                        gap(8),
                        _acc('GPS Raw & HDOP Tablosu'),
                        gap(8),
                        _acc('VFR HUD & Sistem Durumu (CPU 35%)'),
                      ],
                    ),
                  ),
                  gap(8),
                  SizedBox(
                    width: 300,
                    child: Panel(
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: MetalButton('TELEMETRİ KAYDI & CSV İNDİR  ⤓', kind: BtnKind.accent, height: 56, fontSize: 12.5, ls: 1.2, hPad: 8),
                        ),
                      ),
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
