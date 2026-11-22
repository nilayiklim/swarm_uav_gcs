import 'package:flutter/foundation.dart';

/// Uygulama genelinde paylaşılan durum (yarışma/test modu, takım ID, QR, bağlantı…).
/// Canlı veri bağlanınca bu değerler Zenoh/MAVLink'ten beslenecek.

/// true: YARIŞMA MODU – Acil Şerit, terminal, Komut Merkezi ve harita sağ-tık menüsü kilitli;
/// yalnızca "GÖREVİ BAŞLAT" kalır. false: TEST / SİMÜLASYON MODU.
final ValueNotifier<bool> raceMode = ValueNotifier<bool>(true);

/// GÖRSEL DEMO anahtarı. true iken Yarı Otonom sayfasındaki formasyon kutuları ve harita
/// (sol tık = "Buraya Uç", sağ tık = Mission Planner menüsü) YARIŞMA MODUNDA da çalışır.
/// Şartnameye uygun gerçek yarışma yapılandırması için false yap: o zaman bu üç öğe
/// YARIŞMA MODUNDA yeniden salt-okunur / kilitli olur (QR'dan gelen formasyon değişmez).
const bool kDemoKomut = true;

/// Görev başlatıldı mı (yarışma modunda tüm sürü aynı anda başlar).
final ValueNotifier<bool> missionStarted = ValueNotifier<bool>(false);

/// BİZİM takımın ID'si: yarışmada hakemlerce verilir ve boyunca değişmez (arayüzde seçici yok).
/// QR'daki "team" tablosundan yalnızca bu ID'ye karşılık gelen görev bloğu ve sonraki QR numarası kullanılır.
final ValueNotifier<int> teamId = ValueNotifier<int>(1);

/// YKİ bağlantısı koptu mu? (otonom görev devam eder, son veriler dondurulur).
final ValueNotifier<bool> linkLost = ValueNotifier<bool>(false);

/// YKİ'de QR en az bir kez okundu mu (okunmazsa −20 puan).
final ValueNotifier<bool> qrSeen = ValueNotifier<bool>(true);

// ── Parametreler ──
final ValueNotifier<double> takeoffAlt = ValueNotifier<double>(20);
final ValueNotifier<double> formDistance = ValueNotifier<double>(15);
final ValueNotifier<double> minAlt = ValueNotifier<double>(10);
final ValueNotifier<double> failsafeSec = ValueNotifier<double>(5);

/// QR içindeki tek bir görev bloğu: ["frm", tip, mesafe], ["mnv", pitch, roll], ["alt", irtifa].
class QrStep {
  const QrStep({required this.frm, required this.dist, required this.pitch, required this.roll, required this.alt});
  final String frm; // ok = Ok Başı, v = V, l = Çizgi
  final double dist; // ajanlar arası mesafe (m)
  final double pitch; // ° (mnv[0])
  final double roll; // ° (mnv[1])
  final double alt; // m

  String get frmName => frm == 'ok' ? 'Ok Başı' : (frm == 'v' ? 'V' : 'Çizgi');
}

/// Şartname Şekil 2 – QR içeriği:
/// {"qr":1,"w":4,"mis":[[frm,mnv,alt],…],"team":{"1":[blok, sonraki QR],…}}
/// Takım, "team" tablosundan kendi görev bloğunu (1. değer) ve sonraki QR numarasını (2. değer, 0 = son görev) alır.
class QrTask {
  const QrTask({
    required this.no,
    required this.wait,
    required this.mis,
    required this.team,
    this.leaveId,
    this.leaveColor,
  });

  final int no;
  final int wait; // w – görevler arası bekleme (sn)
  final List<QrStep> mis;
  final Map<int, List<int>> team;
  final int? leaveId; // sürüden ayrılacak ajan (varsa)
  final String? leaveColor; // KIRMIZI / MAVİ

  QrStep stepFor(int t) {
    final i = ((team[t]?[0] ?? 1) - 1).clamp(0, mis.length - 1).toInt();
    return mis[i];
  }

  int blockFor(int t) => team[t]?[0] ?? 1;
  int nextFor(int t) => team[t]?[1] ?? 0;

  String get json {
    String blk(QrStep s) =>
        '    [\n      ["frm", "${s.frm}", ${s.dist.toStringAsFixed(0)}],\n      ["mnv", ${s.pitch.toStringAsFixed(0)}, ${s.roll.toStringAsFixed(0)}],\n      ["alt", ${s.alt.toStringAsFixed(0)}]\n    ]';
    final tm = team.entries.map((e) => '    "${e.key}": [${e.value[0]}, ${e.value[1]}]').join(',\n');
    return '{\n  "qr": $no,\n  "w": $wait,\n  "mis": [\n${mis.map(blk).join(',\n')}\n  ],\n  "team": {\n$tm\n  }\n}';
  }
}

/// Çözülen QR'lar. Gerçek veride YKİ bir QR'ı çözdükçe buraya eklenir; takım ID yalnızca QR içindeki
/// "team" tablosundan kendi görev bloğunu ve "sonraki QR" numarasını seçer (sabit bir rota yoktur).
/// ÖRNEK VERİ: şartname Şekil 2'deki QR-1.
const List<QrTask> kQrTasks = [
  QrTask(
    no: 1,
    wait: 4,
    mis: [
      QrStep(frm: 'ok', dist: 6, pitch: -10, roll: 0, alt: 20),
      QrStep(frm: 'v', dist: 8, pitch: 0, roll: 10, alt: 25),
      QrStep(frm: 'l', dist: 5, pitch: 10, roll: -5, alt: 22),
    ],
    team: {1: [1, 4], 2: [2, 5], 3: [3, 3], 4: [1, 5], 5: [2, 2]},
  ),
];

QrTask? qrByNo(int no) {
  for (final q in kQrTasks) {
    if (q.no == no) return q;
  }
  return null;
}

/// Son çözülen QR'ın seçili takım bloğundaki "sonraki QR" numarası (okunmakta olan / hedef QR). 0 = son görev.
int nextQrFor(int team) => kQrTasks.last.nextFor(team);
