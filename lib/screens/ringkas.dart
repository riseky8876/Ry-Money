import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class RingkasScreen extends StatelessWidget {
  const RingkasScreen({
    super.key,
    required this.store,
    required this.onGoTo,
  });

  final RyStore store;
  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    final state = store.state;
    final month = state.month;
    final totals = monthTotals(state, month);
    final active = state.routines.where((r) => r.active).toList();
    final planned = active.fold<double>(0, (sum, r) => sum + r.monthly);
    final inflow = totals.inflow;
    final over = totals.available < 0;
    final whole = inflow > 0
        ? ((totals.available < 0 ? 0 : totals.available) / inflow * 100)
            .round()
            .clamp(0, 100)
        : 0;

    double share(double value) {
      if (inflow <= 0) return 0;
      return (value / inflow * 100).clamp(0, 100).toDouble();
    }

    final recent = state.txns
        .where((txn) => inMonth(txn.date, month))
        .toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    final goals = state.goals.where((g) => !g.done).toList()
      ..sort((a, b) {
        final da = a.daysLeft ?? 1e9;
        final db = b.daysLeft ?? 1e9;
        return da.compareTo(db);
      });

    final note = inflow <= 0
        ? 'Catat gaji dulu supaya angka ini hidup.'
        : over
            ? 'Pengeluaran melebihi pemasukan bulan ini.'
            : 'dari ${fmtRp(inflow)} yang masuk bulan ini.';

    return SingleChildScrollView(
      key: const PageStorageKey<String>('ringkas'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Eyebrow('Buku kas · ${monthLabel(month)}'),
          const SizedBox(height: 8),
          Text(
            'Uangmu,\ndalam satu garis.',
            style: T.display(38, height: 0.98, letter: -0.045),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 6, bottom: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: R.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Eyebrow('Sisa bisa dipakai'),
                        const SizedBox(height: 10),
                        BalanceFigure(totals.available),
                        const SizedBox(height: 10),
                        Text(
                          note,
                          style: T.body(13, color: R.muted, height: 1.4),
                        ),
                      ],
                    ),
                    if (inflow > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Stamp('$whole% utuh'),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SplitBar(
                  parts: <SplitPart>[
                    SplitPart(R.olive, totals.allocated),
                    SplitPart(R.save, totals.saved),
                    SplitPart(R.spend, totals.spent),
                    SplitPart(R.acid, totals.available < 0 ? 0 : totals.available),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: <Widget>[
                    _LegendItem(
                      color: R.olive,
                      label: 'Penyisihan ${share(totals.allocated).round()}%',
                    ),
                    _LegendItem(
                      color: R.save,
                      label: 'Tabungan ${share(totals.saved).round()}%',
                    ),
                    _LegendItem(
                      color: R.spend,
                      label: 'Belanja ${share(totals.spent).round()}%',
                    ),
                    _LegendItem(
                      color: R.acid,
                      label: 'Sisa '
                          '${share(totals.available < 0 ? 0 : totals.available).round()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          LedgerRow('Gaji masuk', fmtRp(totals.income)),
          if (totals.extra > 0)
            LedgerRow('Pemasukan lain', fmtRp(totals.extra)),
          LedgerRow('Penyisihan rutin', '−${fmtRp(totals.allocated)}'),
          LedgerRow('Setor tabungan', '−${fmtRp(totals.saved)}'),
          LedgerRow('Pengeluaran', '−${fmtRp(totals.spent)}'),
          LedgerRow(
            'Sisa',
            fmtRp(totals.available),
            total: true,
            negative: over,
          ),
          if (!state.hasData)
            EmptyBlock(
              eyebrow: 'Mulai dari sini',
              title: 'Mulai dari gaji.',
              body:
                  'Sekitar dua menit. Tidak ada akun, tidak ada server, tidak ada iklan.',
              action: 'Catat gaji',
              onAction: () => onGoTo(1),
            ),
          if (active.isNotEmpty) ...<Widget>[
            SectionHead(
              title: 'Penyisihan',
              action: 'Kelola',
              onAction: () => onGoTo(1),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                '${fmtRp(planned)} per bulan dari ${active.length} rutinitas aktif.',
                style: T.body(12, color: R.muted, height: 1.4),
              ),
            ),
            for (final routine in active.take(4))
              _MiniRow(
                title: routine.name,
                subtitle:
                    '${fmtRp(routine.amount)} ${routine.rhythmLabel}',
                value: fmtRp(routine.monthly),
              ),
          ],
          if (goals.isNotEmpty) ...<Widget>[
            SectionHead(
              title: 'Dikejar',
              action: 'Semua target',
              onAction: () => onGoTo(2),
            ),
            const SizedBox(height: 8),
            for (final goal in goals.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            goal.name,
                            style: T.display(19, height: 1.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(goal.progress * 100).round()}%',
                          style: T.mono(11.5, color: R.paperDim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(value: goal.progress, height: 5),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        Text(
                          '${fmtRp(goal.saved)} / ${fmtRp(goal.target)}',
                          style: T.mono(10.5, color: R.muted, letter: -0.1),
                        ),
                        const Spacer(),
                        Text(
                          etaLabel(goal.daysLeft),
                          style: T.mono(10.5, color: R.muted, letter: -0.1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
          if (recent.isNotEmpty) ...<Widget>[
            SectionHead(
              title: 'Terakhir',
              action: 'Semua catatan',
              onAction: () => onGoTo(3),
            ),
            const SizedBox(height: 4),
            for (final txn in recent.take(4))
              _MiniRow(
                title: txn.note.isEmpty
                    ? (txn.category.isEmpty ? 'Tanpa keterangan' : txn.category)
                    : txn.note,
                subtitle: '${txn.category.isEmpty ? 'Lainnya' : txn.category} · ${fmtDate(txn.date)}',
                value:
                    '${txn.isIncome ? '+' : '−'}${fmtRp(txn.amount)}',
                valueColor: txn.isIncome ? R.acid : R.paper,
              ),
          ],
          const SizedBox(height: 26),
          Text(
            'Data tersimpan di HP ini. Cadangkan dari tombol pengaturan di atas.',
            style: T.mono(9.5, color: R.muted, height: 1.6, letter: 0.2),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 7),
        Text(label, style: T.body(12, color: R.muted)),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor = R.paper,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: R.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: T.body(14, color: R.paper, height: 1.35),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: T.body(11.5, color: R.muted, height: 1.35),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              value,
              style: T.mono(12, color: valueColor, letter: -0.1),
            ),
          ),
        ],
      ),
    );
  }
}
