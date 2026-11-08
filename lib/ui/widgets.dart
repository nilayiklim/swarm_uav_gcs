import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'uav_strip.dart';

// ───────────────────────── Panel ─────────────────────────

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.expand = true,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (title != null) PanelTitle(title!, trailing: trailing),
        if (expand) Expanded(child: child) else child,
      ],
    );
    return CustomPaint(
      foregroundPainter: _BracketPainter(),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: C.panelLine),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF183137), Color(0xFF132529), Color(0xFF12232A)],
            stops: [0, .06, 1],
          ),
          boxShadow: [
            BoxShadow(color: rgba(0x000000, .35), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: body,
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = C.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const l = 10.0;
    c.drawPath(Path()..moveTo(0, l)..lineTo(0, 0)..lineTo(l, 0), p);
    c.drawPath(
        Path()
          ..moveTo(s.width - l, s.height)
          ..lineTo(s.width, s.height)
          ..lineTo(s.width, s.height - l),
        p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PanelTitle extends StatelessWidget {
  const PanelTitle(this.text, {super.key, this.trailing, this.topGap = 0});
  final String text;
  final Widget? trailing;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                  color: C.green,
                  boxShadow: [BoxShadow(color: rgba(0x3FD97F, .6), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(11.5, color: const Color(0xFFB4C8CD), w: FontWeight.w600, ls: 2),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rgba(0x3FD97F, .7), C.panelLine, rgba(0x2A4046, .2)],
                stops: const [0, .22, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Tag / Dot ─────────────────────────

enum TagKind { normal, on, amber, red }

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.kind = TagKind.normal, this.height = 24, this.fontSize = 11.5, this.ls = .8, this.centered = false});
  final String text;
  final TagKind kind;
  final double height;
  final double fontSize;
  final double ls;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    Color border;
    List<Color> grad;
    Color fg;
    switch (kind) {
      case TagKind.on:
        border = const Color(0xFF2E9060);
        grad = const [Color(0xFF17402F), Color(0xFF102A20)];
        fg = C.green;
        break;
      case TagKind.amber:
        border = const Color(0xFF9A7220);
        grad = const [Color(0xFF3A2D10), Color(0xFF2A200B)];
        fg = C.amber;
        break;
      case TagKind.red:
        border = const Color(0xFFF0443E);
        grad = const [Color(0xFF3A1517), Color(0xFF2A1013)];
        fg = const Color(0xFFFF6B66);
        break;
      case TagKind.normal:
        border = const Color(0xFF33505A);
        grad = const [Color(0xFF223940), Color(0xFF18292E)];
        fg = const Color(0xFFDDE6E8);
        break;
    }
    return Container(
      height: height,
      alignment: centered ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: grad),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(text, maxLines: 1, style: ts(fontSize, color: fg, ls: ls))],
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({super.key, this.color = C.green, this.size = 10, this.glow = true});
  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: glow ? [BoxShadow(color: color, blurRadius: 6)] : null,
        ),
      );
}

// ───────────────────────── Metal buton ─────────────────────────

enum BtnKind { normal, danger, dangerOutline, green, gray, redTint, accent, amber }

class MetalButton extends StatelessWidget {
  const MetalButton(
    this.label, {
    super.key,
    this.kind = BtnKind.normal,
    this.height = 48,
    this.fontSize = 12.5,
    this.ls = 1.6,
    this.hPad = 18,
    this.minWidth = 0,
    this.onTap,
  });

