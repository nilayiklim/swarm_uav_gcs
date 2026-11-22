import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ───────────────────────── Açık / koyu tema ─────────────────────────
//
// Uygulama koyu palete göre yazılmıştır. Açık temada her renk, tuvaldeki tasarımla aynı
// eşleme tablosundan geçer ([lc], [rgba], [C]); panel, buton, etiket, yan çubuk gibi bileşenler
// ayrıca açık temaya özel çizilir (düz beyaz kartlar, ince çerçeve, gölge, parlama yok).
// Tema değişince ağaç yeniden kurulur ve yeniden boyanır ([initThemeSwitching]).

/// true = açık tema.
final ValueNotifier<bool> lightMode = ValueNotifier<bool>(false);

int _darkDepth = 0;

/// Şu an açık tema çiziliyor mu? ([KeepDark] içinde her zaman false.)
bool get isLight => lightMode.value && _darkDepth == 0;

/// Koyu hex -> açık hex eşleme tablosu (elle seçilmiş değerler).
const Map<int, int> _kLightMap = {
  0x050B0D: 0xE6EDF0, 0x070D0F: 0xDCE5E8, 0x091012: 0xE3EAED, 0x0A1214: 0xE4ECEF,
  0x0A1417: 0xF0F5F7, 0x0B1417: 0xF3F7F8, 0x0B1518: 0xE9EFF1, 0x0C171A: 0xE9EFF1,
  0x0D181C: 0xF3F7F8, 0x0D191C: 0xEDF2F4, 0x0E181B: 0xEDF2F4, 0x0E1B1F: 0xF1F5F6,
  0x0E2A1D: 0xCFEBDC, 0x0F1C20: 0xF5F8F9, 0x0F1D22: 0xE7EEF1, 0x101C1F: 0xF5F8F9,
  0x10201F: 0xE8EFF1, 0x102A20: 0xCFEBDC, 0x10301F: 0xD2EEE0, 0x112024: 0xDDE9E8,
  0x122126: 0xE4ECEF, 0x12232A: 0xF9FBFC, 0x123325: 0xDDF3E8, 0x132227: 0xFFFFFF,
  0x13242A: 0xE9F0F2, 0x132529: 0xFCFDFE, 0x14262C: 0xEFF4F6, 0x14302A: 0xDDF3E8,
  0x14402C: 0xDDF3E8, 0x15252A: 0xFFFFFF, 0x16282D: 0xF2F6F7, 0x17402F: 0xDDF3E8,
  0x18292E: 0xEFF4F6, 0x182B31: 0xF0F5F6, 0x183137: 0xFFFFFF, 0x1A2D32: 0xEBF1F3,
  0x1A4A38: 0xD2EEE0, 0x1B2A2F: 0xD3DDE0, 0x1B2E33: 0xF2F6F7, 0x1B3238: 0xF7FAFB,
  0x1E3237: 0xDAE3E6, 0x1F3338: 0xCCD7DB, 0x1F6C9E: 0x2B7FBF, 0x203A41: 0xFFFFFF,
  0x223439: 0xCDD8DC, 0x223940: 0xFFFFFF, 0x243C42: 0xC6D3D7, 0x25161A: 0xF7DADC,
  0x264047: 0xF5F9FA, 0x26424A: 0xFFFFFF, 0x27393F: 0xCAD6DA, 0x2A1013: 0xF7DADC,
  0x2A200B: 0xF4E5BE, 0x2A4046: 0xBBCACF, 0x2A4047: 0xC3D0D4, 0x2A7F55: 0x2E9A62,
  0x2B4147: 0xBBCACF, 0x2E86C0: 0x2E86C0, 0x2E8F5A: 0x2E9A62, 0x2E9060: 0x2E9A62,
  0x2F474D: 0xB6C6CB, 0x33270C: 0xFCF1D8, 0x33505A: 0xAEBFC4, 0x3A1519: 0xFCE9EA,
  0x3A1E24: 0xFCE9EA, 0x3A2D10: 0xFCF1D8, 0x3A4F55: 0xB2C2C7, 0x3A5961: 0xA4B7BC,
  0x3B5258: 0xA6B8BD, 0x3FD97F: 0x0C8C48, 0x4BE88D: 0x0A7A3E, 0x4DB2FF: 0x0A6CB5,
  0x4E3219: 0x8A5A2B, 0x5B7B84: 0x6B858C, 0x5BE0A0: 0x0C8C48, 0x5F7A80: 0x6B858C,
  0x63B8E8: 0x8FD0F5, 0x7A252B: 0xE8AEB2, 0x7D959B: 0x566F76, 0x7F989E: 0x566F76,
  0x86A0A6: 0x4E6870, 0x8BA0A5: 0x526B72, 0x9A7220: 0xC99A2E, 0x9FB1B6: 0x46606A,
  0x9FB4BA: 0x46606A, 0xB07A3E: 0xC9954A, 0xB9CBCF: 0x2D434A, 0xC8D6D9: 0x22363C,
  0xCFE0E3: 0x1B2D33, 0xD5E0E2: 0x1B2D33, 0xDDE6E8: 0x12262B, 0xE8EEF0: 0x10202A,
  0xF5B73D: 0x9C6606, 0xFF5A55: 0xD02A29, 0xFF6B66: 0xC0282A, 0xFF7A75: 0xC0282A,
  0xFF8480: 0xC0282A,
};

