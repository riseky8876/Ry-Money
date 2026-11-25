import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../sheets.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class GajiScreen extends StatelessWidget {
  const GajiScreen({super.key, required this.store});

  final RyStore store;

  Future<void> _addRoutine(BuildContext context) async {
    final message = await showRoutineSheet(context, store);
    if (message != null && context.mounted) showToast(context, message);
  }

  Future<void> _editRoutine(BuildContext context, Routine routine) async {
    final message = await showRoutineSheet(context, store, routine: routine);
    if (message != null && context.mounted) showToast(context, message);
  }

  Future<void> _deleteRoutine(BuildContext context, Routine routine) async {
    final sure = await confirmAction(
      context,
      title: 'Hapus "${routine.name}"?',
      body: 'Gaji yang sudah tercatat tidak berubah. Rutinitas ini berhenti dipotong.',
    );
    if (!sure) return;
    store.state.routines.removeWhere((r) => r.id == routine.id);
    await store.save();
    if (context.mounted) showToast(context, 'Rutinitas dihapus.');
  }

  Future<void> _deleteIncome(BuildContext context, Income income) async {
    final sure = await confirmAction(
      context,
      title: 'Hapus catatan gaji?',
      body:
          'Gaji ${fmtRp(income.amount)} beserta penyisihan dan tabungan otomatis yang dibuatnya ikut hilang.',
    );
    if (!sure) return;
    store.state.incomes.removeWhere((item) => item.id == income.id);
    for (final goal in store.state.goals) {
      goal.deposits.removeWhere((deposit) => deposit.incomeId == income.id);
    }
    await store.save();
    if (context.mounted) showToast(context, 'Catatan gaji dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final state = store.state;
    final month = state.month;
    final active = state.routines.where((r) => r.active).toList();
    final planned = active.fold<double>(0, (sum, r) => sum + r.monthly);
    final incomes = state.incomes
        .where((income) => inMonth(income.date, month))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final monthIncome =
        incomes.fold<double>(0, (sum, income) => sum + income.amount);

    return SingleChildScrollView(
      key: const PageStorageKey<String>('gaji'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Eyebrow('Pemasukan'),
          const SizedBox(height: 8),
          Text(
            'Gaji & penyisihan',
            style: T.display(34, height: 1.0, letter: -0.04),
          ),
          const SizedBox(height: 9),
          Text(
            'Catat gaji yang masuk. Penyisihan rutin dan tabungan bisa dipotong otomatis — kamu yang menentukan mana yang ikut.',
            style: T.body(14, color: R.muted, height: 1.6),
          ),
          const SizedBox(height: 18),
          _SalaryForm(store: store),
          SectionHead(
            title: 'Rutinitas',
            action: '+ Tambah',
            onAction: () => _addRoutine(context),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Text(
              state.routines.isEmpty
                  ? 'Kos, transport, listrik — apa pun yang berulang.'
                  : 'Total ${fmtRp(planned)} per bulan'
                      '${active.isEmpty ? ' · semua dimatikan' : ' · ${active.length} aktif'}.\n'
                      'Hitungan: harian ×30,4 · mingguan ×4,3 · custom = nominal × 30,4 ÷ N hari.',
              style: T.body(11.5, color: R.muted, height: 1.5),
            ),
          ),
          if (state.routines.isEmpty)
            const EmptyBlock(
              title: 'Belum ada rutinitas.',
              body:
                  'Tambahkan pengeluaran yang datang terus tiap periode. Nominalnya dipotong dari gaji saat kamu mencatat gaji.',
            )
          else
            for (final routine in state.routines)
              _RoutineRow(
                routine: routine,
                onToggle: (value) {
                  routine.active = value;
                  applyPendingSalaryDeductions(store.state);
                  store.changed();
                },
                onEdit: () => _editRoutine(context, routine),
                onDelete: () => _deleteRoutine(context, routine),
              ),
          SectionHead(
            title: 'Gaji bulan ini',
            trailing: fmtRp(monthIncome),
          ),
          const SizedBox(height: 6),
          if (incomes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Belum ada gaji tercatat bulan ini.',
                style: T.body(13, color: R.muted),
              ),
            )
          else
            for (final income in incomes)
              _IncomeRow(
                income: income,
                onDelete: () => _deleteIncome(context, income),
              ),
        ],
      ),
    );
  }
}

