import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'painters.dart';
import 'theme.dart';
import 'uav_data.dart';
import 'widgets.dart';

/// Etkileşimli sürü haritası:
///  • tekerlek / pinch ile yakınlaştırma, sürükleyerek kaydırma
///  • İHA'ya tıklayınca seçme (onSelect)
///  • + / − / ⟲ düğmeleri
class SwarmMap extends StatefulWidget {
  const SwarmMap({super.key, required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  State<SwarmMap> createState() => _SwarmMapState();
}

class _SwarmMapState extends State<SwarmMap> {
  static const double _vw = 900, _vh = 520;
  static const double _maxScale = 6;

  final _tc = TransformationController();
  Size _size = Size.zero;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _zoom(double f) {
    final cur = _tc.value.getMaxScaleOnAxis();
    final next = (cur * f).clamp(1.0, _maxScale);
    final k = next / cur;
    final c = Offset(_size.width / 2, _size.height / 2);
    _tc.value = Matrix4.translationValues(c.dx, c.dy, 0) *
        Matrix4.diagonal3Values(k, k, 1) *
        Matrix4.translationValues(-c.dx, -c.dy, 0) *
        _tc.value;
  }

  void _reset() => _tc.value = Matrix4.identity();

  /// Dokunulan noktayı (child koordinatı) en yakın İHA'ya eşler.
  void _tap(Offset local) {
    final k = math.max(_size.width / _vw, _size.height / _vh);
    final ox = (_size.width - _vw * k) / 2;
    final oy = (_size.height - _vh * k) / 2;
    final d = Offset((local.dx - ox) / k, (local.dy - oy) / k);
    int best = -1;
    double bestDist = 36; // tasarım birimi cinsinden dokunma yarıçapı
    for (int i = 0; i < MapPainter.uavPos.length; i++) {
      final dist = (MapPainter.uavPos[i] - d).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best >= 0) widget.onSelect(best);
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: rgba(0x0A1417, .85),
            border: Border.all(color: const Color(0xFF3B5258)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(icon, size: 18, color: C.text),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LayoutBuilder(builder: (context, box) {
        _size = Size(box.maxWidth, box.maxHeight);
        final u = kUavs[widget.selected];
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _tc,
                minScale: 1,
                maxScale: _maxScale,
                child: SizedBox(
                  width: box.maxWidth,
                  height: box.maxHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _tap(d.localPosition),
                    child: CustomPaint(painter: MapPainter(selected: widget.selected)),
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 12,
              top: 12,
              child: Tag('Formasyon Hatası: 0.2m | Min Mesafe: 14.8m', fontSize: 13, ls: 0, height: 26),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: rgba(0x0A1417, .85),
                  border: Border.all(color: const Color(0xFF3B5258)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'SEÇİLİ: ${u.name}   Alt ${u.alt.toStringAsFixed(1)} m   ${u.speed.toStringAsFixed(1)} m/s   HDG ${u.heading.toStringAsFixed(0)}°',
                  style: ts(12, color: C.blue, w: FontWeight.w600, ls: .4),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _btn(Icons.add, () => _zoom(1.5)),
                  gap(6),
                  _btn(Icons.remove, () => _zoom(1 / 1.5)),
                  gap(6),
                  _btn(Icons.center_focus_strong_outlined, _reset),
                ],
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                'Tekerlek: yakınlaştır · Sürükle: kaydır · İHA\'ya tıkla: seç',
                style: ts(10.5, color: C.label, ls: .4),
              ),
            ),
          ],
        );
      }),
    );
  }
}