  final String label;
  final BtnKind kind;
  final double height;
  final double fontSize;
  final double ls;
  final double hPad;
  final double minWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    List<Color> grad;
    Color border;
    Color fg = C.text;
    List<BoxShadow> shadow = [BoxShadow(color: rgba(0x000000, .4), blurRadius: 8, offset: const Offset(0, 3))];
    switch (kind) {
      case BtnKind.danger:
        grad = const [Color(0xFFF24A56), Color(0xFFC8283A), Color(0xFF9E1B2B)];
        border = const Color(0xFFFF6B73);
        fg = Colors.white;
        shadow = [BoxShadow(color: rgba(0xE5333F, .4), blurRadius: 18), ...shadow];
        break;
      case BtnKind.dangerOutline:
        grad = const [Color(0xFF3A1519), Color(0xFF2A0F12), Color(0xFF2A0F12)];
        border = C.disarm;
        fg = const Color(0xFFFF7A75);
        break;
      case BtnKind.green:
        grad = const [Color(0xFF17513A), Color(0xFF0F3A29), Color(0xFF0F3A29)];
        border = const Color(0xFF2E9060);
        fg = const Color(0xFF5BF0A0);
        break;
      case BtnKind.gray:
        grad = const [Color(0xFF1F3036), Color(0xFF1B2A2E), Color(0xFF1B2A2E)];
        border = const Color(0xFF2B4147);
        fg = const Color(0xFF6F8388);
        break;
      case BtnKind.redTint:
        grad = const [Color(0xFF4A1C21), Color(0xFF3A1519), Color(0xFF2E1115)];
        border = const Color(0xFF7A252B);
        fg = const Color(0xFFFF8480);
        break;
      case BtnKind.amber:
        grad = const [Color(0xFF3A2D10), Color(0xFF2E230C), Color(0xFF2A200B)];
        border = const Color(0xFF8A6A22);
        fg = C.amber;
        break;
      case BtnKind.accent:
        grad = const [Color(0xFF17402F), Color(0xFF102A20), Color(0xFF102A20)];
        border = C.green;
        fg = C.green;
        break;
      case BtnKind.normal:
        grad = const [Color(0xFF26424A), Color(0xFF182B31), Color(0xFF122126)];
        border = const Color(0xFF3A5961);
        break;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: height,
          constraints: BoxConstraints(minWidth: minWidth),
          padding: EdgeInsets.symmetric(horizontal: hPad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: border),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: grad,
              stops: grad.length == 3 ? const [0, .55, 1] : null,
            ),
            boxShadow: shadow,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ts(fontSize, color: fg, w: FontWeight.w600, ls: ls),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Slider (tasarım) ─────────────────────────

class FakeSlider extends StatelessWidget {
  const FakeSlider(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: LayoutBuilder(builder: (context, box) {
        final x = box.maxWidth * value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 7,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rgba(0x14242A), rgba(0x2A4047)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 7,
              width: x,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(colors: [Color(0xFF2E86C0), C.blue]),
                ),
              ),
            ),
            Positioned(
              left: x - 9,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: rgba(0x0A1214)),
                  gradient: RadialGradient(
                    center: const Alignment(-.3, -.4),
                    radius: .9,
                    colors: [Colors.white, rgba(0xC5D3D7), rgba(0x7C9097)],
                    stops: const [0, .45, 1],
                  ),
                  boxShadow: [BoxShadow(color: rgba(0x000000, .6), blurRadius: 6, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ───────────────────────── Kart / giriş kutusu ─────────────────────────

class GCard extends StatelessWidget {
  const GCard({super.key, required this.child, this.padding = const EdgeInsets.all(10), this.bad = false, this.tint});
  final Widget child;
  final EdgeInsets padding;
  final bool bad;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: bad ? const Color(0xFFF0443E) : const Color(0xFF33505A)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bad
              ? const [Color(0xFF3A1E24), Color(0xFF25161A)]
              : tint != null
                  ? [Color.alphaBlend(tint!, const Color(0xFF203A41)), const Color(0xFF18292E)]
                  : const [Color(0xFF203A41), Color(0xFF18292E)],
        ),
        boxShadow: [
          BoxShadow(
            color: bad ? rgba(0xF0443E, .18) : rgba(0x000000, .25),
            blurRadius: bad ? 18 : 12,
            offset: bad ? Offset.zero : const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FieldBox extends StatelessWidget {
  const FieldBox(this.value, {super.key, this.unit, this.height = 40, this.mono = false, this.fontSize = 15});
  final String value;
  final String? unit;
  final double height;
  final bool mono;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: C.cardLine),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1417), Color(0xFF10201F)],
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(fontSize, mono: mono, ls: .6))),
          if (unit != null) Text(unit!, style: ts(12, color: C.mut2)),
        ],
      ),
    );
  }
}