/* ---------- formulir gaji ---------- */

class _SalaryForm extends StatefulWidget {
  const _SalaryForm({required this.store});

  final RyStore store;

  @override
  State<_SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends State<_SalaryForm> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _label = TextEditingController();
  String _date = todayISO();
  bool _cutRoutine = true;
  bool _saveGoals = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _label.dispose();
    super.dispose();
  }

  double _routineCut(List<Routine> routines) {
    if (!_cutRoutine) return 0;
    return routines.fold<double>(
      0,
      (sum, routine) => sum + routine.monthly.roundToDouble(),
    );
  }

  double _goalCut(List<Goal> goals) {
    if (!_saveGoals) return 0;
    return goals.fold<double>(
      0,
      (sum, goal) => sum + goal.monthlyPlan.roundToDouble(),
    );
  }

  Future<void> _save(List<Routine> routines, List<Goal> goals) async {
    final amount = parseRp(_amount.text);
    if (amount <= 0) {
      setState(() => _error = 'Isi nominal gaji dulu.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });

    final incomeId = newId();
    final plan = planDeductions(
      routines: routines,
      goals: goals,
      cutRoutines: _cutRoutine,
      saveToGoals: _saveGoals,
    );
    for (final goal in goals) {
      final value = plan.goalAmounts[goal.id];
      if (value == null) continue;
      goal.deposits.add(
        Deposit(
          id: newId(),
          date: _date,
          amount: value,
          incomeId: incomeId,
        ),
      );
    }

    final totalCut = plan.total;
    final label = _label.text.trim();
    widget.store.state.incomes.add(
      Income(
        id: incomeId,
        date: _date,
        label: label.isEmpty ? 'Gaji' : label,
        amount: amount,
        allocations: plan.allocations,
        cutRoutine: _cutRoutine,
        saveGoals: _saveGoals,
      ),
    );
    widget.store.state.month = monthOf(_date);

    final ok = await widget.store.save();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Gagal menyimpan. Penyimpanan HP penuh?';
      });
      return;
    }
    _amount.clear();
    _label.clear();
    setState(() => _busy = false);
    showToast(
      context,
      totalCut > 0
          ? 'Gaji dicatat. ${fmtRp(totalCut)} disisihkan.'
          : 'Gaji dicatat.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.store.state;
    final routines = state.routines.where((r) => r.active).toList();
    final goals = state.goals
        .where((g) => g.autoDeduct && !g.done && g.planAmount > 0)
        .toList();
    final amount = parseRp(_amount.text);
    final routineCut = _routineCut(routines);
    final goalCut = _goalCut(goals);
    final totalCut = routineCut + goalCut;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: R.ink2,
        border: Border.all(color: R.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RyField(
            label: 'Nominal gaji',
            child: RyInput(
              controller: _amount,
              prefix: 'Rp ',
              hint: '0',
              keyboardType: TextInputType.number,
              formatters: const <TextInputFormatter>[RupiahInputFormatter()],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 14),
          RyField(
            label: 'Tanggal masuk',
            child: RyDateField(
              value: _date,
              onChanged: (value) => setState(() => _date = value),
            ),
          ),
          const SizedBox(height: 14),
          RyField(
            label: 'Keterangan',
            child: RyInput(
              controller: _label,
              hint: 'Gaji ${monthLabel(state.month)}',
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: 14),
          ToggleRow(
            title: 'Potong penyisihan',
            subtitle: routines.isEmpty
                ? 'Belum ada rutinitas aktif.'
                : '${routines.length} rutinitas · ${fmtRp(routineCut)} per bulan',
            value: _cutRoutine && routines.isNotEmpty,
            onChanged: routines.isEmpty
                ? null
                : (value) => setState(() => _cutRoutine = value),
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 9),
          ToggleRow(
            title: 'Sisihkan tabungan',
            subtitle: goals.isEmpty
                ? 'Belum ada target dengan potong otomatis.'
                : '${goals.length} target · ${fmtRp(goalCut)} per bulan',
            value: _saveGoals && goals.isNotEmpty,
            onChanged: goals.isEmpty
                ? null
                : (value) => setState(() => _saveGoals = value),
            icon: Icons.savings_outlined,
          ),
          if (routines.isNotEmpty || goals.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: R.ink,
                border: Border.all(color: R.line),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                children: <Widget>[
                  LedgerRow('Gaji', fmtRp(amount)),
                  if (_cutRoutine)
                    for (final routine in routines)
                      LedgerRow(
                        routine.name,
                        '−${fmtRp(routine.monthly.roundToDouble())}',
                        sub: true,
                      ),
                  if (_saveGoals)
                    for (final goal in goals)
                      LedgerRow(
                        goal.name,
                        '−${fmtRp(goal.monthlyPlan.roundToDouble())}',
                        sub: true,
                      ),
                  LedgerRow(
                    'Sisa setelah potongan',
                    fmtRp(amount - totalCut),
                    total: true,
                    negative: amount - totalCut < 0,
                  ),
                ],
              ),
            ),
            if (amount > 0 && totalCut > amount)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Potongan lebih besar dari gaji. Kecilkan nominal, atau matikan salah satu potongan.',
                  style: T.body(12, color: R.rust, height: 1.45),
                ),
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: T.body(12.5, color: R.rust, height: 1.45),
              ),
            ),
          const SizedBox(height: 14),
          RyButton(
            label: 'Simpan gaji',
            block: true,
            busy: _busy,
            onTap: _busy ? null : () => _save(routines, goals),
          ),
          if (routines.isNotEmpty || goals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                'Dua tombol di atas bisa dimatikan kapan saja. Tabungan otomatis juga bisa diatur per target.',
                style: T.body(11, color: R.muted, height: 1.45),
              ),
            ),
        ],
      ),
    );
  }
}

