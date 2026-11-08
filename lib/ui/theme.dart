import 'package:flutter/material.dart';

/// 0xRRGGBB + opaklık -> Color (kullanımdan kalkmış API kullanmaz).
Color rgba(int hex, [double o = 1.0]) =>
    Color.fromRGBO((hex >> 16) & 0xFF, (hex >> 8) & 0xFF, hex & 0xFF, o);

/// Takım tasarımı renk paleti.
class C {
  static const bg = Color(0xFF0E181B);
  static const side = Color(0xFF0A1214);
  static const panel = Color(0xFF15252A);
  static const panelLine = Color(0xFF2A4046);
  static const card = Color(0xFF1B2E33);
  static const cardLine = Color(0xFF2F474D);
  static const green = Color(0xFF3FD97F);
  static const red = Color(0xFFFF5A55);
  static const blue = Color(0xFF4DB2FF);
  static const amber = Color(0xFFF5B73D);
  static const disarm = Color(0xFFE5333F);
  static const text = Color(0xFFE8EEF0);
  static const mut = Color(0xFF8BA0A5);
  static const mut2 = Color(0xFF9FB1B6);
  static const label = Color(0xFF7F989E);
  static const dark = Color(0xFF0A1214);
}

const List<String> kMono = ['Menlo', 'Consolas', 'Courier New', 'monospace'];

TextStyle ts(
  double size, {
  Color color = C.text,
  FontWeight w = FontWeight.w400,
  double ls = 0,
  double? h,
  bool mono = false,
}) {
  return TextStyle(
    fontSize: size,
    color: color,
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
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.green,
      secondary: C.blue,
      surface: C.panel,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

// ───────────────────────── Açık / koyu tema ─────────────────────────
//
// Uygulama koyu tema ile çizilir. Açık tema, tüm ağaca uygulanan tek bir
// renk matrisidir (invert → hue-rotate 180° → parlaklık .94 → kontrast .9 → sepya .1).
// Böylece yeşil/kırmızı/mavi tonlar korunur, tek yerden yönetilir.
// Açık temada olduğu gibi kalması gereken yerler (HUD, harita, kamera) [KeepDark] ile sarılır.

/// true = açık tema.
final ValueNotifier<bool> lightMode = ValueNotifier<bool>(false);

class _Aff {
  const _Aff(this.m, this.o);
  final List<double> m; // 3x3 (satır sırasıyla)
  final List<double> o; // 3
}

_Aff _compose(_Aff f, _Aff g) {
  // f ∘ g  (önce g, sonra f)
  final m = List<double>.filled(9, 0);
  final o = List<double>.filled(3, 0);
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 3; c++) {
      var s = 0.0;
      for (var k = 0; k < 3; k++) {
        s += f.m[r * 3 + k] * g.m[k * 3 + c];
      }
      m[r * 3 + c] = s;
    }
    var s = f.o[r];
    for (var k = 0; k < 3; k++) {
      s += f.m[r * 3 + k] * g.o[k];
    }
    o[r] = s;
  }
  return _Aff(m, o);
}

_Aff _inverse(_Aff a) {
  final m = a.m;
  final det = m[0] * (m[4] * m[8] - m[5] * m[7]) - m[1] * (m[3] * m[8] - m[5] * m[6]) + m[2] * (m[3] * m[7] - m[4] * m[6]);
  final d = 1 / det;
  final inv = <double>[
    (m[4] * m[8] - m[5] * m[7]) * d,
    (m[2] * m[7] - m[1] * m[8]) * d,
    (m[1] * m[5] - m[2] * m[4]) * d,
    (m[5] * m[6] - m[3] * m[8]) * d,
    (m[0] * m[8] - m[2] * m[6]) * d,
    (m[2] * m[3] - m[0] * m[5]) * d,
    (m[3] * m[7] - m[4] * m[6]) * d,
    (m[1] * m[6] - m[0] * m[7]) * d,
    (m[0] * m[4] - m[1] * m[3]) * d,
  ];
  final o = <double>[
    -(inv[0] * a.o[0] + inv[1] * a.o[1] + inv[2] * a.o[2]),
    -(inv[3] * a.o[0] + inv[4] * a.o[1] + inv[5] * a.o[2]),
    -(inv[6] * a.o[0] + inv[7] * a.o[1] + inv[8] * a.o[2]),
  ];
  return _Aff(inv, o);
}

ColorFilter _toFilter(_Aff a) {
  final m = a.m;
  final o = a.o;
  return ColorFilter.matrix(<double>[
    m[0], m[1], m[2], 0, o[0] * 255,
    m[3], m[4], m[5], 0, o[1] * 255,
    m[6], m[7], m[8], 0, o[2] * 255,
    0, 0, 0, 1, 0,
  ]);
}

_Aff _buildLight() {
  const invert = _Aff([-1, 0, 0, 0, -1, 0, 0, 0, -1], [1, 1, 1]);
  const hue = _Aff([-0.574, 1.430, 0.144, 0.426, 0.430, 0.144, 0.426, 1.430, -0.856], [0, 0, 0]);
  const bright = _Aff([.94, 0, 0, 0, .94, 0, 0, 0, .94], [0, 0, 0]);
  const contrast = _Aff([.9, 0, 0, 0, .9, 0, 0, 0, .9], [.05, .05, .05]);
  const s = .9; // 1 - sepya miktarı (0.1)
  final sepia = _Aff([
    0.393 + 0.607 * s, 0.769 - 0.769 * s, 0.189 - 0.189 * s,
    0.349 - 0.349 * s, 0.686 + 0.314 * s, 0.168 - 0.168 * s,
    0.272 - 0.272 * s, 0.534 - 0.534 * s, 0.131 + 0.869 * s,
  ], const [0, 0, 0]);
  return _compose(sepia, _compose(contrast, _compose(bright, _compose(hue, invert))));
}

final _Aff _lightAff = _buildLight();
final ColorFilter kLightFilter = _toFilter(_lightAff);
final ColorFilter kLightInverse = _toFilter(_inverse(_lightAff));
const ColorFilter kIdentityFilter = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Açık temada renkleri koyu temadaki gibi bırakır (HUD, harita, kamera görüntüsü…).
class KeepDark extends StatelessWidget {
  const KeepDark({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: lightMode,
      child: child,
      builder: (context, light, c) => ColorFiltered(colorFilter: light ? kLightInverse : kIdentityFilter, child: c),
    );
  }
}

/// Uygulamanın tamamını seçili temaya göre boyar.
class ThemeScope extends StatelessWidget {
  const ThemeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: lightMode,
      child: child,
      builder: (context, light, c) => ColorFiltered(colorFilter: light ? kLightFilter : kIdentityFilter, child: c),
    );
  }
}
