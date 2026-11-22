import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../painters.dart';
import '../swarm_map.dart';
import '../theme.dart';
import '../uav_data.dart';
import '../widgets.dart';

/// ANA SAYFA – büyük etkileşimli sürü haritası + seçili İHA için detaylı HUD.
/// (İHA telemetri kutucukları tüm sayfalarda en üstte, bkz. UavStrip.)
class KontrolPage extends StatefulWidget {
  const KontrolPage({super.key});

  @override
  State<KontrolPage> createState() => _KontrolPageState();
}

class _KontrolPageState extends State<KontrolPage> {
  int _sel = 0;
  static const int _snapPhase = 3; // 'Formasyon' – QR-1 çözüldü, çözülen QR'ın görevleri sırayla yürütülüyor
  int _phase = _snapPhase; // görev akışı aşaması
  int _step = 1; // 0 Ayrıldı · 1 İniş Yaptı · 2 Disarm · 3 Yeniden Katılıyor
  bool _running = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (missionStarted.value) {
        setState(() {
          if (!_running) {
            // görev yeni başladı: akış baştan (Kalkış) izlenir
            _running = true;
            _phase = 0;
            _step = 0;
          } else {
            _step = (_step + 1) % 4;
            _phase = (_phase + 1) % _phases.length;
          }
        });
      } else if (_running || _step != 1 || _phase != _snapPhase) {
        setState(() {
          _running = false;
          _step = 1;
          _phase = _snapPhase;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _ro(String label, String value, {Color? color}) => Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: isLight
            ? BoxDecoration(color: L.sf, borderRadius: BorderRadius.circular(6), border: Border.all(color: L.sfLine))
            : BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: C.cardLine),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B1417), Color(0xFF10201F)],
                ),
              ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ts(9.5, color: C.label, w: FontWeight.w600, ls: 1.2)),
              gap(2),
              Text(value, style: ts(16, color: color ?? C.text, w: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _tab(int i) {
    final on = i == _sel;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () => setState(() => _sel = i),
        child: Tag('İHA-${i + 1}', kind: on ? TagKind.on : TagKind.normal, height: 26, fontSize: 11),
      ),
    );
  }

  void _fullHud() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: lc(0xFF0E181B),
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 900,
          height: 760,
          child: Stack(children: [
            Positioned.fill(child: Padding(padding: const EdgeInsets.all(10), child: _hud(full: true))),
            Positioned(
              right: 16,
              top: 14,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                child: Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, color: C.text, size: 22)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _hud({bool full = false}) {
    final u = kUavs[_sel];
    return Panel(
      title: full ? 'HUD · ${u.name}' : 'HUD',
      trailing: full
          ? const SizedBox(width: 36)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < kUavs.length; i++) _tab(i),
              gap(8),
              Tooltip(
                message: 'HUD\'u büyüt (tam ekran)',
                child: InkWell(
                  onTap: _fullHud,
                  child: Padding(padding: EdgeInsets.all(3), child: Icon(Icons.fullscreen, size: 22, color: C.text)),
                ),
              ),
            ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 440 / 404,
            child: CustomPaint(painter: BigAttitudePainter(roll: u.roll, pitch: u.pitch, heading: u.heading)),
          ),
          gap(8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      Expanded(child: Center(child: AspectRatio(aspectRatio: 1, child: KeepDark(child: CustomPaint(painter: CompassPainter(u.heading)))))),
                      gap(3),
                      Text('HDG · ${u.heading.toStringAsFixed(0)}°', style: ts(9.5, color: C.label, w: FontWeight.w600, ls: .8)),
                    ],
                  ),
                ),
                gap(8),
                Expanded(
                  flex: 11,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('YER HIZI', '${u.speed.toStringAsFixed(1)} m/s')),
                          gap(6),
                          Expanded(child: _ro('DİKEY HIZ', '${u.vspeed >= 0 ? '+' : '−'}${u.vspeed.abs().toStringAsFixed(1)} m/s')),
                        ]),
                      ),
                      gap(6),
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('İRTİFA', '${u.alt.toStringAsFixed(1)} m')),
                          gap(6),
                          Expanded(child: _ro('BATARYA', '${u.pct}% · ${u.bat.toStringAsFixed(1)}V', color: u.pctColor)),
                        ]),
                      ),
                      gap(6),
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('ROLL', '${u.roll >= 0 ? '+' : '−'}${u.roll.abs().toStringAsFixed(1)}°')),
                          gap(6),
                          Expanded(child: _ro('PITCH', '${u.pitch >= 0 ? '+' : '−'}${u.pitch.abs().toStringAsFixed(1)}°')),
                        ]),
                      ),
                      gap(6),
                      Expanded(
                        child: Row(children: [
                          Expanded(child: _ro('GPS', '${u.gps} uydu')),
                          gap(6),
                          Expanded(child: _ro('HDOP', u.hdop.toStringAsFixed(1))),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _phases = [
    'Kalkış',
    'QR\'a Rotasyon',
    'QR Çöz',
    'Formasyon',
    'Manevra',
    'İrtifa',
    'Birey Ekle/Çıkar',
    'Sonraki QR',
    'QR=0 → Home',
    'Güvenli İniş',
    'Disarm',
  ];

  /// Şartname görev akışı: kalkış → rotasyon → QR çöz → görevler → sonraki QR → (0) home → iniş → disarm.
  Widget _flow() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: rgba(0x0A1417, .85),
        border: Border.all(color: C.panelLine),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(children: [
        Text('GÖREV AKIŞI', style: ts(10.5, color: C.label, w: FontWeight.w700, ls: 1.4)),
        gap(12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < _phases.length; i++) ...[
                if (i > 0) Text('  ›  ', style: ts(12, color: C.label)),
                Text(
                  _phases[i],
                  style: ts(12.5,
                      color: i == _phase ? C.green : (i < _phase ? C.mut : C.label),
                      w: i == _phase ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ]),
          ),
        ),
        gap(10),
        const Tag('AKTİF İHA 3 · MİN 3 ✓', kind: TagKind.on, fontSize: 10, height: 22),
      ]),
    );
  }

  // ───── Ana Sayfa alt kartları (QR görev kartı yalnızca Kamera sayfasında) ─────

  Widget _stepChip(int i, String t) {
    final done = _step > i;
    final on = _step == i;
    final col = on ? C.green : (done ? C.mut : C.label);
    return Expanded(
      child: Container(
        height: 30,
        alignment: Alignment.center,
        margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: on ? lc(0xFF17402F) : lc(0xFF18292E),
          border: Border.all(color: on ? C.green : lc(0xFF33505A)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${done ? '✓ ' : ''}$t', style: ts(11, color: col, w: FontWeight.w600, ls: .4)),
        ),
      ),
    );
  }

  Widget _zoneRow(String n, Color c, bool found) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        gap(8),
        Text(n, style: ts(12.5, w: FontWeight.w600)),
        const Spacer(),
        Text(found ? 'Tespit Edildi' : 'Bekleniyor', style: ts(12.5, color: found ? C.green : C.amber, w: FontWeight.w700)),
      ]);

  Widget _statusCard() => Panel(
        title: 'İNİŞ BÖLGESİ · BİREY DURUMU',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _zoneRow('KIRMIZI İNİŞ ALANI', C.red, false),
            gap(6),
            _zoneRow('MAVİ İNİŞ ALANI', C.blue, true),
            gap(4),
            Text('Ø 2 m daire · iniş toleransı: merkezden 2.5 m', style: ts(10.5, color: C.label)),
            gap(10),
            Row(children: [
              _stepChip(0, 'Ayrıldı'),
              _stepChip(1, 'İniş Yaptı'),
              _stepChip(2, 'Disarm'),
              _stepChip(3, 'Yeniden Katılıyor'),
            ]),
          ],
        ),
      );

  /// Küçük değer satırı (iki sütunlu aktif QR görevi tablosu için).
  Widget _kv2(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(children: [
          Expanded(child: Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11.5, color: C.mut))),
          gap(6),
          Text(v, maxLines: 1, style: ts(13, color: color, w: FontWeight.w700)),
        ]),
      );

  /// Aktif QR görevi: son çözülen QR'ın JSON'unun özet hali (resim ve ham JSON Kamera sayfasında, burada tekrarlanmaz).
  /// Takım ID yalnızca QR içindeki takım bloğunu seçer.
  Widget _formCard() => ListenableBuilder(
        listenable: teamId,
        builder: (context, _) {
          final t = teamId.value;
          final task = kQrTasks.last;
          final st = task.stepFor(t);
          final next = task.nextFor(t);
          final kind = st.frm == 'ok' ? 0 : (st.frm == 'v' ? 1 : 2);
          final leave = task.leaveId != null ? 'İHA-${task.leaveId} · ${task.leaveColor}' : 'Yok';
          return Panel(
            title: 'AKTİF QR GÖREVİ',
            trailing: Tag('QR-${task.no} · TAKIM $t', kind: TagKind.on, fontSize: 10, height: 22),
            child: Row(children: [
              SizedBox(
                width: 112,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 112, height: 45, child: CustomPaint(painter: FormationIconPainter(kind, color: C.green))),
                  gap(3),
                  Text(st.frmName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10, color: C.label, ls: .6)),
                ]),
              ),
              gap(12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Expanded(child: _kv2('Mesafe', '${st.dist.toStringAsFixed(0)} m')),
                      gap(14),
                      Expanded(child: _kv2('Pitch / roll', '${st.pitch.toStringAsFixed(0)}° / ${st.roll.toStringAsFixed(0)}°', color: C.blue)),
                    ]),
                    Row(children: [
                      Expanded(child: _kv2('İrtifa', '${st.alt.toStringAsFixed(0)} m')),
                      gap(14),
                      Expanded(child: _kv2('Bekleme (w)', '${task.wait} sn')),
                    ]),
                    Row(children: [
                      Expanded(child: _kv2('Birey ekle/çıkar', leave, color: task.leaveId != null ? C.blue : C.label)),
                      gap(14),
                      Expanded(child: _kv2('Sonraki QR', next == 0 ? 'SON' : '$next', color: C.amber)),
                    ]),
                    Row(children: [
                      Expanded(child: _kv2('Rotasyon → ${next == 0 ? 'HOME' : 'QR-$next'}', '${kUavs.first.heading.toStringAsFixed(0)}°')),
                      gap(14),
                      Expanded(child: _kv2('Takım bloğu', '#${task.blockFor(t)} / ${task.mis.length}')),
                    ]),
                  ],
                ),
              ),
            ]),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'SÜRÜ İHA // ANA SAYFA',
      simple: true,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 68,
              child: Column(
                children: [
                  Expanded(
                    child: Panel(
                      title: 'SÜRÜ KONUMU & HARİTA',
                      child: Plain(child: SwarmMap(selected: _sel, onSelect: (i) => setState(() => _sel = i))),
                    ),
                  ),
                  gap(8),
                  _flow(),
                  gap(8),
                  SizedBox(
                    height: 176,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 1, child: _statusCard()),
                        gap(8),
                        Expanded(flex: 1, child: _formCard()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gap(8),
            Expanded(flex: 32, child: Plain(child: _hud())),
          ],
        ),
      ),
    );
  }
}
