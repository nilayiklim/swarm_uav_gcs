import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

/// PARAMETRE – alarm eşikleri, ses, harita, bağlantı, görev profili ve formasyon varsayılanları.
class ParametrePage extends StatelessWidget {
  const ParametrePage({super.key});

  Widget _pr(String label, String sub, double v, String val, String unit, {bool last = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF1E3237))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15)),
                  gap(2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12.5, color: C.mut2)),
                ],
              ),
            ),
            gap(14),
            Expanded(flex: 15, child: FakeSlider(v)),
            gap(14),
            SizedBox(width: 92, child: FieldBox(val, unit: unit)),
          ],
        ),
      ),
    );
  }

  Widget _seg(String t, bool on) => Expanded(child: Tag(t, kind: on ? TagKind.on : TagKind.normal, height: 38, fontSize: 13, ls: 1, centered: true));

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: ts(12.5, color: C.mut)),
      );

  Widget _row3(List<String> c, {bool head = false}) {
    const flex = [3, 3, 3, 2];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3237)))),
      child: Row(
        children: [
          for (int i = 0; i < c.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(c[i],
                  style: head ? ts(10.5, color: C.label, w: FontWeight.w600, ls: 1.6) : ts(14)),
            ),
        ],
      ),
    );
  }

  Widget _kvRow(String l, String v, String? u) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(l, style: ts(14.5))),
            SizedBox(width: 92, child: FieldBox(v, unit: u)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final alarms = Panel(
      title: 'ALARM EŞİKLERİ',
      trailing: const Tag('KAYDEDİLMEDİ', kind: TagKind.amber),
      child: Column(
        children: [
          _pr('Batarya uyarı (sarı)', 'Tek kısa bip', .30, '30', '%'),
          _pr('Batarya kritik (kırmızı)', 'Onaylanana kadar tekrar eder', .20, '20', '%'),
          _pr('Minimum uydu sayısı', 'Altında GPS uyarısı', .40, '8', 'adet'),
          _pr('Eski veri süresi', 'Bu süreden uzun veri gelmezse etiket çıkar', .20, '2.0', 'sn'),
          _pr('Fail-safe geri sayımı', 'Sürekli bip, sayaç ekranda', .50, '5', 'sn'),
          _pr('Min. İHA arası mesafe', 'Altında kırmızı alarm', .25, '5.0', 'm'),
          _pr('Alarm tekrar bekleme', 'Onaylanan alarm bu süre sessiz kalır', .30, '30', 'sn', last: true),
        ],
      ),
    );

    final sound = Panel(
      title: 'SES',
      trailing: const Tag('AÇIK', kind: TagKind.on),
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            SizedBox(width: 70, child: Text('Seviye', style: ts(15))),
            const Expanded(child: FakeSlider(.7)),
            gap(12),
            Text('%70', style: ts(15)),
          ]),
          gap(14),
          Row(children: const [
            Expanded(child: MetalButton('UYARI TESTİ', height: 44, fontSize: 11, ls: 1, hPad: 4)),
            SizedBox(width: 8),
            Expanded(child: MetalButton('KRİTİK TESTİ', height: 44, fontSize: 11, ls: 1, hPad: 4, kind: BtnKind.dangerOutline)),
            SizedBox(width: 8),
            Expanded(child: MetalButton('FAIL-SAFE TESTİ', height: 44, fontSize: 11, ls: 1, hPad: 4)),
          ]),
          gap(10),
          Text('Yarışma öncesi sesi hoparlörle deneyin, açık havada gürültü yüksek olabilir.', style: ts(13.5, color: C.mut)),
        ],
      ),
    );

    final map = Panel(
      title: 'HARİTA',
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [_seg('ÇEVRİMDIŞI', true), gap(6), _seg('ÇEVRİMİÇİ', false)]),
          gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Önbellek: 412 MB · dün güncellendi', style: ts(14.5)), const Tag('HAZIR', kind: TagKind.on)],
          ),
        ],
      ),
    );

    final conn = Panel(
      title: 'BAĞLANTI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _lbl('Zenoh peer'),
          const FieldBox('tcp/172.20.10.2:7447', mono: true, fontSize: 14.5),
          gap(10),
          _lbl('Yeniden bağlanma'),
          const FieldBox('3', unit: 'sn'),
        ],
      ),
    );

    final mission = Panel(
      title: 'GÖREV PROFİLİ',
      expand: false,
      trailing: Row(children: const [Tag('KAYDET'), SizedBox(width: 6), Tag('YÜKLE')]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FieldBox('Profil: Yarışma · Gaziantep', unit: '▾'),
          gap(8),
          _row3(const ['NOKTA', 'ENLEM', 'BOYLAM', 'İRT.'], head: true),
          _row3(const ['Başlangıç', '40.1200', '32.5600', '0 m']),
          _row3(const ['QR-1', '40.1234', '32.5678', '30 m']),
          _row3(const ['Mavi alan', '40.1221', '32.5661', '0 m']),
          _row3(const ['Kırmızı alan', '40.1218', '32.5664', '0 m']),
        ],
      ),
    );

    final formation = Panel(
      title: 'FORMASYON VARSAYILANLARI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: const [
            Tag('V', kind: TagKind.on, height: 34),
            SizedBox(width: 6),
            Tag('OK', height: 34),
            SizedBox(width: 6),
            Tag('ÇİZGİ', height: 34),
          ]),
          gap(12),
          _kvRow('İHA sayısı', '3', null),
          _kvRow('Ajanlar arası mesafe', '15.0', 'm'),
          _kvRow('Yaw hızı', '10', '°/s'),
        ],
      ),
    );

    return PageFrame(
      title: 'SÜRÜ İHA // PARAMETRELER',
      bar: EmVariant.standard,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 125, child: alarms),
            gap(8),
            Expanded(
              flex: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [sound, gap(8), map, gap(8), Expanded(child: conn)],
              ),
            ),
            gap(8),
            Expanded(
              flex: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [mission, gap(8), Expanded(child: formation)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
