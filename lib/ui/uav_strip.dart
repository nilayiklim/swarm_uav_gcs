import 'package:flutter/material.dart';
import 'app_state.dart';
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
    final light = isLight;
    final small = ts(11.5, color: lc(0xFFB9CBCF));
    final dot = Text('  ·  ', style: ts(11.5, color: C.mut));
    final content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(u.name, style: ts(15, w: FontWeight.w700)),
                gap(10),
                Text('${u.pct}%', style: ts(15, color: u.standby ? C.amber : u.pctColor, w: FontWeight.w700)),
                const Spacer(),
                if (u.tag != null)
                  Tag(u.tag!, kind: u.standby ? TagKind.amber : TagKind.red, fontSize: 9.5, ls: .4, height: 18)
                else if (linkLost.value)
                  Text('◼ SON VERİ', style: ts(10.5, color: C.amber, w: FontWeight.w600, ls: .6))
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
        );
    final Widget card;
    if (light) {
      // Açık tema: beyaz kart, ince çerçeve, solda 3 px durum şeridi.
      final Color accent = u.bad ? const Color(0xFFD02A29) : (u.standby ? const Color(0xFFC99A2E) : L.gr);
      final Color bg = u.bad ? const Color(0xFFFFF6F6) : (u.standby ? const Color(0xFFFFFBF1) : Colors.white);
      card = Container(
        height: height - 12,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: u.bad ? const Color(0xFFF2B8B8) : L.line),
          boxShadow: L.shadowSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accent),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: content)),
          ],
        ),
      );
    } else {
      card = Container(
        height: height - 12,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: u.bad ? const Color(0xFFF0443E) : const Color(0xFF33505A)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: u.bad
                ? const [Color(0xFF3A1E24), Color(0xFF25161A)]
                : const [Color(0xFF203A41), Color(0xFF18292E)],
          ),
        ),
        child: content,
      );
    }
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(i),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(valueListenable: linkLost, builder: (context, _, __) => _body());
  }

  Widget _body() {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isLight ? L.strip : const Color(0xFF0C171A),
        border: Border(bottom: BorderSide(color: isLight ? L.line : const Color(0xFF1F3338))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < kStripUavs.length; i++) ...[
            if (i > 0) gap(8),
            Expanded(child: _card(i, kStripUavs[i])),
          ],
        ],
      ),
    );
  }
}
