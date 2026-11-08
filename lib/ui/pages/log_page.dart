import 'package:flutter/material.dart';
import '../theme.dart';
import '../uav_data.dart';
import '../widgets.dart';

/// LOG KAYITLARI – her İHA için ayrı sütun; İHA / seviye / kategori filtresi, arama, canlı akış, CSV.
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

enum _Lv { info, ok, warn, err }

class _Ev {
  const _Ev(this.t, this.cat, this.lv, this.msg, [this.n = 0]);
  final String t, cat, msg;
  final _Lv lv;
  final int n; // x5 gibi tekrar sayısı
}

const _logs = <List<_Ev>>[
  [
    _Ev('14:12:30', 'TELEMETRİ', _Lv.info, 'Telemetri aktif · 4.8 Hz · gecikme 84 ms'),
    _Ev('14:12:26', 'QR', _Lv.warn, 'QR-2 okunuyor · güven %64'),
    _Ev('14:12:22', 'FORMASYON', _Lv.ok, 'Formasyon korundu (V-Tipi) · hata 0.2 m', 5),
    _Ev('14:12:20', 'QR', _Lv.ok, 'QR-1 çözüldü · FORM=V · güven %97'),
    _Ev('14:12:18', 'QR', _Lv.info, 'QR-1 okunuyor'),
    _Ev('14:12:10', 'WAYPOINT', _Lv.ok, 'WP-02 geçildi'),
    _Ev('14:12:05', 'FORMASYON', _Lv.ok, 'Formasyon korundu (V-Tipi)', 5),
    _Ev('14:12:02', 'FORMASYON', _Lv.warn, 'Formasyon sapması (V-Tipi) · 1.4 m'),
    _Ev('14:11:58', 'KOMUT', _Lv.info, 'Hız komutu alındı · 10.1 m/s'),
    _Ev('14:11:52', 'GPS', _Lv.ok, 'GPS fix 3D · 12 uydu · HDOP 1.0'),
    _Ev('14:11:48', 'BATARYA', _Lv.info, 'Batarya %88 · 15.8 V'),
    _Ev('14:11:44', 'WAYPOINT', _Lv.ok, 'WP-01 geçildi'),
    _Ev('14:11:40', 'BAĞLANTI', _Lv.info, 'Zenoh bağlantısı kuruldu · 12 ms'),
    _Ev('14:11:36', 'SİSTEM', _Lv.info, 'ARM edildi · GUIDED modu'),
    _Ev('14:11:30', 'SİSTEM', _Lv.info, 'Ön uçuş kontrolleri tamam'),
  ],
  [
    _Ev('14:12:30', 'TELEMETRİ', _Lv.info, 'Telemetri aktif · 4.8 Hz · gecikme 91 ms'),
    _Ev('14:12:24', 'BATARYA', _Lv.info, 'Batarya %76 · 15.1 V'),
    _Ev('14:12:22', 'FORMASYON', _Lv.ok, 'Formasyon korundu (V-Tipi) · hata 0.3 m', 5),
    _Ev('14:12:15', 'GPS', _Lv.ok, 'Uydu sayısı 11 · HDOP 1.1'),
    _Ev('14:12:10', 'WAYPOINT', _Lv.ok, 'WP-02 geçildi'),
    _Ev('14:12:05', 'FORMASYON', _Lv.ok, 'Formasyon korundu (V-Tipi)', 5),
    _Ev('14:12:02', 'FORMASYON', _Lv.warn, 'Formasyon sapması (V-Tipi) · 1.1 m'),
    _Ev('14:11:58', 'KOMUT', _Lv.info, 'Hız komutu alındı · 10.1 m/s'),
    _Ev('14:11:52', 'GPS', _Lv.ok, 'GPS fix 3D · 11 uydu · HDOP 1.1'),
    _Ev('14:11:47', 'TELEMETRİ', _Lv.info, 'Paket kaybı %0.4 · kabul edilebilir'),
    _Ev('14:11:44', 'WAYPOINT', _Lv.ok, 'WP-01 geçildi'),
    _Ev('14:11:40', 'BAĞLANTI', _Lv.info, 'Zenoh bağlantısı kuruldu · 14 ms'),
    _Ev('14:11:36', 'SİSTEM', _Lv.info, 'ARM edildi · GUIDED modu'),
    _Ev('14:11:32', 'SİSTEM', _Lv.info, 'Pusula kalibrasyonu doğrulandı'),
    _Ev('14:11:30', 'SİSTEM', _Lv.info, 'Ön uçuş kontrolleri tamam'),
  ],
  [
    _Ev('14:12:30', 'DURUM', _Lv.warn, 'Mavi alanda bekleniyor · kalan 12 s'),
    _Ev('14:12:24', 'BATARYA', _Lv.warn, 'Batarya %64 · 14.6 V · düşük seviyeye yaklaşıyor'),
    _Ev('14:12:18', 'FORMASYON', _Lv.warn, 'Sürüden ayrıldı · mavi alana yönleniyor'),
    _Ev('14:12:16', 'KOMUT', _Lv.info, 'Ayrılma komutu alındı'),
    _Ev('14:12:12', 'FORMASYON', _Lv.warn, 'Formasyon sapması (V-Tipi) · 2.1 m'),
    _Ev('14:12:10', 'WAYPOINT', _Lv.ok, 'WP-02 geçildi'),
    _Ev('14:12:05', 'QR', _Lv.err, 'QR-3 okunamadı · 3 deneme'),
    _Ev('14:12:01', 'TELEMETRİ', _Lv.warn, 'Telemetri gecikmesi 240 ms'),
    _Ev('14:11:58', 'KOMUT', _Lv.info, 'Hız komutu alındı · 10.1 m/s'),
    _Ev('14:11:52', 'GPS', _Lv.ok, 'GPS fix 3D · 11 uydu · HDOP 1.1'),
    _Ev('14:11:47', 'TELEMETRİ', _Lv.info, 'Paket kaybı %0.4'),
    _Ev('14:11:44', 'WAYPOINT', _Lv.ok, 'WP-01 geçildi'),
    _Ev('14:11:40', 'BAĞLANTI', _Lv.info, 'Zenoh bağlantısı kuruldu · 16 ms'),
    _Ev('14:11:36', 'SİSTEM', _Lv.info, 'ARM edildi · GUIDED modu'),
    _Ev('14:11:30', 'SİSTEM', _Lv.info, 'Ön uçuş kontrolleri tamam'),
  ],
];