// ───────────────────────── Üst şerit ─────────────────────────

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.main = false});
  final String title;

  /// true: Ana Sayfa başlığı (HAZIR · ZENOH · SAAT); false: diğer sayfaların tam başlığı.
  final bool main;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF132227), Color(0xFF0D181C)],
        ),
        border: const Border(bottom: BorderSide(color: Color(0xFF243C42))),
        boxShadow: [BoxShadow(color: rgba(0x3FD97F, .22), offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          const Icon(Icons.flight, color: C.disarm, size: 22),
          const SizedBox(width: 8),
          Text(title, style: ts(14.5, w: FontWeight.w600, ls: 1.3)),
          const SizedBox(width: 10),
          if (main)
            const Tag('HAZIR', kind: TagKind.on, height: 26, fontSize: 10, ls: .8)
          else ...[
            const Tag('SİSTEM AKTİF', kind: TagKind.on, height: 26, fontSize: 10, ls: .8),
            const SizedBox(width: 7),
            const Tag('YER İSTASYONU: BAĞLI', kind: TagKind.on, height: 26, fontSize: 10, ls: .8),
            const SizedBox(width: 8),
            Text('GPS 11', style: ts(13, color: C.mut)),
          ],
          const Spacer(),
          if (main) ...[
            Text('ZENOH: 12ms', style: ts(17, color: C.mut)),
            const SizedBox(width: 12),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'SAAT: ', style: ts(17)),
              TextSpan(text: '00:14:22', style: ts(17, w: FontWeight.w700)),
            ])),
          ] else ...[
            Text.rich(TextSpan(children: [
              TextSpan(text: 'SAAT ', style: ts(15)),
              TextSpan(text: '00:24:12', style: ts(15, w: FontWeight.w700)),
            ])),
            const SizedBox(width: 12),
            Text('UTC 14:12:13', style: ts(14, color: C.mut)),
            const SizedBox(width: 10),
            const LiveBadge(),
            const SizedBox(width: 10),
            Text('BATTERY 10%', style: ts(14)),
          ],
          const SizedBox(width: 12),
          const ThemeToggle(),
        ],
      ),
    );
  }
}

/// Koyu / açık tema anahtarı: iki ikonlu bölünmüş düğme (ay · güneş).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  Widget _b(bool on, IconData icon, String tip, VoidCallback f) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: f,
          child: Container(
            width: 30,
            height: 28,
            decoration: BoxDecoration(color: on ? const Color(0xFF1F6B47) : Colors.transparent),
            child: Icon(icon, size: 16, color: on ? Colors.white : C.mut),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: lightMode,
      builder: (context, light, _) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF33505A)),
          color: const Color(0xFF18292E),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _b(!light, Icons.dark_mode_outlined, 'Koyu tema', () => lightMode.value = false),
            _b(light, Icons.light_mode_outlined, 'Açık tema', () => lightMode.value = true),
          ]),
        ),
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3FE883), Color(0xFF22A857)],
          ),
          boxShadow: [BoxShadow(color: rgba(0x3FD97F, .4), blurRadius: 12)],
        ),
        child: Text('LIVE', style: ts(12, color: const Color(0xFF06210F), w: FontWeight.w800, ls: 1.4)),
      );
}

class StatusRow extends StatelessWidget {
  const StatusRow({super.key});

