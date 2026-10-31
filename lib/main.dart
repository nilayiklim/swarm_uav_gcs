import 'package:flutter/material.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1215),
      ),
      home: const MissionControlScreen(),
    );
  }
}

class MissionControlScreen extends StatelessWidget {
  const MissionControlScreen({super.key});

  static const Color panelBgColor = Color(0xFF131D21);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color borderColor = Color(0xFF23383E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SOL İKON MENÜSÜ
          Container(
            width: 64,
            color: const Color(0xFF080D0F),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.radar, color: Colors.redAccent, size: 30),
                const SizedBox(height: 32),
                _buildMenuIcon(Icons.dashboard, 'KONTROL', true),
                _buildMenuIcon(Icons.analytics_outlined, 'TELEMETRİ', false),
                _buildMenuIcon(Icons.videocam_outlined, 'KAMERA', false),
                _buildMenuIcon(Icons.receipt_long_outlined, 'GÖREV', false),
              ],
            ),
          ),
          // ANA EKRAN İÇERİĞİ
          Expanded(
            child: Column(
              children: [
                _buildTopStatusBar(),
                _buildSubStatusBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // 1. SOL KISIM: İHA TELEMETRİ KARTLARI
                        Expanded(
                          flex: 3,
                          child: _buildPanelBox(
                            title: 'İHA TELEMETRİ',
                            content: ListView(
                              children: [
                                _buildUavCard('İHA-1', '37.7 m', '44.2 m/s', '39.9337 m  22.66344216', 0.85, true),
                                const SizedBox(height: 8),
                                _buildUavCard('İHA-2', '37.5 m', '45.2 m/s', '39.9337 m  32.86634216', 0.72, false),
                                const SizedBox(height: 8),
                                _buildUavCard('İHA-3', '37.3 m', '49.2 m/s', '39.9337 m  32.66334216', 0.45, false),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 2. ORTA KISIM: HARİTA VE İLK GÖRSELDEKİ ORANLARA SAHİP KAMERALAR
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 64,
                                child: _buildPanelBox(
                                  title: 'SÜRÜ KONUMU & HARİTA',
                                  content: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF070C0E),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.map, size: 180, color: neonGreen.withOpacity(0.04)),
                                        ),
                                      ),
                                      Center(
                                        child: CustomPaint(
                                          size: const Size(double.infinity, double.infinity),
                                          painter: MapRoutePainter(),
                                        ),
                                      ),
                                      Positioned(top: 90, left: 130, child: _mapNode('İHA-1', neonGreen)),
                                      Positioned(top: 170, left: 220, child: _mapNode('İHA-2', Colors.cyanAccent)),
                                      Positioned(top: 210, left: 320, child: _mapNode('İHA-3', Colors.amber)),
                                      Positioned(bottom: 60, left: 110, child: _waypointNode('WP-01')),
                                      Positioned(bottom: 110, right: 130, child: _waypointNode('WP-02')),
                                      Positioned(top: 90, right: 90, child: _waypointNode('WP-03')),
                                      // Neon Parıltılı Radar Çemberi
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: neonGreen, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: neonGreen.withOpacity(0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                            color: Colors.black54,
                                          ),
                                          child: const Center(
                                            child: Text('RADAR', style: TextStyle(fontSize: 10, color: neonGreen, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                flex: 36,
                                child: _buildPanelBox(
                                  title: 'KAMERA YAYINLARI',
                                  content: Row(
                                    children: [
                                      Expanded(child: _buildCameraBox('İHA-1 KAS (BURUN)', '37.7m')),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildCameraBox('İHA-2 KAS', '45.2m')),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildCameraBox('İHA-3 KAS', '37.5m')),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 3. SAĞ KISIM: HUD, LOG VE BUTONLAR
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 38,
                                child: _buildPanelBox(
                                  title: 'UÇUŞ GÖSTERGELERİ / HUD',
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildArtificialHorizonHud(),
                                      _buildCompassHud(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                flex: 44,
                                child: _buildPanelBox(
                                  title: 'LOG',
                                  content: ListView(
                                    children: const [
                                      Text('[14:12:01] Telemetri aktif', style: TextStyle(color: neonGreen, fontSize: 11, fontFamily: 'monospace')),
                                      SizedBox(height: 3),
                                      Text('[14:12:05] Formasyon korundu (V-Tipi)', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                      SizedBox(height: 3),
                                      Text('[14:12:05] Formasyon korundu', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                      SizedBox(height: 3),
                                      Text('[14:12:03] Telemetri aktif', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                      SizedBox(height: 3),
                                      Text('[14:12:20] Formasyon korundu', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                      SizedBox(height: 3),
                                      Text('[14:12:10] Waypoint WP-02 geçildi', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(child: _commandButton('Kalkış', Icons.flight_takeoff)),
                                          const SizedBox(width: 6),
                                          Expanded(child: _commandButton('Otonom', Icons.auto_mode)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(child: _commandButton('Formasyon', Icons.hub_outlined)),
                                          const SizedBox(width: 6),
                                          Expanded(child: _commandButton('İniş', Icons.flight_land)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF091013),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.airplanemode_active, color: Colors.redAccent, size: 18),
          const SizedBox(width: 6),
          const Text('SÜRÜ İHA // GÖREV KONTROL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          const Text('TEKNOFEST 2026 - TAKIM-07', style: TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(width: 16),
          _statusTag('SİSTEM AKTİF', neonGreen),
          const SizedBox(width: 8),
          _statusTag('YER İSTASYONU: BAĞLI', neonGreen),
          const SizedBox(width: 8),
          const Text('GPS 11', style: TextStyle(fontSize: 11, color: Colors.white70)),
          const Spacer(),
          const Text('SAAT 00:24:12', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          const Text('UTC 14:12:12', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: neonGreen,
              boxShadow: [BoxShadow(color: neonGreen.withOpacity(0.5), blurRadius: 4)],
            ),
            child: const Text('LİVE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          const Text('BATTERY 10%', style: TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(width: 10),
          const Text('SWARM UAV v2.4', style: TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildSubStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: panelBgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: neonGreen, size: 8),
          const SizedBox(width: 6),
          const Text('BAĞLANTI ETKİN', style: TextStyle(fontSize: 11, color: neonGreen)),
          const SizedBox(width: 16),
          const Icon(Icons.circle, color: neonGreen, size: 8),
          const SizedBox(width: 6),
          const Text('YER İSTASYONU ONLİNE', style: TextStyle(fontSize: 11, color: neonGreen)),
          const SizedBox(width: 16),
          const Icon(Icons.circle, color: neonGreen, size: 8),
          const SizedBox(width: 6),
          const Text('GPS FIX 3D', style: TextStyle(fontSize: 11, color: neonGreen)),
          const Spacer(),
          const Icon(Icons.circle, color: neonGreen, size: 8),
          const SizedBox(width: 6),
          const Text('CANLI/LİVE', style: TextStyle(fontSize: 11, color: neonGreen)),
        ],
      ),
    );
  }

  Widget _statusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(icon, color: active ? neonGreen : Colors.white38, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: active ? neonGreen : Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildPanelBox({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panelBgColor,
        border: Border.all(color: title == 'İHA TELEMETRİ' ? neonGreen.withOpacity(0.6) : borderColor, width: title == 'İHA TELEMETRİ' ? 1.2 : 1.0),
        boxShadow: title == 'İHA TELEMETRİ' ? [BoxShadow(color: neonGreen.withOpacity(0.1), blurRadius: 6)] : [],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              if (title == 'LOG')
                const Row(
                  children: [
                    Icon(Icons.circle, color: neonGreen, size: 6),
                    SizedBox(width: 4),
                    Text('CANLI/LİVE', style: TextStyle(fontSize: 10, color: neonGreen)),
                  ],
                ),
            ],
          ),
          const Divider(color: borderColor, height: 10),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildUavCard(String name, String alt, String spd, String pos, double battery, bool isLive) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF19272C),
        border: Border.all(color: isLive ? neonGreen : borderColor, width: isLive ? 1.5 : 1),
        boxShadow: isLive ? [BoxShadow(color: neonGreen.withOpacity(0.3), blurRadius: 6)] : [],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  Icon(Icons.circle, color: isLive ? neonGreen : Colors.amber, size: 8),
                  const SizedBox(width: 4),
                  Text(isLive ? 'LİVE' : 'BAĞLI', style: TextStyle(color: isLive ? neonGreen : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('ALT   $alt     BAT', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          Text('HIZ   $spd     10.1 m/s', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          Text('KONUM  $pos', style: const TextStyle(fontSize: 10, color: Colors.white54)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: battery,
            backgroundColor: Colors.black26,
            color: neonGreen,
            minHeight: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBox(String title, String alt) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF070C0E),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
          const Center(child: Icon(Icons.add, color: neonGreen, size: 26)),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text('ALT: $alt', style: const TextStyle(fontSize: 9, color: Colors.white54)),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text('BAĞLI', style: TextStyle(fontSize: 9, color: neonGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildArtificialHorizonHud() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: neonGreen, width: 2),
        boxShadow: [BoxShadow(color: neonGreen.withOpacity(0.4), blurRadius: 6)],
        color: const Color(0xFF1E3D59),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 74, height: 37, color: const Color(0xFFB46A31)),
          Positioned(
            top: 0,
            child: Container(width: 74, height: 37, color: const Color(0xFF2675B5)),
          ),
          const Icon(Icons.flight, color: neonGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildCompassHud() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: neonGreen, width: 2),
        boxShadow: [BoxShadow(color: neonGreen.withOpacity(0.4), blurRadius: 6)],
        color: const Color(0xFF070C0E),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('360° N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: neonGreen)),
            SizedBox(height: 2),
            Text('39.833768', style: TextStyle(fontSize: 7.5, color: Colors.white54)),
            Text('46.2 km/s', style: TextStyle(fontSize: 7.5, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _mapNode(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 5)],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _waypointNode(String wp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.25),
        border: Border.all(color: Colors.cyan, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 5)],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(wp, style: const TextStyle(color: Colors.cyan, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _commandButton(String label, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: panelBgColor,
        foregroundColor: Colors.white,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: EdgeInsets.zero,
      ),
      onPressed: () {},
      icon: Icon(icon, size: 14, color: neonGreen),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(150, 110);
    path.lineTo(240, 190);
    path.lineTo(340, 230);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}