const _cats = ['Tümü', 'TELEMETRİ', 'QR', 'FORMASYON', 'WAYPOINT', 'KOMUT', 'GPS', 'BATARYA', 'BAĞLANTI', 'SİSTEM', 'DURUM'];

class _LogPageState extends State<LogPage> {
  int _uav = -1; // -1 tümü
  _Lv? _lv;
  String _cat = 'Tümü';
  String _q = '';
  bool _live = true;
  String _toast = '';

  Color _dot(_Lv l) => switch (l) { _Lv.info => C.blue, _Lv.ok => C.green, _Lv.warn => C.amber, _Lv.err => C.red };
  Color _txt(_Lv l) => switch (l) { _Lv.warn => C.amber, _Lv.err => C.red, _ => C.text };

  int _count(_Lv l) => _logs.expand((e) => e).where((e) => e.lv == l).length;

  bool _show(_Ev e) =>
      (_lv == null || e.lv == _lv) &&
      (_cat == 'Tümü' || e.cat == _cat) &&
      (_q.isEmpty || e.msg.toLowerCase().contains(_q.toLowerCase()) || e.cat.toLowerCase().contains(_q.toLowerCase()));

  Widget _chip(String t, bool on, VoidCallback f, {TagKind? kind, Color? color}) => GestureDetector(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ColoredTag(t, on: on, color: color, kind: kind ?? TagKind.normal),
        ),
      );

  Widget _col(int u) {
    final all = _logs[u];
    final list = all.where(_show).toList();
    final info = kUavs[u];
    final warn = all.where((e) => e.lv == _Lv.warn).length;
    final err = all.where((e) => e.lv == _Lv.err).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: info.bad ? const Color(0xFFF0443E) : C.panelLine),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF183137), Color(0xFF12232A)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(info.name, style: ts(17, w: FontWeight.w700, ls: 1)),
            gap(8),
            Text('${info.pct}%', style: ts(16, color: info.pctColor, w: FontWeight.w700)),
            gap(8),
            if (info.bad) const Tag('AYRILDI', height: 22, fontSize: 10.5) else Text('● LIVE', style: ts(10.5, color: C.green, w: FontWeight.w600)),
            const Spacer(),
            Tag('UYARI $warn', kind: TagKind.amber, height: 22, fontSize: 10.5),
            gap(6),
            Tag('HATA $err', kind: TagKind.red, height: 22, fontSize: 10.5),
            gap(6),
            Tag('${all.length} kayıt', height: 22, fontSize: 10.5),
          ]),
          gap(6),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('Filtreye uyan kayıt yok', style: ts(13.5, color: C.mut)))
                : ListView(
                    children: [
                      for (final e in list)
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: e.lv == _Lv.warn ? rgba(0xF5B73D, .06) : (e.lv == _Lv.err ? rgba(0xFF5A55, .08) : null),
                            border: const Border(bottom: BorderSide(color: Color(0xFF1E3237))),
                          ),
                          child: Row(
                            children: [
                              Text(e.t, style: ts(12, color: C.mut, mono: true)),
                              gap(8),
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: _dot(e.lv), shape: BoxShape.circle)),
                              gap(8),
                              SizedBox(width: 74, child: Text(e.cat, maxLines: 1, style: ts(10, color: C.mut2, w: FontWeight.w700, ls: .8))),
                              Expanded(child: Text(e.msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, color: _txt(e.lv)))),
                              if (e.n > 0) ...[
                                gap(6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF33505A)), borderRadius: BorderRadius.circular(2)),
                                  child: Text('x${e.n}', style: ts(10.5, color: C.mut2)),
                                ),
                              ],
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

  @override
  Widget build(BuildContext context) {
    final cols = _uav < 0 ? [0, 1, 2] : [_uav];
    return PageFrame(
      title: 'SÜRÜ İHA // LOG KAYITLARI',
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Tümü', _uav < 0, () => setState(() => _uav = -1), kind: TagKind.on),
                for (int i = 0; i < 3; i++) _chip('İHA-${i + 1}', _uav == i, () => setState(() => _uav = i), kind: TagKind.on),
                gap(8),
                _chip('BİLGİ ${_count(_Lv.info)}', _lv == _Lv.info, () => setState(() => _lv = _lv == _Lv.info ? null : _Lv.info), color: C.blue),
                _chip('BAŞARI ${_count(_Lv.ok)}', _lv == _Lv.ok, () => setState(() => _lv = _lv == _Lv.ok ? null : _Lv.ok), color: C.green),
                _chip('UYARI ${_count(_Lv.warn)}', _lv == _Lv.warn, () => setState(() => _lv = _lv == _Lv.warn ? null : _Lv.warn), color: C.amber),
                _chip('HATA ${_count(_Lv.err)}', _lv == _Lv.err, () => setState(() => _lv = _lv == _Lv.err ? null : _Lv.err), color: C.red),
                gap(8),
                PopupMenuButton<String>(
                  color: const Color(0xFF0C171A),
                  onSelected: (v) => setState(() => _cat = v),
                  itemBuilder: (_) => [for (final c in _cats) PopupMenuItem(value: c, height: 34, child: Text(c, style: ts(13)))],
                  child: Padding(padding: const EdgeInsets.only(right: 8), child: Tag('Kategori: $_cat ▾', height: 32, fontSize: 12, ls: .3)),
                ),
                Container(
                  width: 190,
                  height: 32,
                  margin: const EdgeInsets.only(right: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: C.dark, border: Border.all(color: const Color(0xFF33505A)), borderRadius: BorderRadius.circular(2)),
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    style: ts(12.5),
                    cursorColor: C.green,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '⌕  Kayıtlarda ara…',
                      hintStyle: ts(12.5, color: C.mut),
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _live = !_live),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tag(_live ? '● CANLI AKIŞ' : '❚❚ DURAKLATILDI', kind: _live ? TagKind.on : TagKind.amber, height: 32, fontSize: 12, ls: .8),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _toast = 'CSV dışa aktarma: log_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.csv hazırlanıyor…'),
                  child: const Tag('⤓ Dışa aktar (CSV)', height: 32, fontSize: 12, ls: .3),
                ),
              ]),
            ),
            if (_toast.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_toast, style: ts(12, color: C.green))),
            gap(8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (int i = 0; i < cols.length; i++) ...[if (i > 0) gap(8), Expanded(child: _col(cols[i]))]],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seviye filtresi etiketi: seçiliyken dolgulu, değilken kenarlıklı.
class _ColoredTag extends StatelessWidget {
  const _ColoredTag(this.text, {required this.on, this.color, this.kind = TagKind.normal});
  final String text;
  final bool on;
  final Color? color;
  final TagKind kind;

  @override
  Widget build(BuildContext context) {
    if (color == null) return Tag(text, kind: on ? kind : TagKind.normal, height: 32, fontSize: 12, ls: 1);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: on ? color!.withAlpha(48) : const Color(0xFF18292E),
        border: Border.all(color: on ? color! : color!.withAlpha(110)),
      ),
      child: Text(text, style: ts(12, color: color!, ls: 1)),
    );
  }
}
