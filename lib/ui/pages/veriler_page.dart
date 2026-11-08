import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

/// VERİLER – seçili İHA için 11 ayrıntılı veri paneli (ArduPilot / MAVLink mesaj alanları).
/// Kutunun üzerine gelince büyür ve tüm satırlar + alan adları görünür.
class VerilerPage extends StatefulWidget {
  const VerilerPage({super.key});

  @override
  State<VerilerPage> createState() => _VerilerPageState();
}

class _R {
  const _R(this.k, this.v, this.f, {this.c, this.bar});
  final String k; // etiket
  final String v; // değer
  final String f; // MAVLink alan adı
  final Color? c;
  final double? bar; // 0..1 küçük çubuk
}

class _P {
  const _P(this.title, this.msg, this.row, this.col, this.rows, {this.span = 1, this.flags = const [], this.extra = 0});
  final String title;
  final String msg;
  final int row, col, span;
  final List<_R> rows;
  final List<String> flags; // Sistem durumu çipleri
  final int extra; // "+N" rozeti
}

const _blue = Color(0xFF8EC9F5);

class _VerilerPageState extends State<VerilerPage> {
  int _sel = 0;
  int _hover = -1;

  static const _bat = [88, 76, 64];
  static const _volt = ['15.8', '15.1', '14.6'];
  static const _amp = ['18.4', '17.9', '17.2'];
  static const _mah = ['1240', '1890', '2410'];
  static const _cell = ['3.93', '3.77', '3.64'];
  static const _temp = ['31', '32', '34'];
  static const _eta = ['14', '11', '8'];
  static const _agl = ['37.7', '37.5', '37.7'];
  static const _msl = ['112.4', '112.2', '112.4'];
  static const _climb = ['+0.1', '−0.1', '+0.0'];
  static const _alte = ['0.3', '0.4', '0.6'];
  static const _gs = '10.1';
  static const _as = ['10.4', '10.3', '10.2'];
  static const _wind = ['2.1', '2.0', '2.4'];
  static const _vx = ['+8.3', '+8.2', '−1.9'];
  static const _vy = ['+5.7', '+5.9', '+9.9'];
  static const _vz = ['−0.1', '+0.1', '+0.0'];
  static const _roll = ['+1.8', '−1.2', '+3.4'];
  static const _pitch = ['+2.1', '+1.8', '+0.9'];
  static const _yaw = ['124', '124', '98'];
  static const _rs = ['+0.4', '−0.3', '+1.1'];
  static const _ps = ['−0.2', '+0.1', '+0.3'];
  static const _ys = ['+0.6', '+0.5', '−1.4'];
  static const _tb = ['287', '291', '305'];
  static const _sats = ['12', '11', '11'];
  static const _hdop = ['1.0', '1.1', '1.1'];
  static const _vdop = ['1.4', '1.5', '1.6'];
  static const _lat = ['409812299', '409813800', '409816999'];
  static const _lon = ['290231100', '290229000', '290235000'];
  static const _alt = ['112400', '112200', '112400'];
  static const _eph = ['100 · 140', '110 · 150', '110 · 160'];
  static const _cog = ['1010 · 12400', '1010 · 12400', '1010 · 9800'];
  static const _latd = ['40.981230', '40.981380', '40.981700'];
  static const _lond = ['29.023110', '29.022900', '29.023500'];
  static const _home = ['182', '165', '240'];
  static const _thr = ['52', '51', '49'];
  static const _cpu = ['34', '36', '39'];
  static const _rtt = ['12', '14', '16'];
  static const _lat2 = ['84', '91', '240'];
  static const _rssi = ['-58', '-60', '-71'];

