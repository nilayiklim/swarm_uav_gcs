import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

/// KAYNAK (Zenoh) – bağlantı durumu, topic tablosu, bağlantı kalitesi ve ham mesaj akışı.
class KaynakPage extends StatelessWidget {
  const KaynakPage({super.key});

  Widget _kpi(String label, String v, String u, Color c) => Expanded(
        child: GCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.6)),
              gap(2),
              Text.rich(TextSpan(children: [
                TextSpan(text: v, style: ts(26, color: c, w: FontWeight.w300)),
                TextSpan(text: ' $u', style: ts(14, color: C.mut)),
              ])),
            ],
          ),
        ),
      );

  Widget _trow(String topic, String dir, String rate, String last, String status, Color sc, {bool head = false}) {
    TextStyle h() => ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.6);
    return Container(
      height: head ? 30 : 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(topic, style: head ? h() : ts(13, mono: true))),
          Expanded(flex: 3, child: Text(dir, style: head ? h() : ts(14))),
          Expanded(flex: 2, child: Text(rate, style: head ? h() : ts(14))),
          Expanded(flex: 2, child: Text(last, style: head ? h() : ts(14))),
          Expanded(flex: 3, child: Text(status, style: head ? h() : ts(14, color: sc))),
        ],
      ),
    );
  }

  Widget _lk(String n, double v, Color c, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
        child: Row(
          children: [
            SizedBox(width: 60, child: Text(n, style: ts(14.5))),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(color: const Color(0xFF2A3F45), borderRadius: BorderRadius.circular(3)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                ),
              ),
            ),
            SizedBox(
              width: 46,
              child: Text('${(v * 100).round()}%', textAlign: TextAlign.right, style: ts(14.5, color: c, w: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _raw(String time, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '$time ', style: ts(12, color: C.mut, mono: true)),
            TextSpan(text: msg, style: ts(12, color: const Color(0xFFBFD0D4), mono: true)),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final table = Panel(
      title: 'TOPIC TABLOSU',
      trailing: const Tag('6 ABONELİK · 3 YAYIN', kind: TagKind.on),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _trow('TOPIC', 'YÖN', 'HIZ', 'SON MESAJ', 'DURUM', C.text, head: true),
          _trow('skyos/1/pixhawk/in', '← Alınan', '10 Hz', '0.1 sn', '● Aktif', C.green),
          _trow('skyos/2/pixhawk/in', '← Alınan', '10 Hz', '0.1 sn', '● Aktif', C.green),
          _trow('skyos/3/pixhawk/in', '← Alınan', '10 Hz', '0.2 sn', '● Aktif', C.green),
          _trow('uav1/camera', '← Alınan', '30 fps', '0.03 sn', '● Aktif', C.green),
          _trow('swarm/qr_image', '← Alınan', 'olay', '12 sn', '● Beklemede', C.mut),
          _trow('swarm/1/command', '→ Gönderilen', 'olay', '41 sn', '● Aktif', C.green),
          _trow('swarm/2/command', '→ Gönderilen', 'olay', '41 sn', '● Aktif', C.green),
          _trow('swarm/area', '→ Gönderilen', 'olay', '2 dk', '● Eski veri', C.amber),
        ],
      ),
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: 'BAĞLANTI',
          expand: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Peer adresi', style: ts(12.5, color: C.mut)),
              gap(4),
              const FieldBox('tcp/172.20.10.2:7447', mono: true, fontSize: 14),
              gap(10),
              Row(children: const [
                Expanded(child: MetalButton('YENİDEN BAĞLAN', height: 44, fontSize: 11, ls: 1, hPad: 4)),
                SizedBox(width: 8),
                Expanded(child: MetalButton('BAĞLANTIYI KES', height: 44, fontSize: 11, ls: 1, hPad: 4)),
              ]),
            ],
          ),
        ),
        gap(8),
        Panel(
          title: 'BAĞLANTI KALİTESİ',
          expand: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _lk('İHA-1', .94, C.green),
              _lk('İHA-2', .91, C.green),
              _lk('İHA-3', .52, C.amber, last: true),
            ],
          ),
        ),
        gap(8),
        Expanded(
          child: Panel(
            title: 'HAM MESAJ AKIŞI',
            trailing: const Tag('DURAKLAT'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: C.dark,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF27393F)),
              ),
              child: ClipRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _raw('00:14:22.108', 'skyos/1/pixhawk/in {"alt":37.8,"bat":88}'),
                    _raw('00:14:22.101', 'skyos/2/pixhawk/in {"alt":37.5,"bat":76}'),
                    _raw('00:14:22.093', 'skyos/3/pixhawk/in {"alt":0.0,"bat":64}'),
                    _raw('00:14:22.008', 'skyos/1/pixhawk/in {"alt":37.8,"bat":88}'),
                    _raw('00:14:21.999', 'uav1/camera frame#4412 1280x720'),
                    _raw('00:14:21.901', 'skyos/2/pixhawk/in {"alt":37.5,"bat":76}'),
                    _raw('00:14:21.880', 'swarm/area {"area":"blue","t":12}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return PageFrame(
      title: 'SÜRÜ İHA // KAYNAK (ZENOH)',
      bar: EmVariant.standard,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(
              height: 78,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kpi('DURUM', 'Bağlı', '', C.green),
                  gap(8),
                  _kpi('GECİKME', '12', 'ms', C.text),
                  gap(8),
                  _kpi('PAKET KAYBI', '0.3', '%', C.text),
                  gap(8),
                  _kpi('MESAJ HIZI', '148', 'msg/s', C.text),
                  gap(8),
                  _kpi('SON MESAJ', '0.1', 'sn önce', C.text),
                ],
              ),
            ),
            gap(8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(flex: 17, child: table), gap(8), Expanded(flex: 10, child: right)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
