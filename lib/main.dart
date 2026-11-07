import 'package:flutter/material.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

void main() {
  runApp(const SwarmUavApp());
}

class SwarmUavApp extends StatelessWidget {
  const SwarmUavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sürü İHA // Görev Kontrol',
      theme: buildTheme(),
      home: const AppShell(),
    );
  }
}
