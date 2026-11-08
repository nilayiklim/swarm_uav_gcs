import 'package:flutter/material.dart';
import 'pages/kamera_page.dart';
import 'pages/kaynak_page.dart';
import 'pages/komut_page.dart';
import 'pages/kontrol_page.dart';
import 'pages/log_page.dart';
import 'pages/parametre_page.dart';
import 'pages/veriler_page.dart';
import 'pages/yari_otonom_page.dart';
import 'theme.dart';
import 'widgets.dart';

/// Yan çubuk + sayfa değiştirme. Sıra:
/// Ana Sayfa, Yarı Otonom, Veriler, Parametre, Kamera, Kaynak, Log Kayıtları, Komut Merkezi.
/// Her sayfanın üstündeki başlık + İHA kutucukları + Acil Şerit [PageFrame] içindedir.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      child: Scaffold(
        backgroundColor: C.bg,
        body: DefaultTextStyle(
          style: ts(14),
          child: Row(
            children: [
              SideBar(index: _index, onSelect: (i) => setState(() => _index = i)),
              Expanded(
                child: ScaleToFit(
                  child: IndexedStack(
                    index: _index,
                    children: const [
                      KontrolPage(),
                      YariOtonomPage(),
                      VerilerPage(),
                      ParametrePage(),
                      KameraPage(),
                      KaynakPage(),
                      LogPage(),
                      KomutPage(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