  Widget _item(String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Dot(size: 5),
          const SizedBox(width: 9),
          Text(t, style: ts(10.5, color: C.label, ls: 1.6)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1B1F), Color(0xFF0B1518)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF1E3237))),
      ),
      child: Row(
        children: [
          _item('BAĞLANTI ETKİN'),
          const SizedBox(width: 22),
          _item('YER İSTASYONU ONLİNE'),
          const SizedBox(width: 22),
          _item('GPS FIX 3D'),
          const Spacer(),
          _item('CANLI/LIVE'),
        ],
      ),
    );
  }
}

// ───────────────────────── Yan çubuk ─────────────────────────

class SideBar extends StatelessWidget {
  const SideBar({super.key, required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  static const labels = [
    'ANA\nSAYFA',
    'YARI\nOTONOM',
    'VERİLER',
    'PARAMETRE',
    'KAMERA',
    'KAYNAK',
    'LOG\nKAYITLARI',
    'KOMUT\nMERKEZİ',
  ];
  static const icons = <IconData>[
    Icons.dashboard,
    Icons.sports_esports_outlined,
    Icons.bar_chart,
    Icons.tune,
    Icons.videocam,
    Icons.receipt_long_outlined,
    Icons.list_alt,
    Icons.terminal,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D181C), Color(0xFF070D0F)],
        ),
        border: const Border(right: BorderSide(color: Color(0xFF1F3338))),
        boxShadow: [BoxShadow(color: rgba(0x3FD97F, .06), offset: const Offset(1, 0))],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 14),
            SizedBox(width: 38, height: 38, child: CustomPaint(painter: _LogoPainter())),
            const SizedBox(height: 10),
            for (int i = 0; i < labels.length; i++) _item(i),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(int i) {
    final on = i == index;
    final col = on ? const Color(0xFF4BE88D) : const Color(0xFF7D959B);
    return InkWell(
      onTap: () => onSelect(i),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: on
            ? BoxDecoration(
                gradient: LinearGradient(colors: [rgba(0x3FD97F, .18), rgba(0x3FD97F, 0)], stops: const [0, .9]),
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (on)
              Positioned(
                left: -2,
                top: -4,
                bottom: -4,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: C.green,
                    boxShadow: [BoxShadow(color: C.green, blurRadius: 10)],
                  ),
                ),
              ),
            SizedBox(
              width: 74,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[i], color: col, size: 24),
                  const SizedBox(height: 5),
                  Text(labels[i], textAlign: TextAlign.center, style: ts(9.5, color: col, w: FontWeight.w600, ls: .5, h: 1.15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = C.disarm
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final o = Offset(s.width / 2, s.height / 2);
    c.drawCircle(o, s.width * .39, p);
    c.drawCircle(o, s.width * .21, p);
    c.drawCircle(o, s.width * .07, Paint()..color = C.disarm);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────── Acil şerit ─────────────────────────

enum EmVariant { standard, redTint, yari, telemetri }

class EmergencyBar extends StatelessWidget {
  const EmergencyBar({super.key, this.variant = EmVariant.standard});
  final EmVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case EmVariant.yari:
        return Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: C.bg,
          child: Row(
            children: const [
              Expanded(flex: 10, child: MetalButton('RTL (HOME)', kind: BtnKind.green, fontSize: 14, ls: 1.2)),
              SizedBox(width: 8),
              Expanded(flex: 10, child: MetalButton('İNİŞ', kind: BtnKind.green, fontSize: 14, ls: 1.2)),
              SizedBox(width: 8),
              Expanded(flex: 14, child: MetalButton('DURDUR', kind: BtnKind.gray, fontSize: 14, ls: 1.2)),
              SizedBox(width: 8),
              Expanded(flex: 14, child: MetalButton('DISARM', kind: BtnKind.dangerOutline, fontSize: 14, ls: 1.2)),
            ],
          ),
        );
      case EmVariant.redTint:
        return _bar(
          bg: const [Color(0xFF2E1013), Color(0xFF240D10)],
          top: const Color(0xFF6B1D22),
          accent: C.disarm,
          labelColor: const Color(0xFFFF7A75),
          buttons: const [
            MetalButton('RTL (HOME)', kind: BtnKind.redTint, minWidth: 210),
            MetalButton('LAND (İNİŞ)', kind: BtnKind.redTint, minWidth: 210),
            MetalButton('STOP (DURDUR)', kind: BtnKind.redTint, minWidth: 210),
            MetalButton('DISARM', kind: BtnKind.danger, minWidth: 210),
          ],
        );
      case EmVariant.telemetri:
        return _bar(
          bg: const [Color(0xFF0F1C20), Color(0xFF0A1316)],
          top: C.panelLine,
          buttons: const [
            MetalButton('RTL (HOME)', minWidth: 190),
            MetalButton('LAND (İNİŞ)', minWidth: 190),
            MetalButton('STOP (DURDUR)', minWidth: 190),
            MetalButton('DISARM', kind: BtnKind.dangerOutline, minWidth: 190),
          ],
        );
      case EmVariant.standard:
        return _bar(
          bg: const [Color(0xFF0F1C20), Color(0xFF0A1316)],
          top: C.panelLine,
          buttons: const [
            MetalButton('RTL (BASILI TUT)', minWidth: 190),
            MetalButton('İNİŞ (BASILI TUT)', minWidth: 190),
            MetalButton('DURDUR', minWidth: 190),
            MetalButton('DISARM', kind: BtnKind.danger, minWidth: 190),
          ],
        );
    }
  }

  Widget _bar({
    required List<Color> bg,
    required Color top,
    Color? accent,
    Color labelColor = const Color(0xFF9DB4BA),
    required List<Widget> buttons,
  }) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bg),
        border: Border(top: BorderSide(color: accent ?? top, width: accent != null ? 2 : 1)),
        boxShadow: [BoxShadow(color: rgba(0x000000, .35), blurRadius: 22, offset: const Offset(0, -8))],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('ACİL ŞERİT', style: ts(11.5, color: labelColor, w: FontWeight.w600, ls: 2.4)),
          ),
          const Spacer(),
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            buttons[i],
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Sayfa iskeleti ─────────────────────────