/// Açık temada da değişmeyen renkler (saf beyaz/siyah, kırmızı düğme, canlı yeşil, QR kâğıdı…).
const Set<int> _kKeep = {
  0xFFFFFF, 0x000000, 0x06210F, 0x05202F, 0xF24A56, 0xC8283A, 0x9E1B2B, 0xFF6B73,
  0xE5333F, 0x3FE883, 0x22A857, 0x2BC66B, 0x1F7A52, 0xEFFFF6, 0x0A1A20, 0xF2F6F7,
};

final Map<int, int> _lightCache = <int, int>{};

int _toLightRgb(int rgb) {
  if (_kKeep.contains(rgb)) return rgb;
  final hit = _kLightMap[rgb];
  if (hit != null) return hit;
  return _lightCache.putIfAbsent(rgb, () => _autoLight(rgb));
}

/// Tabloda olmayan renkler için: açıklığı tersine çevir, doygun renkleri koyulaştır.
int _autoLight(int rgb) {
  final r = ((rgb >> 16) & 255) / 255, g = ((rgb >> 8) & 255) / 255, b = (rgb & 255) / 255;
  final hls = _rgbToHls(r, g, b);
  final h = hls[0], l = hls[1], s = hls[2];
  double l2;
  if (s > 0.35 && l > 0.45) {
    l2 = l * 0.6;
  } else if (l < 0.5) {
    l2 = 1 - 0.88 * l;
  } else {
    l2 = 0.98 - 0.93 * l;
  }
  l2 = l2.clamp(0.02, 0.99).toDouble();
  final o = _hlsToRgb(h, l2, math.min(s, 0.5));
  int c(double v) => (v * 255).round().clamp(0, 255).toInt();
  return (c(o[0]) << 16) | (c(o[1]) << 8) | c(o[2]);
}

List<double> _rgbToHls(double r, double g, double b) {
  final maxc = math.max(r, math.max(g, b));
  final minc = math.min(r, math.min(g, b));
  final l = (minc + maxc) / 2.0;
  if (minc == maxc) return [0.0, l, 0.0];
  final d = maxc - minc;
  final s = l <= 0.5 ? d / (maxc + minc) : d / (2.0 - maxc - minc);
  final rc = (maxc - r) / d, gc = (maxc - g) / d, bc = (maxc - b) / d;
  double h;
  if (r == maxc) {
    h = bc - gc;
  } else if (g == maxc) {
    h = 2.0 + rc - bc;
  } else {
    h = 4.0 + gc - rc;
  }
  return [(h / 6.0) % 1.0, l, s];
}

double _hv(double m1, double m2, double hue) {
  hue = hue % 1.0;
  if (hue < 1 / 6) return m1 + (m2 - m1) * hue * 6.0;
  if (hue < 0.5) return m2;
  if (hue < 2 / 3) return m1 + (m2 - m1) * (2 / 3 - hue) * 6.0;
  return m1;
}

List<double> _hlsToRgb(double h, double l, double s) {
  if (s == 0) return [l, l, l];
  final m2 = l <= 0.5 ? l * (1.0 + s) : l + s - (l * s);
  final m1 = 2.0 * l - m2;
  return [_hv(m1, m2, h + 1 / 3), _hv(m1, m2, h), _hv(m1, m2, h - 1 / 3)];
}

/// 0xAARRGGBB (koyu tema değeri) -> seçili temanın rengi.
Color lc(int argb) {
  if (!isLight) return Color(argb);
  return Color((argb & 0xFF000000) | _toLightRgb(argb & 0xFFFFFF));
}

/// 0xRRGGBB + opaklık -> Color. Açık temada eşlenir; siyah gölgeler yumuşak mürekkep gölgesine döner.
Color rgba(int hex, [double o = 1.0]) {
  if (isLight) {
    if (hex == 0x000000) return Color.fromRGBO(0x12, 0x30, 0x3A, o * 0.30);
    hex = _toLightRgb(hex);
  }
  return Color.fromRGBO((hex >> 16) & 0xFF, (hex >> 8) & 0xFF, hex & 0xFF, o);
}

/// Takım tasarımı renk paleti (seçili temaya göre).
class C {
  static Color get bg => lc(0xFF0E181B);
  static Color get side => lc(0xFF0A1214);
  static Color get panel => lc(0xFF15252A);
  static Color get panelLine => lc(0xFF2A4046);
  static Color get card => lc(0xFF1B2E33);
  static Color get cardLine => lc(0xFF2F474D);
  static Color get green => lc(0xFF3FD97F);
  static Color get red => lc(0xFFFF5A55);
  static Color get blue => lc(0xFF4DB2FF);
  static Color get amber => lc(0xFFF5B73D);
  static Color get disarm => lc(0xFFE5333F);
  static Color get text => lc(0xFFE8EEF0);
  static Color get mut => lc(0xFF8BA0A5);
  static Color get mut2 => lc(0xFF9FB1B6);
  static Color get label => lc(0xFF7F989E);
  static Color get dark => lc(0xFF0A1214);
}

