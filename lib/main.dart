import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Haritada sağ tık menüsümüz var: tarayıcının kendi menüsünü kapat.
  if (kIsWeb) BrowserContextMenu.disableContextMenu();
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
