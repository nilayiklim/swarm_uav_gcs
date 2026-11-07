import 'package:flutter/material.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// KONTROL (ana ekran) – tasarım: görev adımları, İHA telemetri, harita, kameralar, QR, HUD, log.
class KontrolPage extends StatelessWidget {
  const KontrolPage({super.key, this.onOpenIha});

  /// İHA kartına dokununca Tek İHA ekranını açar.
  final VoidCallback? onOpenIha;

  Widget _steps() {
    const labels = [
      '1. BEKLE', '2. KALKIŞ', '3. FORMASYON', '[4. QR OKUMA]', '5. MANEVRA', '6. AYRILMA', '7. DÖNÜŞ', '8. İNİŞ'
    ];
    final children = <Widget>[];
    for (int i = 0; i < labels.length; i++) {
      final active = i == 3;
      children.add(Text(
        labels[i],
        style: ts(12,
            color: active ? const Color(0xFF4BE88D) : C.label,
            w: active ? FontWeight.w700 : FontWeight.w400,
            ls: 1.4),
      ));
      if (i < labels.length - 1) children.add(Text('→', style: ts(14, color: C.label)));
    }
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14262C), Color(0xFF0F1D22)],
        ),
        border: const Border(bottom: BorderSide(color: Color(0xFF223439))),
        boxShadow: [BoxShadow(color: rgba(0x3FD97F, .12), offset: const Offset(0, 1))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children),
    );
  }

  Widget _tele(String n, String pct, Color pc, String alt, String bat, {String? tagText, bool bad = false}) {
    final line = ts(14, color: const Color(0xFFD5E0E2), h: 1.55);
    return InkWell(
      onTap: onOpenIha,
      child: GCard(
        bad: bad,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(n, style: ts(19, w: FontWeight.w700)),
                gap(10),
                Text(pct, style: ts(22, color: pc, w: FontWeight.w700)),
                const Spacer(),
                if (tagText != null)
  Flexible(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Tag(tagText, kind: TagKind.red, fontSize: 10, ls: 0, height: 22),
    ),
  )
                else ...[
                  const Tag('0.4s', height: 22, fontSize: 11),
                  gap(8),
                  Text('LIVE', style: ts(12, color: C.green, w: FontWeight.w600)),
                ],
              ],
            ),
            gap(4),
            Text('Alt: $alt m      Bat: $bat V', style: line),
            Text('Hız: 10.1 m/s', style: line),
            Text('GPS: 11 / HDOP: 1.1', style: line),
          ],
        ),
      ),
    );
  }

  Widget _camLabel(String l, String r) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: rgba(0x000000, .75), borderRadius: BorderRadius.circular(2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(l, style: ts(13)), Text(r, style: ts(13))],
        ),
      );

  Widget _thumb(String name, Offset pos, double rot) => AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: TerrainPainter(planePos: pos, planeRot: rot, planeSize: 90)),
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: rgba(0x000000, .8), borderRadius: BorderRadius.circular(2)),
                  child: Text(name, style: ts(12.5)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _inst(Widget painter, double ratio, String caption) => Column(
        children: [
          Expanded(
            child: Center(child: AspectRatio(aspectRatio: ratio, child: painter)),
          ),
          gap(3),
          Text(caption, maxLines: 1, overflow: TextOverflow.clip, style: ts(8.5, color: C.label, w: FontWeight.w600, ls: .8)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final top = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 23,
          child: Panel(
            title: 'İHA TELEMETRİ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tele('İHA-1', '88%', C.green, '37.7', '15.8'),
                gap(8),
                _tele('İHA-2', '76%', C.green, '37.5', '15.1'),
                gap(8),
                _tele('İHA-3', '64%', C.red, '37.7', '14.6', tagText: 'AYRILDI - MAVİ ALAN 12s', bad: true),
              ],
            ),
          ),
        ),
        gap(8),
        Expanded(
          flex: 54,
          child: Panel(
            title: 'SÜRÜ KONUMU & HARİTA',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: MapPainter())),
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: Tag('Formasyon Hatası: 0.2m | Min Mesafe: 14.8m', fontSize: 13, ls: 0, height: 26),
                  ),
                ],
              ),
            ),
          ),
        ),
        gap(8),
        Expanded(
          flex: 23,
          child: Panel(
            title: 'KAMERA YAYINLARI',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(painter: TerrainPainter(planePos: const Offset(360, 170), planeRot: -60, planeSize: 80)),
                        Positioned(left: 6, right: 6, top: 6, child: _camLabel('İHA-1 KAMERA', '16:9')),
                      ],
                    ),
                  ),
                ),
                gap(8),
                Row(
                  children: [
                    Expanded(child: _thumb('İHA-2', const Offset(330, 190), -20)),
                    gap(8),
                    Expanded(child: _thumb('İHA-3', const Offset(300, 200), 15)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final qr = Panel(
      title: 'QR ÇÖZÜMLEME',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 1; i <= 5; i++) ...[
            if (i > 1) gap(6),
            Expanded(
              child: GCard(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR-$i', maxLines: 1, style: ts(14, w: FontWeight.w700)),
                    gap(4),
                    if (i == 1) ...[
                      Text('Çözüldü', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10.5, color: C.green)),
                      gap(4),
                      Text('FORM=V', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10.5, color: C.mut2)),
                    ] else if (i == 2)
                      Text('Okunuyor', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10.5, color: C.amber)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final area = Panel(
      title: 'RENKLİ ALAN & GERİ DÖNÜŞ SAYACI',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1A1D),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF27393F)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: 'KIRMIZI: ', style: ts(17, color: C.red)),
              TextSpan(text: 'Hazır', style: ts(17, color: C.green)),
            ])),
            gap(5),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'MAVİ: ', style: ts(17, color: C.blue)),
              TextSpan(text: '12s', style: ts(17, color: C.blue)),
            ])),
            gap(5),
            Text('Geri Dönüş: 11.2m', style: ts(17, color: C.mut)),
            gap(5),
            Text('Min. Dönüş Süresi: 12:23', style: ts(17, color: C.mut)),
          ],
        ),
      ),
    );

    final hud = Panel(
      title: 'HUD',
      child: Row(
        children: [
          Expanded(flex: 11, child: _inst(CustomPaint(painter: CompassPainter(112)), 1, 'HDG · 112°')),
          gap(6),
          Expanded(flex: 11, child: _inst(CustomPaint(painter: HorizonPainter(-2.1, 1.4)), 1, 'ATT · R −2.1° P +1.4°')),
          gap(6),
          Expanded(flex: 6, child: _inst(CustomPaint(painter: AltTapePainter(37.8)), .625, 'ALT · 37.8 m')),
        ],
      ),
    );

    Widget logRow(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t, style: ts(13.5)),
              const Tag('x5', height: 20, fontSize: 12, ls: 0),
            ],
          ),
        );

    final log = Panel(
      title: 'LOG',
      trailing: Text('● CANLI/LİVE', style: ts(12, color: C.green, w: FontWeight.w600)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LogLine('[14:12:01] Telemetri aktif', color: C.green),
          logRow('[14:12:01] Formasyon korundu'),
          logRow('[14:12:20] Formasyon korundu'),
          logRow('[14:12:20] Formasyon korundu'),
          logRow('[14:12:20] Formasyon korundu'),
        ],
      ),
    );

    return PageFrame(
      title: 'SÜRÜ İHA // GÖREV KONTROL',
      simple: true,
      extra: _steps(),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(child: top),
            gap(8),
            SizedBox(
              height: 228,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 23, child: qr),
                  gap(8),
                  Expanded(
                    flex: 54,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Expanded(child: area), gap(8), Expanded(child: hud)],
                    ),
                  ),
                  gap(8),
                  Expanded(flex: 23, child: log),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