  List<_P> _panels(int i) {
    final lateLink = i == 2;
    return [
      _P('BATARYA', 'SYS_STATUS', 0, 0, extra: 4, [
        _R('Kalan', '%${_bat[i]}', 'battery_remaining', c: _bat[i] < 70 ? C.amber : C.green, bar: _bat[i] / 100),
        _R('Gerilim', '${_volt[i]} V', 'voltage_battery'),
        _R('Akım', '${_amp[i]} A', 'current_battery'),
        _R('Tüketilen', '${_mah[i]} mAh', 'current_consumed'),
        _R('Hücre (min)', '${_cell[i]} V', 'voltages[ ]'),
        _R('Sıcaklık', '${_temp[i]} °C', 'temperature'),
        _R('Tahmini süre', '${_eta[i]} dk', 'hesaplanan'),
      ]),
      _P('İRTİFA', 'GLOBAL_POSITION_INT', 0, 1, extra: 4, [
        _R('Göreli (AGL)', '${_agl[i]} m', 'relative_alt'),
        _R('Deniz seviyesi', '${_msl[i]} m', 'alt (MSL)'),
        _R('Zemin (SRTM)', '74.7 m', 'terrain_alt'),
        _R('Barometre', '1004.2 hPa', 'press_abs'),
        _R('Dikey hız', '${_climb[i]} m/s', 'climb'),
        _R('İrtifa hatası', '${_alte[i]} m', 'alt_error'),
        _R('Hedef irtifa', '37.5 m', 'alt_target'),
      ]),
      _P('HIZ', 'VFR_HUD · GLOBAL_POS', 0, 2, extra: 4, [
        _R('Yer hızı', '$_gs m/s', 'groundspeed'),
        _R('Hava hızı', '${_as[i]} m/s', 'airspeed'),
        _R('Rüzgâr', '${_wind[i]} m/s', 'wind_vel'),
        _R('Hız K (vx)', '${_vx[i]} m/s', 'vx · kuzey'),
        _R('Hız D (vy)', '${_vy[i]} m/s', 'vy · doğu'),
        _R('Hız Y (vz)', '${_vz[i]} m/s', 'vz · aşağı'),
        _R('Hedef hız', '10.0 m/s', 'aspd_target'),
      ]),
      _P('YÖN', 'ATTITUDE', 0, 3, extra: 4, [
        _R('Roll', '${_roll[i]}°', 'roll'),
        _R('Pitch', '${_pitch[i]}°', 'pitch'),
        _R('Yaw / Heading', '${_yaw[i]}°', 'yaw · heading'),
        _R('Roll hızı', '${_rs[i]} °/s', 'rollspeed'),
        _R('Pitch hızı', '${_ps[i]} °/s', 'pitchspeed'),
        _R('Yaw hızı', '${_ys[i]} °/s', 'yawspeed'),
        _R('Hedef yön', '${_tb[i]}°', 'target_bearing'),
      ]),
      _P('DURUM', 'HEARTBEAT', 1, 0, extra: 4, [
        _R('Arm', 'ARMED', 'base_mode', c: C.green),
        _R('Uçuş modu', 'GUIDED', 'custom_mode', c: _blue),
        _R('Sistem durumu', 'ACTIVE', 'system_status', c: C.green),
        _R('Otopilot', 'ArduPilot', 'MAV_AUTOPILOT'),
        _R('MAVLink', 'v2.0', 'mavlink_version'),
        _R('Heartbeat', '1.0 Hz', 'son: 0.4 s önce'),
        _R('Sistem ID', 'SYSID ${i + 1}', 'target_system'),
      ]),
      _P('GPS', 'GPS_STATUS', 1, 1, extra: 4, [
        _R('Fix tipi', '3D FIX', 'fix_type', c: C.green),
        _R('Uydu sayısı', _sats[i], 'satellites_visible', bar: int.parse(_sats[i]) / 16),
        _R('HDOP', _hdop[i], 'eph / 100'),
        _R('VDOP', _vdop[i], 'epv / 100'),
        _R('Yatay doğruluk', '1.2 m', 'h_acc'),
        _R('Dikey doğruluk', '1.9 m', 'v_acc'),
        _R('DGPS / RTK', 'Yok', 'fix_type'),
      ]),
      _P('GPS RAW', 'GPS_RAW_INT', 1, 2, extra: 4, [
        _R('time_usec', '184 322 650', 'µs'),
        _R('fix_type', '3', 'enum'),
        _R('lat', _lat[i], 'degE7'),
        _R('lon', _lon[i], 'degE7'),
        _R('alt', _alt[i], 'mm'),
        _R('eph · epv', _eph[i], 'cm'),
        _R('vel · cog', _cog[i], 'cm/s · cdeg'),
      ]),
      _P('KONUM', 'GLOBAL_POSITION_INT', 1, 3, extra: 4, [
        _R('Enlem', '${_latd[i]}° K', 'lat'),
        _R('Boylam', '${_lond[i]}° D', 'lon'),
        _R('MSL irtifa', '${_msl[i]} m', 'alt'),
        _R('Göreli irtifa', '${_agl[i]} m', 'relative_alt'),
        _R('Home mesafesi', '${_home[i]} m', 'HOME_POSITION'),
        _R('Home yönü', '${_tb[i]}°', 'bearing'),
        _R('Yer yönü (COG)', '${_yaw[i]}°', 'hdg'),
      ]),
      _P('VFR HUD', 'VFR_HUD', 2, 0, extra: 3, [
        _R('airspeed', _as[i], 'm/s'),
        _R('groundspeed', _gs, 'm/s'),
        _R('heading', _yaw[i], '° 0–360'),
        _R('throttle', _thr[i], '% 0–100'),
        _R('alt', _msl[i], 'm MSL'),
        _R('climb', _climb[i], 'm/s'),
      ]),
      _P('SİSTEM DURUMU', 'SYS_STATUS', 2, 1, span: 2, extra: 2, flags: const [
        '3D GYRO', '3D ACCEL', '3D MAG', 'ABS PRESSURE', 'GPS', 'AHRS', 'BATTERY', 'MOTOR OUT', 'RC RECEIVER', 'LOGGING', 'PREARM', 'GEOFENCE'
      ], [
        _R('CPU yükü', '%${_cpu[i]}', 'load / 10', bar: int.parse(_cpu[i]) / 100),
        _R('Haberleşme hatası', '3', 'errors_comm'),
        _R('Sistem kaybı', '%0.4', 'drop_rate_comm'),
      ]),
      _P('HABERLEŞME', 'Zenoh · RADIO_STATUS', 2, 3, extra: 3, [
        _R('Zenoh RTT', '${_rtt[i]} ms', 'bağlantı'),
        _R('Telemetri gecikmesi', '${_lat2[i]} ms', 'ölçülen', c: lateLink ? C.amber : null),
        _R('Telemetri hızı', '4.8 Hz', 'akış'),
        _R('Paket kaybı', '%0.4', 'drop_rate_comm'),
        _R('Sinyal (RSSI)', '${_rssi[i]} dBm', 'rssi'),
        _R('Son paket', '0.2 s önce', 'zaman damgası'),
      ]),
    ];
  }

