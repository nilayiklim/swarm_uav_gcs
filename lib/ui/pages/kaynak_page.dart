import 'package:flutter/material.dart';
import '../widgets.dart';

/// KAYNAK – içerik henüz belirlenmedi (başlık, İHA kutucukları ve Acil Şerit hazır).
class KaynakPage extends StatelessWidget {
  const KaynakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'SÜRÜ İHA // KAYNAK',
      bar: EmVariant.standard,
      body: SizedBox.expand(),
    );
  }
}
