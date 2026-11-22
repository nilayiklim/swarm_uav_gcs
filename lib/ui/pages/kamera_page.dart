import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../painters.dart';
import '../qr_card.dart';
import '../theme.dart';
import '../widgets.dart';

/// KAMERA – İHA seçimi, kayıt, anlık görüntü, tam ekran ve QR çözümleme ayrıntısı (hepsi tıklanabilir).
class KameraPage extends StatefulWidget {
  const KameraPage({super.key});

  @override
  State<KameraPage> createState() => _KameraPageState();
}

class _Qr {
  const _Qr(this.name, this.state, this.by, this.conf, this.dur, this.tries, this.pos, this.time, this.content);
  final String name;
  final int state; // 0 çözüldü, 1 okunuyor, 2 başarısız, 3 bekliyor
  final String by, conf, dur, tries, pos, time, content; // pos: QR konumu (enlem, boylam) – hakemler paylaşır
}

const _qrPos = {
  1: '40.12310, 32.56740',
  2: '40.12340, 32.56780',
  3: '40.12360, 32.56850',
  4: '40.12330, 32.56900',
  5: '40.12290, 32.56880',
};

/// QR durumları okunan QR'lardan türetilir (sabit rota yok):
///  · çözülenler = kQrTasks (örnek veri: QR-1)
///  · okunmakta olan = son çözülen QR'ın seçili takım bloğundaki "sonraki QR"
///  · diğerleri beklemede. Takım ID yalnızca QR içindeki takım bloğunu seçer.
_Qr _qrFor(int no, int team) {
  final pos = _qrPos[no]!;
  if (qrByNo(no) != null) return _Qr('QR-$no', 0, 'İHA-1', '%97', '1.8 s', '1 / 3', pos, '14:11:50', '');
  if (no == nextQrFor(team)) return _Qr('QR-$no', 1, 'İHA-1', '%64', '2.4 s', '1 / 3', pos, '—', 'Çözülüyor…');
  return _Qr('QR-$no', 3, '—', '—', '—', '0 / 3', pos, '—', 'Bekleniyor');
}

class _KameraPageState extends State<KameraPage> {
  int _cam = 0;
  bool _rec = true;
  int _recSec = 221;
  bool _full = false;
  int _qr = 0;
  String _flash = '';
  Timer? _timer;

