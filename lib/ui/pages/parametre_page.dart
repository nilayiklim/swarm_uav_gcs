import 'package:flutter/material.dart';
import '../widgets.dart';

/// PARAMETRELER – içerik henüz belirlenmedi (başlık, İHA kutucukları ve Acil Şerit hazır).
class ParametrePage extends StatelessWidget {
  const ParametrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'SÜRÜ İHA // PARAMETRELER',
      bar: EmVariant.standard,
      body: SizedBox.expand(),
    );
  }
}