  Widget _tab(int i) {
    final on = i == _sel;
    return GestureDetector(
      onTap: () => setState(() => _sel = i),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tag('İHA-${i + 1}', kind: on ? TagKind.on : TagKind.normal, height: 30, fontSize: 12.5, ls: 1),
      ),
    );
  }

  Widget _row(_R r, bool hovered) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(r.k, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13.5, color: const Color(0xFFC8D6D9))),
        ),
        if (r.bar != null)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFF2A3F45), borderRadius: BorderRadius.circular(2)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: r.bar!.clamp(0.0, 1.0).toDouble(),
                  child: Container(decoration: BoxDecoration(color: r.c ?? C.green, borderRadius: BorderRadius.circular(2))),
                ),
              ),
            ),
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(r.v, maxLines: 1, style: ts(r.bar != null ? 15 : 16, color: r.c ?? C.text, w: FontWeight.w600)),
            if (hovered) Text(r.f, maxLines: 1, style: ts(9.5, color: C.mut, mono: true)),
          ],
        ),
      ],
    );
  }

  Widget _panel(_P p, bool hovered) {
    final visible = hovered ? p.rows : p.rows.take(p.flags.isNotEmpty ? 1 : 3).toList();
    final chips = p.flags.isEmpty
        ? null
        : Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in p.flags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rgba(0x3FD97F, .08),
                    border: Border.all(color: const Color(0xFF2E9060)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '● ', style: ts(8, color: C.green)),
                    TextSpan(text: f, style: ts(10.5, color: C.green, ls: .8, w: FontWeight.w600)),
                  ])),
                ),
            ],
          );
    Widget list;
    if (hovered) {
      list = Column(
        children: [
          for (final r in visible)
            Container(
              height: 36,
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
              child: _row(r, true),
            ),
        ],
      );
    } else {
      list = Column(
        children: [
          for (final r in visible)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
                child: _row(r, false),
              ),
            ),
        ],
      );
    }
    final title = Row(children: [
      Text(p.title, style: ts(13, w: FontWeight.w700, ls: 1.4)),
      gap(8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E9060)), borderRadius: BorderRadius.circular(2)),
        child: Text('+${p.extra}', style: ts(10, color: C.green)),
      ),
      const Spacer(),
      Flexible(child: Text(p.msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(9.5, color: C.mut, mono: true))),
    ]);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: hovered ? C.green : C.panelLine),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF183137), Color(0xFF12232A)]),
        boxShadow: [BoxShadow(color: rgba(0x000000, hovered ? .6 : .3), blurRadius: hovered ? 26 : 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          gap(8),
          if (chips != null) ...[chips, gap(6)],
          if (hovered) Flexible(child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: list)) else Expanded(child: list),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = _panels(_sel);
    return PageFrame(
      title: 'SÜRÜ İHA // VERİLER',
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              for (int i = 0; i < 3; i++) _tab(i),
              const Spacer(),
              const Tag('Kutunun üzerine gel: tüm alanlar açılır · Kaynak: MAVLink (ArduPilot)', height: 30, fontSize: 12, ls: .2),
              gap(8),
              const Tag('● CANLI · 4.8 Hz', kind: TagKind.on, height: 30, fontSize: 12, ls: .6),
            ]),
            gap(8),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                const g = 8.0;
                final cw = (box.maxWidth - g * 3) / 4;
                final ch = (box.maxHeight - g * 2) / 3;
                Rect base(_P c) => Rect.fromLTWH(c.col * (cw + g), c.row * (ch + g), cw * c.span + g * (c.span - 1), ch);
                Rect grown(_P c) {
                  final r = base(c);
                  final dw = c.span > 1 ? 0.0 : r.width * .28;
                  final need = (c.rows.length * 36.0 + 78 + (c.flags.isEmpty ? 0 : 70)).clamp(r.height, box.maxHeight).toDouble();
                  final dh = need - r.height;
                  final left = c.col + c.span >= 4 ? r.left - dw : r.left;
                  final top = c.row == 2 ? r.top - dh : (c.row == 1 ? r.top - dh * .25 : r.top);
                  return Rect.fromLTWH(left, top.clamp(0.0, box.maxHeight).toDouble(), r.width + dw, r.height + dh);
                }

                final order = [for (int i = 0; i < cells.length; i++) if (i != _hover) i, if (_hover >= 0) _hover];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final i in order)
                      AnimatedPositioned(
                        key: ValueKey('c$i'),
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        left: (i == _hover ? grown(cells[i]) : base(cells[i])).left,
                        top: (i == _hover ? grown(cells[i]) : base(cells[i])).top,
                        width: (i == _hover ? grown(cells[i]) : base(cells[i])).width,
                        height: (i == _hover ? grown(cells[i]) : base(cells[i])).height,
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hover = i),
                          onExit: (_) => setState(() {
                            if (_hover == i) _hover = -1;
                          }),
                          child: _panel(cells[i], i == _hover),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
