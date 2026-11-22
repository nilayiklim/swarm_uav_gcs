import 'package:flutter/material.dart';
import '../widgets.dart';

/// PARAMETRELER – içerik alanı bilerek boş bırakıldı (başlık, İHA şeridi ve alt şerit çerçevede kalır).
class ParametrePage extends StatelessWidget {
  const ParametrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'SÜRÜ İHA // PARAMETRELER',
      body: SizedBox.expand(),
    );
  }
}
