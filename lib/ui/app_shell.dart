import 'package:flutter/material.dart';
import 'pages/kamera_page.dart';
import 'pages/kaynak_page.dart';
import 'pages/kontrol_page.dart';
import 'pages/parametre_page.dart';
import 'pages/tek_iha_page.dart';
import 'pages/telemetri_page.dart';
import 'pages/yari_otonom_page.dart';
import 'theme.dart';
import 'widgets.dart';

/// Yan çubuk + sayfa değiştirme.
/// KONTROL sayfasında bir İHA kartına dokunmak TEK İHA ekranını açar;
/// yan çubuktan KONTROL'e tekrar basmak ana ekrana döndürür.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _tek = false;

  void _select(int i) {
    setState(() {
      if (i == 0 && _index == 0) {
        _tek = false;
      } else {
        _index = i;
        if (i != 0) _tek = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: DefaultTextStyle(
        style: ts(14),
        child: Row(
          children: [
            SideBar(index: _index, onSelect: _select),
            Expanded(
              child: ScaleToFit(
                child: IndexedStack(
                  index: _index,
                  children: [
                    _tek ? const TekIhaPage() : KontrolPage(onOpenIha: () => setState(() => _tek = true)),
                    const YariOtonomPage(),
                    const TelemetriPage(),
                    const ParametrePage(),
                    const KameraPage(),
                    const KaynakPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
