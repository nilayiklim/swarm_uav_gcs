import 'package:flutter/material.dart';
import 'theme.dart';
import 'uav_data.dart';
import 'widgets.dart';

/// Tüm sayfaların başlığı altında duran, her İHA için ayrı küçük telemetri kutusu.
class UavStrip extends StatelessWidget {
  const UavStrip({super.key, this.onTap});

  /// Kutuya dokununca (isteğe bağlı).
  final ValueChanged<int>? onTap;

  static const double height = 58;

  Widget _card(int i, UavInfo u) {
    final small = ts(11.5, color: const Color(0xFFB9CBCF));
    final dot = Text('  ·  ', style: ts(11.5, color: C.mut));
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(i),
      child: Container(
        height: height - 12,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: u.bad ? const Color(0xFFF0443E) : const Color(0xFF33505A)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: u.bad ? const [Color(0xFF3A1E24), Color(0xFF25161A)] : const [Color(0xFF203A41), Color(0xFF18292E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(u.name, style: ts(15, w: FontWeight.w700)),
                gap(10),
                Text('${u.pct}%', style: ts(15, color: u.pctColor, w: FontWeight.w700)),
                const Spacer(),
                if (u.tag != null)
                  Tag(u.tag!, kind: TagKind.red, fontSize: 9.5, ls: .4, height: 18)
                else
                  Text('● LIVE', style: ts(10.5, color: C.green, w: FontWeight.w600, ls: .6)),
              ],
            ),
            gap(2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Alt ${u.alt.toStringAsFixed(1)} m', style: small),
                  dot,
                  Text('Bat ${u.bat.toStringAsFixed(1)} V', style: small),
                  dot,
                  Text('Hız ${u.speed.toStringAsFixed(1)} m/s', style: small),
                  dot,
                  Text('GPS ${u.gps}', style: small),
                  dot,
                  Text('HDOP ${u.hdop.toStringAsFixed(1)}', style: small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0C171A),
        border: Border(bottom: BorderSide(color: Color(0xFF1F3338))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < kUavs.length; i++) ...[
            if (i > 0) gap(8),
            Expanded(child: _card(i, kUavs[i])),
          ],
        ],
      ),
    );
  }
}