class GridBg extends StatelessWidget {
  const GridBg({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter(), child: child);
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = rgba(0x3FD97F, .035)
      ..strokeWidth = 1;
    for (double x = 0; x < s.width; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (double y = 0; y < s.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.body,
    this.bar = EmVariant.standard,
    this.battery = '10%',
    this.simple = false,
    this.statusRow = false,
    this.extra,
  });
  final String title;
  final Widget body;
  final EmVariant bar;
  final String battery;

  /// true: Ana Sayfa başlığı.
  final bool simple;

  /// Başlık altında "BAĞLANTI ETKİN · YER İSTASYONU ONLİNE…" şeridi (Yarı Otonom).
  final bool statusRow;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(title: title, main: simple),
        const UavStrip(),
        if (statusRow) const StatusRow(),
        Expanded(child: GridBg(child: body)),
        const EmergencyBar(),
      ],
    );
  }
}

class ScaleToFit extends StatelessWidget {
  const ScaleToFit({super.key, required this.child, this.minWidth = 1202, this.minHeight = 880});
  final Widget child;
  final double minWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = math.max(box.maxWidth, minWidth);
      final h = math.max(box.maxHeight, minHeight);
      if (w == box.maxWidth && h == box.maxHeight) return child;
      return FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topLeft,
        child: SizedBox(width: w, height: h, child: child),
      );
    });
  }
}

/// Basit yardımcılar
Widget gap(double w, [double? h]) => SizedBox(width: w, height: h ?? w);

class LogLine extends StatelessWidget {
  const LogLine(this.text, {super.key, this.color = C.text, this.size = 13.5});
  final String text;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(size, color: color)),
      );
}
