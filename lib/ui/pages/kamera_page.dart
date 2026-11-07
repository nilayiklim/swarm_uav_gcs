import 'package:flutter/material.dart';
import '../painters.dart';
import '../theme.dart';
import '../widgets.dart';

/// KAMERA – seçili İHA'nın canlı görüntüsü, QR algılama ve akış durumu.
class KameraPage extends StatelessWidget {
  const KameraPage({super.key});

  Widget _ov(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: rgba(0x060C0E, .82),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: rgba(0xFFFFFF, .07)),
        ),
        child: child,
      );

  Widget _thumb(int i, String name, String info, Color ic, bool on) => Container(
        height: 62,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: on ? C.green : C.cardLine, width: on ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: ThumbPainter(i)),
              Positioned(left: 6, top: 6, child: _ov(Text(name, style: ts(12, w: FontWeight.w600)))),
              Positioned(right: 6, bottom: 6, child: _ov(Text(info, style: ts(12, color: ic, w: FontWeight.w600)))),
            ],
          ),
        ),
      );

  Widget _st(String k, String v, {Color c = C.text, bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k, style: ts(14.5, color: C.mut)), Text(v, style: ts(14.5, color: c, w: FontWeight.w700))],
        ),
      );

  Widget _qr(String n, String d, bool ok, bool dim) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
        child: Row(
          children: [
            SizedBox(width: 32, height: 32, child: CustomPaint(painter: QrTilePainter(dim: dim))),
            gap(10),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: n, style: ts(14, w: FontWeight.w700, color: dim ? C.mut : C.text)),
                  TextSpan(text: ' · $d', style: ts(14, color: dim ? C.mut : C.text)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(ok ? '✓' : '…', style: ts(14, color: ok ? C.green : C.mut)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final main = Panel(
      title: 'İHA-1 · ÖN KAMERA',
      padding: const EdgeInsets.all(10),
      trailing: Row(children: const [Tag('● CANLI', kind: TagKind.on), SizedBox(width: 6), Tag('1280×720')]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: QrCameraPainter()),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _ov(Text.rich(TextSpan(children: [
                      TextSpan(text: '● REC ', style: ts(13, color: C.red, w: FontWeight.w600)),
                      TextSpan(text: '00:03:41', style: ts(13, w: FontWeight.w600)),
                    ]))),
                  ),
                  Positioned(right: 10, top: 10, child: _ov(Text('30 FPS · 84 ms · 4.2 Mbps', style: ts(13, w: FontWeight.w600)))),
                  Align(
                    alignment: const Alignment(0, .78),
                    child: _ov(Text('QR-2 okundu · güven %97', style: ts(13, color: C.green, w: FontWeight.w600))),
                  ),
                  Positioned(left: 10, bottom: 10, child: _ov(Text('İrt 37.8 m · Hız 9.2 m/s · Yön 112° DOĞU', style: ts(13, w: FontWeight.w600)))),
                  Positioned(right: 10, bottom: 10, child: _ov(Text('40.12340, 32.56780', style: ts(13, w: FontWeight.w600)))),
                ],
              ),
            ),
          ),
          gap(8),
          Row(
            children: [
              const MetalButton('● KAYIT DURDUR', kind: BtnKind.dangerOutline, height: 44, fontSize: 12, ls: 1.2),
              gap(8),
              const MetalButton('ANLIK GÖRÜNTÜ', height: 44, fontSize: 12, ls: 1.2),
              gap(8),
              const MetalButton('TAM EKRAN', height: 44, fontSize: 12, ls: 1.2),
              const Spacer(),
              const Tag('QR ALGILAMA: AÇIK', kind: TagKind.on, height: 36, fontSize: 12),
              gap(8),
              const Tag('ÇERÇEVE ÇİZİMİ: AÇIK', height: 36, fontSize: 12),
            ],
          ),
        ],
      ),
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: 'KAMERALAR',
          expand: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _thumb(0, 'İHA-1', '30 fps', C.green, true),
              _thumb(1, 'İHA-2', '30 fps', C.green, false),
              _thumb(2, 'İHA-3', 'AYRILDI', C.red, false),
            ],
          ),
        ),
        gap(8),
        Panel(
          title: 'AKIŞ DURUMU',
          expand: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _st('Çözünürlük', '1280×720'),
              _st('Kare hızı', '30 FPS', c: C.green),
              _st('Gecikme', '84 ms'),
              _st('Kayıp kare', '0.4%'),
              _st('Kaynak', 'uav1/camera', last: true),
            ],
          ),
        ),
        gap(8),
        Expanded(
          child: Panel(
            title: 'QR ÇÖZÜMLEME',
            child: Column(
              children: [
                _qr('QR-1', 'Sağ 15 m', true, false),
                _qr('QR-2', 'Yükseklik 40 m', true, false),
                _qr('QR-3', 'bekleniyor', false, true),
              ],
            ),
          ),
        ),
      ],
    );

    return PageFrame(
      title: 'SÜRÜ İHA // KAMERA',
      bar: EmVariant.standard,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(flex: 3, child: main), gap(8), Expanded(flex: 1, child: right)],
        ),
      ),
    );
  }
}
