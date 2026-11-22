import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme.dart';
import 'widgets.dart';

/// Çözümlenen QR JSON içeriğinin alanlara ayrılmış gösterimi
/// Şartname sırası: ① formasyon → ② pitch/roll manevrası → ③ irtifa → ④ birey ekleme/çıkarma → ⑤ sonraki QR;
/// her görev arasında QR'daki "w" kadar beklenir.
class QrParsedCard extends StatelessWidget {
  const QrParsedCard({super.key, required this.task, this.showJson = true});
  final QrTask task;
  final bool showJson;

  Widget _cell(String k, String v, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: C.dark,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: lc(0xFF27393F)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: ts(9.5, color: C.label, w: FontWeight.w600, ls: 1.1)),
            gap(2),
            Text(v, style: ts(14.5, color: color, w: FontWeight.w700)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: teamId,
      builder: (context, team, _) {
        final st = task.stepFor(team);
        final next = task.nextFor(team);
        final leaveCol = task.leaveColor == 'KIRMIZI' ? C.red : C.blue;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              _cell('QR NO', '${task.no}', color: C.green),
              _cell('TAKIM $team BLOĞU', '#${task.blockFor(team)} / ${task.mis.length}'),
              _cell('GÖREVLER ARASI BEKLEME (w)', '${task.wait} sn'),
              _cell('1 · FORMASYON', '${st.frmName} · ${st.dist.toStringAsFixed(0)} m'),
              _cell('2 · MANEVRA (PITCH / ROLL)', '${st.pitch.toStringAsFixed(0)}° / ${st.roll.toStringAsFixed(0)}°'),
              _cell('3 · İRTİFA', '${st.alt.toStringAsFixed(0)} m'),
              if (task.leaveId != null)
                _cell('4 · BİREY ÇIKAR', 'İHA-${task.leaveId} → ${task.leaveColor}', color: leaveCol)
              else
                _cell('4 · BİREY EKLE/ÇIKAR', 'Bu QR\'da yok', color: C.mut),
              _cell('5 · SONRAKİ QR', next == 0 ? '0 · SON GÖREV → HOME' : '$next', color: C.amber),
            ]),
            if (showJson) ...[
              gap(8),
              Text('HAM JSON', style: ts(10, color: C.label, w: FontWeight.w600, ls: 1.4)),
              gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: C.dark, border: Border.all(color: lc(0xFF33505A)), borderRadius: BorderRadius.circular(2)),
                child: Text(task.json, style: ts(11, mono: true, color: C.green)),
              ),
            ],
          ],
        );
      },
    );
  }
}