  void _onTeam() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    teamId.addListener(_onTeam);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_rec) _recSec++;
        if (_flash.isNotEmpty && _recSec % 3 == 0) _flash = '';
      });
    });
  }

  @override
  void dispose() {
    teamId.removeListener(_onTeam);
    _timer?.cancel();
    super.dispose();
  }

  String get _recTxt {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(_recSec ~/ 3600)}:${p(_recSec % 3600 ~/ 60)}:${p(_recSec % 60)}';
  }

  Widget _ov(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(6, 12, 14, .82),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: rgba(0xFFFFFF, .07)),
        ),
        child: child,
      );

  Widget _thumb(int i, String name, String info, Color ic) {
    final on = i == _cam;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cam = i),
        child: Container(
          height: 62,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: on ? C.green : C.cardLine, width: on ? 2 : 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                KeepDark(child: CustomPaint(painter: ThumbPainter(i))),
                Positioned(left: 5, top: 5, child: _ov(Text(name, style: ts(11, color: D.text, w: FontWeight.w600)))),
                Positioned(right: 5, bottom: 5, child: _ov(Text(info, style: ts(10.5, color: ic, w: FontWeight.w600)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _st(String k, String v, {Color? c, bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: lc(0xFF1E3237)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k, style: ts(13.5, color: C.mut)), Text(v, style: ts(13.5, color: c, w: FontWeight.w700))],
        ),
      );

  Color _qc(int s) => s == 0 ? C.green : (s == 1 ? C.amber : (s == 2 ? C.red : C.mut));
  String _qi(int s) => s == 0 ? '✓' : (s == 1 ? '…' : (s == 2 ? '✕' : '–'));
  String _qt(int s) => s == 0 ? 'ÇÖZÜLDÜ' : (s == 1 ? 'OKUNUYOR' : (s == 2 ? 'BAŞARISIZ' : 'BEKLİYOR'));

  Widget _qrTile(int i) {
    final q = _qrFor(i + 1, teamId.value);
    final on = i == _qr;
    final c = _qc(q.state);
    final active = q.state != 3;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _qr = i),
        child: Container(
          height: 58,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active ? c.withAlpha(34) : lc(0xFF18292E),
            border: Border.all(color: on ? C.blue : (active ? c : lc(0xFF33505A)), width: on ? 2 : 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_qi(q.state), style: ts(18, color: c, w: FontWeight.w800)),
              gap(2),
              Text(q.name, style: ts(12, color: active ? c : C.mut, w: FontWeight.w700, ls: .6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, [Color? c]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: ts(13, color: C.mut)),
          Text(v, style: ts(13.5, color: c, w: FontWeight.w700)),
        ]),
      );

  /// Şartname kuralı notu (renkli çerçeveli kutu).
  Widget _rule(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: c.withAlpha(26), borderRadius: BorderRadius.circular(2), border: Border.all(color: c.withAlpha(150))),
        child: Text(t, style: ts(12, color: c, h: 1.4)),
      );

  /// Renkli iniş alanı kaydı (kamera tespiti): renk, durum, İHA + konum.
  Widget _zone(Color c, String name, String info, bool found) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: lc(0xFF101C1F),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: found ? c : lc(0xFF2A4046)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: found ? c : Colors.transparent, border: Border.all(color: c, width: 2)),
          ),
          gap(8),
          Text(name, style: ts(11.5, color: c, w: FontWeight.w700, ls: .8)),
          gap(8),
          Text(info, style: ts(12, color: found ? C.text : C.mut)),
        ]),
      );

  Widget _detail() {
    final q = _qrFor(_qr + 1, teamId.value);
    final c = _qc(q.state);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rgba(0x3FD97F, q.state == 0 ? .05 : 0),
        gradient: q.state == 0 ? null : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lc(0xFF14262B), lc(0xFF0F1D21)]),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: c.withAlpha(140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text(q.name, style: ts(18, w: FontWeight.w700)),
            gap(10),
            Tag(_qt(q.state), kind: q.state == 0 ? TagKind.on : (q.state == 2 ? TagKind.red : (q.state == 1 ? TagKind.amber : TagKind.normal)), height: 24, fontSize: 11),
            const Spacer(),
            Text(q.time, style: ts(11.5, color: C.mut)),
          ]),
          gap(10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: lc(0xFFF2F6F7), borderRadius: BorderRadius.circular(3), border: Border.all(color: c, width: 2)),
              child: KeepDark(child: CustomPaint(painter: _QrBigPainter(q.state == 3 ? 0 : q.name.hashCode, dim: q.state == 3))),
            ),
            gap(14),
            Expanded(
              child: Column(children: [
                _kv('Okuyan', q.by),
                _kv('Güven', q.conf, q.state == 0 ? C.green : C.text),
                _kv('Süre', q.dur),
                _kv('Deneme', q.tries),
                _kv('Konum', q.pos),
              ]),
            ),
          ]),
          if (q.state == 1) ...[
            gap(8),
            _rule(
                'Okuma sürüyor. Çözülemezse sürü halinde alçalma / yükselme / ileri-geri hareketleriyle yeniden denenir (alt sınır ${minAlt.value.toStringAsFixed(0)} m). '
                'Hiç çözülemezse sonraki QR konumu bilinmez → sürü HOME\'a döner ve görev baştan başlar; önceki QR\'lara kadar puan alınır.',
                C.amber),
          ],
          if (q.state == 2) ...[
            gap(8),
            _rule('QR çözülemedi → sonraki QR konumu bilinmiyor: sürü HOME\'a döner ve görevi başlangıç noktasından yeniden başlatır. Önceki QR\'lara kadar puan alınır.', C.red),
          ],
          gap(12),
          Row(children: [
            Text('ÇÖZÜMLENEN İÇERİK', style: ts(10, color: C.label, w: FontWeight.w600, ls: 1.4)),
            const Spacer(),
            ValueListenableBuilder<bool>(
              valueListenable: qrSeen,
              builder: (context, seen, _) => seen
                  ? const Tag('● YKİ\'DE OKUNDU', kind: TagKind.on, fontSize: 10, height: 22)
                  : const Tag('QR OKUNMADI · −20 PUAN', kind: TagKind.red, fontSize: 10, height: 22),
            ),
          ]),
          gap(5),
          if (q.state == 0 && qrByNo(_qr + 1) != null)
            QrParsedCard(task: qrByNo(_qr + 1)!)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: C.dark, border: Border.all(color: lc(0xFF33505A)), borderRadius: BorderRadius.circular(2)),
              child: Text(q.content, style: ts(14, mono: true, color: C.mut, w: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final camNames = ['İHA-1', 'İHA-2', 'İHA-3'];
    final main = Panel(
      title: '${camNames[_cam]} · ÖN KAMERA',
      padding: const EdgeInsets.all(10),
      trailing: Row(children: [
        Tag(_cam == 2 ? '● KOPUK' : '● CANLI', kind: _cam == 2 ? TagKind.red : TagKind.on),
        gap(6),
        const Tag('1280×720'),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  KeepDark(child: CustomPaint(painter: QrCameraPainter())),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _ov(Text.rich(TextSpan(children: [
                      TextSpan(text: _rec ? '● REC ' : '■ DURDU ', style: ts(13, color: _rec ? D.red : D.mut, w: FontWeight.w600)),
                      TextSpan(text: _recTxt, style: ts(13, color: D.text, w: FontWeight.w600)),
                    ]))),
                  ),
                  Positioned(right: 10, top: 10, child: _ov(Text(_cam == 2 ? 'SİNYAL YOK' : '30 FPS · 84 ms · 4.2 Mbps', style: ts(13, color: D.text, w: FontWeight.w600)))),
                  Align(
                    alignment: const Alignment(0, .78),
                    child: _ov(Text(nextQrFor(teamId.value) == 0 ? 'QR-1 okundu · güven %97' : 'QR-${nextQrFor(teamId.value)} okunuyor · güven %64', style: ts(13, color: nextQrFor(teamId.value) == 0 ? D.green : D.amber, w: FontWeight.w600))),
                  ),
                  Positioned(left: 10, bottom: 10, child: _ov(Text('İrt 37.8 m · Hız 9.2 m/s · Yön 112° DOĞU', style: ts(13, color: D.text, w: FontWeight.w600)))),
                  Positioned(right: 10, bottom: 10, child: _ov(Text(_qrPos[nextQrFor(teamId.value)] ?? _qrPos[1]!, style: ts(13, color: D.text, w: FontWeight.w600)))),
                  if (_flash.isNotEmpty) Positioned.fill(child: Container(color: rgba(0xFFFFFF, .25), alignment: Alignment.center, child: _ov(Text(_flash, style: ts(14, color: D.green, w: FontWeight.w700))))),
                ],
              ),
            ),
          ),
          gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('İNİŞ ALANLARI', style: ts(10, color: C.label, w: FontWeight.w600, ls: 1.4)),
              _zone(C.red, 'KIRMIZI', 'bekleniyor · tespit yok', false),
              _zone(C.blue, 'MAVİ', 'İHA-1 · 40.12341, 32.56790 · ✓ kaydedildi', true),
              Text('Ø 2 m daire · iniş toleransı 2.5 m', style: ts(11, color: C.label)),
            ],
          ),
          gap(8),
          Row(
            children: [
              MetalButton(_rec ? '■ KAYIT DURDUR' : '● KAYIT BAŞLAT', kind: _rec ? BtnKind.dangerOutline : BtnKind.green, height: 44, fontSize: 12, ls: 1.2, onTap: () => setState(() {
                    _rec = !_rec;
                    if (_rec) _recSec = 0;
                  })),
              gap(8),
              MetalButton('ANLIK GÖRÜNTÜ', height: 44, fontSize: 12, ls: 1.2, onTap: () => setState(() => _flash = 'Anlık görüntü kaydedildi · $_recTxt')),
              gap(8),
              MetalButton(_full ? 'KÜÇÜLT' : 'TAM EKRAN', height: 44, fontSize: 12, ls: 1.2, onTap: () => setState(() => _full = !_full)),
              const Spacer(),
              const Tag('QR ALGILAMA: AÇIK', kind: TagKind.on, height: 36, fontSize: 12),
              gap(8),
              const Tag('ÇERÇEVE ÇİZİMİ: AÇIK', height: 36, fontSize: 12),
            ],
          ),
        ],
      ),
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: 'KAMERALAR',
          expand: false,
          child: Row(children: [
            _thumb(0, 'İHA-1', '30 fps', D.green),
            _thumb(1, 'İHA-2', '30 fps', D.green),
            _thumb(2, 'İHA-3', 'AYRILDI', D.red),
          ]),
        ),
        gap(8),
        Panel(
          title: 'AKIŞ DURUMU',
          expand: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _st('Çözünürlük', '1280×720'),
              _st('Kare hızı', _cam == 2 ? '—' : '30 FPS', c: C.green),
              _st('Gecikme', _cam == 2 ? '240 ms' : '84 ms'),
              _st('Kayıp kare', _cam == 2 ? '3.8%' : '0.4%'),
              _st('Kaynak', 'uav${_cam + 1}/camera'),
              _st('FOV', '≤ 90° (şartname)'),
              _st('QR boyutu', '150 × 150 cm'),
              _st('Kameralı İHA', '2 / 3 · min. 1', c: C.green, last: true),
            ],
          ),
        ),
        gap(8),
        Expanded(
          child: Panel(
            title: 'QR ÇÖZÜMLEME',
            trailing: Text('kutuya tıkla → ayrıntı', style: ts(10.5, color: C.mut)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [for (int i = 0; i < 5; i++) _qrTile(i)]),
                  _detail(),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return PageFrame(
      title: 'SÜRÜ İHA // KAMERA',
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _full ? [Expanded(child: main)] : [Expanded(flex: 3, child: main), gap(8), Expanded(flex: 1, child: right)],
        ),
      ),
    );
  }
}