/// Koyu paletin değişmeyen hâli (yan çubuk, terminal, kamera görüntüsü gibi her zaman koyu alanlar).
class D {
  static const bg = Color(0xFF0E181B);
  static const panel = Color(0xFF15252A);
  static const panelLine = Color(0xFF2A4046);
  static const card = Color(0xFF1B2E33);
  static const cardLine = Color(0xFF2F474D);
  static const green = Color(0xFF3FD97F);
  static const red = Color(0xFFFF5A55);
  static const blue = Color(0xFF4DB2FF);
  static const amber = Color(0xFFF5B73D);
  static const text = Color(0xFFE8EEF0);
  static const mut = Color(0xFF8BA0A5);
  static const label = Color(0xFF7F989E);
  static const mut2 = Color(0xFF9FB1B6);
  static const term = Color(0xFF050B0D);
  static const termLine = Color(0xFF1E3237);
}

/// Açık temaya özel tasarım değerleri (düz yüzeyler, ince çerçeve, koyu lacivert yan çubuk).
class L {
  static const navy = Color(0xFF12303A);
  static const ink = Color(0xFF12303A);
  static const ink2 = Color(0xFF33505B);
  static const mu = Color(0xFF5A727C);
  static const line = Color(0xFFD6E0E5);
  static const line2 = Color(0xFFE3EAEE);
  static const sf = Color(0xFFF5F8FA);
  static const sfLine = Color(0xFFDCE5EA);
  static const page = Color(0xFFEDF1F4);
  static const strip = Color(0xFFF7F9FB);
  static const gr = Color(0xFF0B8A47);
  static const grDark = Color(0xFF0A7A3E);
  static const grText = Color(0xFF0B7A3F);
  static const grBg = Color(0xFFE3F4EA);
  static const grLine = Color(0xFFA6D8BC);
  static const redText = Color(0xFFB3232B);
  static const redBg = Color(0xFFFDECEC);
  static const redLine = Color(0xFFF0B3B3);
  static const amText = Color(0xFF8A5A00);
  static const amBg = Color(0xFFFFF3D6);
  static const amLine = Color(0xFFE2BD6C);
  static const btnLine = Color(0xFFBFCDD4);
  static const danger = Color(0xFFD92D3A);
  static const dangerLine = Color(0xFFB8232F);

  /// Panel/kart gölgesi (açık tema).
  static List<BoxShadow> get shadow => const [
        BoxShadow(color: Color(0x0D12303A), blurRadius: 2, offset: Offset(0, 1)),
        BoxShadow(color: Color(0x0D12303A), blurRadius: 16, offset: Offset(0, 6)),
      ];
  static List<BoxShadow> get shadowSm => const [
        BoxShadow(color: Color(0x0F12303A), blurRadius: 2, offset: Offset(0, 1)),
      ];
}

const List<String> kMono = ['Menlo', 'Consolas', 'Courier New', 'monospace'];

TextStyle ts(
  double size, {
  Color? color,
  FontWeight w = FontWeight.w400,
  double ls = 0,
  double? h,
  bool mono = false,
}) {
  return TextStyle(
    fontSize: size,
    color: color ?? C.text,
    fontWeight: w,
    letterSpacing: ls,
    height: h,
    decoration: TextDecoration.none,
    fontFamily: mono ? kMono.first : null,
    fontFamilyFallback: mono ? kMono.sublist(1) : null,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildTheme() {
  final light = lightMode.value;
  return ThemeData(
    useMaterial3: true,
    brightness: light ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: light
        ? ColorScheme.light(primary: C.green, secondary: C.blue, surface: C.panel)
        : ColorScheme.dark(primary: C.green, secondary: C.blue, surface: C.panel),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

/// Tema değişince bütün ağacı yeniden kurar ve yeniden boyar (durum korunur).
/// `main()` içinde bir kez çağrılır.
void initThemeSwitching() {
  lightMode.addListener(() {
    void visit(Element e) {
      e.markNeedsBuild();
      if (e is RenderObjectElement) e.renderObject.markNeedsPaint();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  });
}

/// Alt ağacı açık temada bile koyu temanın renkleriyle boyar. Yalnızca [CustomPaint] gibi
/// boyama anında renk seçen içerikler için (kamera görüntüsü, pusula…). Widget'lar derleme
/// anında renk seçtiği için içlerinde [D] paleti kullanılmalıdır.
class KeepDark extends SingleChildRenderObjectWidget {
  const KeepDark({super.key, required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderKeepDark();
}

class _RenderKeepDark extends RenderProxyBox {
  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    _darkDepth++;
    try {
      super.paint(context, offset);
    } finally {
      _darkDepth--;
    }
  }
}

/// Hiçbir şey yapmayan sarmalayıcı (bir alt ağacın artık [KeepDark] olmadığı yerlerde).
class Plain extends StatelessWidget {
  const Plain({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
