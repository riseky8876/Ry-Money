import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class TabunganScreen extends StatelessWidget {
  const TabunganScreen({super.key, required this.store});

  final RyStore store;

  Future<void> _addGoal(BuildContext context) async {
    final message = await showGoalSheet(context, store);
    if (message != null && context.mounted) showToast(context, message);
  }

  Future<void> _editGoal(BuildContext context, Goal goal) async {
    final message = await showGoalSheet(context, store, goal: goal);
    if (message != null && context.mounted) showToast(context, message);
  }

  Future<void> _deposit(BuildContext context, Goal goal) async {
    final message = await showDepositSheet(context, store, goal);
    if (message != null && context.mounted) showToast(context, message);
  }

  Future<void> _deleteGoal(BuildContext context, Goal goal) async {
    final sure = await confirmAction(
      context,
      title: 'Hapus "${goal.name}"?',
      body: 'Target dan seluruh riwayat setorannya ikut terhapus.',
    );
    if (!sure) return;
    store.state.goals.removeWhere((item) => item.id == goal.id);
    await store.save();
    if (context.mounted) showToast(context, 'Target dihapus.');
  }

  void _toggleAuto(BuildContext context, Goal goal, bool value) {
    goal.autoDeduct = value;
    applyPendingSalaryDeductions(store.state);
    store.changed();
    showToast(
      context,
      value
          ? 'Tabungan "${goal.name}" ikut dipotong tiap gaji.'
          : 'Tabungan "${goal.name}" tidak dipotong otomatis.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = List<Goal>.from(store.state.goals)
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        final da = a.daysLeft ?? 1e9;
        final db = b.daysLeft ?? 1e9;
        return da.compareTo(db);
      });

    final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.target);
    final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.saved);
    final overall = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final monthlyAuto = goals
        .where((g) => g.autoDeduct && !g.done && g.planAmount > 0)
        .fold<double>(0, (sum, g) => sum + g.monthlyPlan);

    return SingleChildScrollView(
      key: const PageStorageKey<String>('tabungan'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Eyebrow('Tabungan'),
          const SizedBox(height: 8),
          Text(
            'Target & wishlist',
            style: T.display(34, height: 1.0, letter: -0.04),
          ),
          const SizedBox(height: 9),
          Text(
            'Tulis barangnya, tentukan ritme menabung — harian, mingguan, bulanan, atau custom — lalu biarkan sisanya dihitung.',
            style: T.body(14, color: R.muted, height: 1.6),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: R.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Eyebrow('Terkumpul untuk semua target'),
                const SizedBox(height: 10),
                BalanceFigure(totalSaved),
                const SizedBox(height: 9),
                Text(
                  totalTarget > 0
                      ? 'dari ${fmtRp(totalTarget)} · ${(overall * 100).round()}%'
                      : 'Belum ada target.',
                  style: T.body(13, color: R.muted),
                ),
                const SizedBox(height: 14),
                ProgressBar(value: overall, height: 7),
                if (monthlyAuto > 0) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '${fmtRp(monthlyAuto)} per bulan dipotong otomatis dari gaji.',
                    style: T.mono(10, color: R.muted, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          SectionHead(
            title: 'Daftar target',
            action: '+ Tambah',
            onAction: () => _addGoal(context),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: goals.isEmpty
                ? EmptyBlock(
                    title: 'Belum ada yang dikejar.',
                    body:
                        'Mulai dari satu barang. Nominal dan ritmenya bebas — per 2 hari, per 10 hari, per minggu, atau per bulan.',
                    action: 'Buat target pertama',
                    onAction: () => _addGoal(context),
                  )
                : Column(
                    children: <Widget>[
                      for (final goal in goals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _GoalCard(
                            goal: goal,
                            onDeposit: () => _deposit(context, goal),
                            onEdit: () => _editGoal(context, goal),
                            onDelete: () => _deleteGoal(context, goal),
                            onToggleAuto: (value) =>
                                _toggleAuto(context, goal, value),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onDeposit,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAuto,
  });

  final Goal goal;
  final VoidCallback onDeposit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleAuto;

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();
    final autoValue = goal.autoDeduct && !goal.done;
    final autoSubtitle = goal.done
        ? 'Target sudah tercapai.'
        : goal.planAmount <= 0
            ? 'Isi nominal nabung untuk mengaktifkan.'
            : goal.autoDeduct
                ? '${fmtRp(goal.monthlyPlan)} disisihkan tiap gaji.'
                : 'Aktifkan agar gaji menyisihkan ${fmtRp(goal.monthlyPlan)}.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: R.ink2,
        border: Border.all(
          color: goal.done ? R.olive.withAlpha(170) : R.line,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  goal.name,
                  style: T.display(21, height: 1.1),
                ),
              ),
              const SizedBox(width: 8),
              if (goal.done)
                const Stamp('Tercapai', color: R.acid)
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$percent%',
                    style: T.mono(12, color: R.paperDim),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: Text(
                  fmtRp(goal.saved),
                  style: T.display(30, height: 1.0, letter: -0.04),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '/ ${fmtRp(goal.target)}',
                style: T.mono(11, color: R.muted, letter: -0.1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: goal.progress, height: 6),
          const SizedBox(height: 9),
          Text(
            'Rencana ${fmtRp(goal.planAmount)} ${goal.rhythmLabel}',
            style: T.mono(10, color: R.muted, height: 1.5, letter: -0.1),
          ),
          const SizedBox(height: 2),
          Text(
            goal.done
                ? 'target tercapai'
                : '${fmtRp(goal.remaining)} lagi · ${etaLabel(goal.daysLeft)}',
            style: T.mono(10, color: R.muted, height: 1.5, letter: -0.1),
          ),
          const SizedBox(height: 12),
          ToggleRow(
            title: 'Potong dari gaji',
            subtitle: autoSubtitle,
            value: autoValue,
            onChanged: goal.done || goal.planAmount <= 0 ? null : onToggleAuto,
            icon: Icons.savings_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              RyButton(
                label: 'Setor',
                small: true,
                onTap: onDeposit,
              ),
              const SizedBox(width: 8),
              RyButton(
                label: 'Ubah',
                kind: RyButtonKind.ghost,
                small: true,
                onTap: onEdit,
              ),
              const Spacer(),
              RyIconButton(
                icon: Icons.close_rounded,
                size: 17,
                onTap: onDelete,
                tooltip: 'Hapus ${goal.name}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
