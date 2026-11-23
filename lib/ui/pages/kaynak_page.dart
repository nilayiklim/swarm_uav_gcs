import 'package:flutter/material.dart';
import '../widgets.dart';

/// KAYNAK – içerik alanı bilerek boş bırakıldı (başlık, İHA şeridi ve alt şerit çerçevede kalır).
class KaynakPage extends StatelessWidget {
  const KaynakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'SÜRÜ İHA // KAYNAK',
      body: SizedBox.expand(),
    );
  }
}