/* ---------- baris ---------- */

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.routine,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Routine routine;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: routine.active ? 1 : 0.55,
      child: Container(
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
                    routine.name,
                    style: T.body(14.5, weight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fmtRp(routine.amount)} ${routine.rhythmLabel} · '
                    '${fmtRp(routine.monthly)}/bln',
                    style: T.body(11.5, color: R.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            RySwitch(
              value: routine.active,
              onChanged: onToggle,
              semanticLabel: routine.name,
            ),
            const SizedBox(width: 2),
            RyIconButton(
              icon: Icons.edit_outlined,
              onTap: onEdit,
              size: 17,
              tooltip: 'Ubah ${routine.name}',
            ),
            RyIconButton(
              icon: Icons.close_rounded,
              onTap: onDelete,
              size: 17,
              tooltip: 'Hapus ${routine.name}',
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.income, required this.onDelete});

  final Income income;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cut = income.allocatedRoutine;
    final saved = income.allocatedSaving;
    final parts = <String>[
      fmtDate(income.date),
      if (cut > 0) 'rutin ${fmtRp(cut)}',
      if (saved > 0) 'tabungan ${fmtRp(saved)}',
    ];
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
                  income.label.isEmpty ? 'Gaji' : income.label,
                  style: T.body(14.5, weight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  parts.join(' · '),
                  style: T.body(11.5, color: R.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(fmtRp(income.amount), style: T.mono(12.5)),
          RyIconButton(
            icon: Icons.close_rounded,
            onTap: onDelete,
            size: 17,
            tooltip: 'Hapus catatan gaji',
          ),
        ],
      ),
    );
  }
}
