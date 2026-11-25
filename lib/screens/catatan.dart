import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class CatatanScreen extends StatelessWidget {
  const CatatanScreen({super.key, required this.store});

  final RyStore store;

  Future<void> _addTxn(BuildContext context) async {
    final message = await showTxnSheet(context, store);
    if (message != null && context.mounted) showToast(context, message);
  }

  Future<void> _deleteTxn(BuildContext context, Txn txn) async {
    final sure = await confirmAction(
      context,
      title: 'Hapus catatan ini?',
      body: '${txn.note.isEmpty ? txn.category : txn.note} · ${fmtRp(txn.amount)}',
    );
    if (!sure) return;
    store.state.txns.removeWhere((item) => item.id == txn.id);
    await store.save();
    if (context.mounted) showToast(context, 'Catatan dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final month = store.state.month;
    final list = store.state.txns
        .where((txn) => inMonth(txn.date, month))
        .toList();
    final groups = groupTxnsByDay(list);
    final spent = list
        .where((txn) => !txn.isIncome)
        .fold<double>(0, (sum, txn) => sum + txn.amount);
    final masuk = list
        .where((txn) => txn.isIncome)
        .fold<double>(0, (sum, txn) => sum + txn.amount);
    final categories = spendingByCategory(store.state, month);
    final maxCategory =
        categories.isEmpty ? 0.0 : categories.first.amount;

    return SingleChildScrollView(
      key: const PageStorageKey<String>('catatan'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Eyebrow('Catatan'),
          const SizedBox(height: 8),
          Text(
            'Keluar & masuk',
            style: T.display(34, height: 1.0, letter: -0.04),
          ),
          const SizedBox(height: 9),
          Text(
            'Setiap pengeluaran kecil tetap punya tempat di sini.',
            style: T.body(14, color: R.muted, height: 1.6),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: R.line),
                bottom: BorderSide(color: R.line),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryItem(
                    label: 'Keluar',
                    value: fmtRp(spent),
                    color: R.rust,
                  ),
                ),
                Container(width: 1, height: 38, color: R.line),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryItem(
                    label: 'Masuk',
                    value: fmtRp(masuk),
                    color: R.acid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RyButton(
            label: '+ Catat transaksi',
            block: true,
            onTap: () => _addTxn(context),
          ),
          if (categories.isNotEmpty) ...<Widget>[
            SectionHead(
              title: 'Ke mana perginya',
              trailing: '${categories.length} kategori',
            ),
            const SizedBox(height: 8),
            for (final slice in categories.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            slice.name,
                            style: T.body(13, color: R.paperDim),
                          ),
                        ),
                        Text(
                          fmtRp(slice.amount),
                          style: T.mono(11.5, color: R.paperDim, letter: -0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ProgressBar(
                      value: maxCategory > 0 ? slice.amount / maxCategory : 0,
                      color: R.olive,
                      height: 4,
                    ),
                  ],
                ),
              ),
          ],
          if (groups.isEmpty)
            EmptyBlock(
              title: 'Masih bersih.',
              body:
                  'Catat pengeluaran pertama bulan ini — sekecil apa pun. Angka di ringkasan ikut bergerak.',
              action: 'Catat sekarang',
              onAction: () => _addTxn(context),
            )
          else
            for (final group in groups)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(bottom: 7),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: R.line2)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              fmtDayHead(group.date),
                              style: T.body(
                                12,
                                color: R.paperDim,
                                weight: FontWeight.w500,
                                letter: 0.1,
                              ),
                            ),
                          ),
                          Text(
                            '${group.net < 0 ? '−' : '+'}${fmtRp(group.net.abs())}',
                            style: T.mono(
                              11.5,
                              color: group.net < 0 ? R.muted : R.acid,
                              letter: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final txn in group.items)
                      _TxnRow(
                        txn: txn,
                        onDelete: () => _deleteTxn(context, txn),
                      ),
                  ],
                ),
              ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Eyebrow(label),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: T.display(25, height: 1.0, letter: -0.03, color: color),
          ),
        ),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.onDelete});

  final Txn txn;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = txn.note.isEmpty
        ? (txn.category.isEmpty ? 'Tanpa keterangan' : txn.category)
        : txn.note;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: R.line)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: T.body(14, color: R.paper),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  txn.category.isEmpty ? 'Lainnya' : txn.category,
                  style: T.body(11.5, color: R.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${txn.isIncome ? '+' : '−'}${fmtRp(txn.amount)}',
            style: T.mono(
              12,
              color: txn.isIncome ? R.acid : R.paper,
              letter: -0.1,
            ),
          ),
          RyIconButton(
            icon: Icons.close_rounded,
            size: 16,
            onTap: onDelete,
            tooltip: 'Hapus catatan',
          ),
        ],
      ),
    );
  }
}
