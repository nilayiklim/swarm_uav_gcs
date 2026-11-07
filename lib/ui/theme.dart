
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