/// Gerçekçi görünümlü QR (25×25 modül, üç köşe konumlandırıcı).
class _QrBigPainter extends CustomPainter {
  _QrBigPainter(this.seed, {this.dim = false});
  final int seed;
  final bool dim;

  @override
  void paint(Canvas c, Size s) {
    const n = 25;
    final u = s.width / n;
    final ink = Paint()..color = dim ? lc(0xFFB8C4C7) : lc(0xFF0A1214);
    bool finder(int x, int y) => (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
    // Küçük sayılarla çalışan üreteç (web'de taşma olmasın diye).
    var r = seed.abs() % 9973 + 17;
    int next() {
      r = (r * 75 + 74) % 65537;
      return r;
    }

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (finder(x, y)) continue;
        if (dim ? (x + y) % 4 == 0 : (next() >> 3) % 100 < 50) c.drawRect(Rect.fromLTWH(x * u, y * u, u + .3, u + .3), ink);
      }
    }
    void eye(int ox, int oy) {
      c.drawRect(Rect.fromLTWH(ox * u, oy * u, 7 * u, 7 * u), ink);
      c.drawRect(Rect.fromLTWH((ox + 1) * u, (oy + 1) * u, 5 * u, 5 * u), Paint()..color = lc(0xFFF2F6F7));
      c.drawRect(Rect.fromLTWH((ox + 2) * u, (oy + 2) * u, 3 * u, 3 * u), ink);
    }

    eye(0, 0);
    eye(n - 7, 0);
    eye(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant _QrBigPainter o) => o.seed != seed || o.dim != dim;
}
