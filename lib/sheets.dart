// Semua lembar isian: rutinitas, target, setoran, transaksi, pengaturan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

/* ---------- rutinitas ---------- */

Future<String?> showRoutineSheet(
  BuildContext context,
  RyStore store, {
  Routine? routine,
}) {
  return showRySheet<String>(
    context,
    title: routine == null ? 'Rutinitas baru' : 'Ubah rutinitas',
    subtitle:
        'Nominal sekali bayar. Siklus menentukan berapa kali ia muncul dalam sebulan.',
    body: _RoutineForm(store: store, routine: routine),
  );
}

class _RoutineForm extends StatefulWidget {
  const _RoutineForm({required this.store, this.routine});

  final RyStore store;
  final Routine? routine;

  @override
  State<_RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<_RoutineForm> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _days;
  late String _cycle;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    _name = TextEditingController(text: routine?.name ?? '');
    _amount = TextEditingController(
      text: (routine?.amount ?? 0) > 0 ? fmtNum(routine!.amount) : '',
    );
    _cycle = routine?.cycle ?? 'bulanan';
    if (!kCycleChoices.contains(_cycle)) _cycle = 'bulanan';
    _days = TextEditingController(
      text: '${(routine?.customDays ?? 0) > 0 ? routine!.customDays : 10}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _days.dispose();
    super.dispose();
  }

  double get _monthly {
    final amount = parseRp(_amount.text);
    final days = int.tryParse(_days.text) ?? 0;
    if (_cycle == 'custom' && days < 1) return 0;
    return amount * kDaysPerMonth / cycleDays(_cycle, days);
  }

  String get _preview {
    if (_cycle == 'custom' && (int.tryParse(_days.text) ?? 0) < 1) {
      return 'Isi jumlah hari dulu untuk melihat hitungan per bulan.';
    }
    final amount = parseRp(_amount.text);
    if (amount <= 0) return 'Isi nominal untuk melihat hitungan per bulan.';
    final days = int.tryParse(_days.text) ?? 0;
    return '≈ ${fmtRp(_monthly)} per bulan · ${cycleLabel(_cycle, days)}';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = parseRp(_amount.text);
    final days = int.tryParse(_days.text) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Nama rutinitas belum diisi.');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'Nominal harus lebih dari nol.');
      return;
    }
    if (_cycle == 'custom' && days < 1) {
      setState(() => _error = 'Jumlah hari harus minimal 1.');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    final customDays = _cycle == 'custom' ? days : 0;
    final existing = widget.routine;
    if (existing != null) {
      existing
        ..name = name
        ..amount = amount
        ..cycle = _cycle
        ..customDays = customDays;
    } else {
      widget.store.state.routines.add(
        Routine(
          id: newId(),
          name: name,
          amount: amount,
          cycle: _cycle,
          customDays: customDays,
        ),
      );
    }

    final ok = await widget.store.save();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Gagal menyimpan. Penyimpanan HP penuh?';
      });
      return;
    }
    Navigator.of(context).pop(
      existing == null ? 'Rutinitas ditambahkan.' : 'Rutinitas diperbarui.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RyField(
          label: 'Nama',
          child: RyInput(
            controller: _name,
            hint: 'Kos, bensin, listrik…',
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Nominal sekali bayar',
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
          label: 'Siklus',
          hint: 'Satu bulan dihitung 30,4 hari.',
          child: RySegmented<String>(
            options: const <SegmentOption<String>>[
              SegmentOption<String>('harian', 'Harian'),
              SegmentOption<String>('mingguan', 'Mingguan'),
              SegmentOption<String>('bulanan', 'Bulanan'),
              SegmentOption<String>('custom', 'Custom'),
            ],
            value: _cycle,
            onChanged: (value) => setState(() => _cycle = value),
          ),
        ),
        if (_cycle == 'custom') ...<Widget>[
          const SizedBox(height: 14),
          RyField(
            label: 'Tiap berapa hari',
            hint: 'Contoh: 2, 10, 15 — bebas.',
            child: RyInput(
              controller: _days,
              hint: '10',
              keyboardType: TextInputType.number,
              formatters: const <TextInputFormatter>[DigitsInputFormatter()],
              maxLength: 3,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
        const SizedBox(height: 14),
        InfoLine(_preview),
        FormMessage(_error),
        const SizedBox(height: 14),
        SheetButtons(
          submitLabel: 'Simpan',
          onSubmit: _busy ? null : _save,
          busy: _busy,
        ),
      ],
    );
  }
}

/* ---------- target tabungan ---------- */

Future<String?> showGoalSheet(
  BuildContext context,
  RyStore store, {
  Goal? goal,
}) {
  return showRySheet<String>(
    context,
    title: goal == null ? 'Target baru' : 'Ubah target',
    subtitle:
        'Ritme menabung menentukan perkiraan waktu. Bisa dipotong otomatis dari gaji.',
    body: _GoalForm(store: store, goal: goal),
  );
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({required this.store, this.goal});

  final RyStore store;
  final Goal? goal;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _plan;
  late final TextEditingController _days;
  late String _period;
  late bool _autoDeduct;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = TextEditingController(text: goal?.name ?? '');
    _target = TextEditingController(
      text: (goal?.target ?? 0) > 0 ? fmtNum(goal!.target) : '',
    );
    _plan = TextEditingController(
      text: (goal?.planAmount ?? 0) > 0 ? fmtNum(goal!.planAmount) : '',
    );
    _period = goal?.planPeriod ?? 'mingguan';
    if (!kCycleChoices.contains(_period)) _period = 'mingguan';
    _days = TextEditingController(
      text: '${(goal?.customDays ?? 0) > 0 ? goal!.customDays : 10}',
    );
    _autoDeduct = goal?.autoDeduct ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _plan.dispose();
    _days.dispose();
    super.dispose();
  }

  double get _periodDays {
    final days = int.tryParse(_days.text) ?? 0;
    return cycleDays(_period, days);
  }

  double get _monthlyPlan => parseRp(_plan.text) * kDaysPerMonth / _periodDays;

  String get _preview {
    final plan = parseRp(_plan.text);
    final target = parseRp(_target.text);
    if (_period == 'custom' && (int.tryParse(_days.text) ?? 0) < 1) {
      return 'Isi jumlah hari dulu.';
    }
    if (plan <= 0) return 'Isi nominal nabung untuk melihat perkiraan waktu.';
    final saved = widget.goal?.saved ?? 0;
    final remaining = target > saved ? target - saved : 0;
    final perDay = plan / _periodDays;
    final daysLeft = perDay > 0 ? remaining / perDay : null;
    final parts = <String>[
      '≈ ${fmtRp(_monthlyPlan)} per bulan',
      if (target > 0) etaLabel(daysLeft),
    ];
    return parts.join(' · ');
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = parseRp(_target.text);
    final plan = parseRp(_plan.text);
    final days = int.tryParse(_days.text) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Nama target belum diisi.');
      return;
    }
    if (target <= 0) {
      setState(() => _error = 'Harga target harus lebih dari nol.');
      return;
    }
    if (plan <= 0) {
      setState(() => _error = 'Nominal nabung harus lebih dari nol.');
      return;
    }
    if (_period == 'custom' && days < 1) {
      setState(() => _error = 'Jumlah hari harus minimal 1.');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    final customDays = _period == 'custom' ? days : 0;
    final existing = widget.goal;
    if (existing != null) {
      existing
        ..name = name
        ..target = target
        ..planAmount = plan
        ..planPeriod = _period
        ..customDays = customDays
        ..autoDeduct = _autoDeduct;
    } else {
      widget.store.state.goals.add(
        Goal(
          id: newId(),
          name: name,
          target: target,
          planAmount: plan,
          planPeriod: _period,
          customDays: customDays,
          autoDeduct: _autoDeduct,
        ),
      );
    }

    final ok = await widget.store.save();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Gagal menyimpan. Penyimpanan HP penuh?';
      });
      return;
    }
    Navigator.of(context).pop(
      existing == null ? 'Target dibuat.' : 'Target diperbarui.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RyField(
          label: 'Barang atau tujuan',
          child: RyInput(
            controller: _name,
            hint: 'Sepatu, laptop, dana darurat…',
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Harga / target',
          child: RyInput(
            controller: _target,
            prefix: 'Rp ',
            hint: '0',
            keyboardType: TextInputType.number,
            formatters: const <TextInputFormatter>[RupiahInputFormatter()],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Nabung',
          child: RyInput(
            controller: _plan,
            prefix: 'Rp ',
            hint: '0',
            keyboardType: TextInputType.number,
            formatters: const <TextInputFormatter>[RupiahInputFormatter()],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Ritme',
          hint: 'Custom bisa 2, 10, 15 hari — sesukamu.',
          child: RySegmented<String>(
            options: const <SegmentOption<String>>[
              SegmentOption<String>('harian', 'Harian'),
              SegmentOption<String>('mingguan', 'Mingguan'),
              SegmentOption<String>('bulanan', 'Bulanan'),
              SegmentOption<String>('custom', 'Custom'),
            ],
            value: _period,
            onChanged: (value) => setState(() => _period = value),
          ),
        ),
        if (_period == 'custom') ...<Widget>[
          const SizedBox(height: 14),
          RyField(
            label: 'Tiap berapa hari',
            child: RyInput(
              controller: _days,
              hint: '10',
              keyboardType: TextInputType.number,
              formatters: const <TextInputFormatter>[DigitsInputFormatter()],
              maxLength: 3,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
        const SizedBox(height: 14),
        InfoLine(_preview),
        const SizedBox(height: 12),
        ToggleRow(
          title: 'Potong otomatis dari gaji',
          subtitle: 'Saat gaji dicatat, ${fmtRp(_monthlyPlan)} disisihkan untuk target ini.',
          value: _autoDeduct,
          onChanged: (value) => setState(() => _autoDeduct = value),
          icon: Icons.savings_outlined,
        ),
        FormMessage(_error),
        const SizedBox(height: 14),
        SheetButtons(
          submitLabel: 'Simpan',
          onSubmit: _busy ? null : _save,
          busy: _busy,
        ),
      ],
    );
  }
}

/* ---------- setoran ---------- */

Future<String?> showDepositSheet(
  BuildContext context,
  RyStore store,
  Goal goal,
) {
  return showRySheet<String>(
    context,
    title: 'Setor — ${goal.name}',
    subtitle:
        'Sisa ${fmtRp(goal.remaining)} dari target ${fmtRp(goal.target)}.',
    body: _DepositForm(store: store, goal: goal),
  );
}

class _DepositForm extends StatefulWidget {
  const _DepositForm({required this.store, required this.goal});

  final RyStore store;
  final Goal goal;

  @override
  State<_DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends State<_DepositForm> {
  late final TextEditingController _amount;
  late String _date;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.goal.planAmount > 0 ? fmtNum(widget.goal.planAmount) : '',
    );
    _date = todayISO();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _fill(double value) {
    _amount.text = fmtNum(value);
    setState(() {});
  }

  Future<void> _save() async {
    final amount = parseRp(_amount.text);
    if (amount <= 0) {
      setState(() => _error = 'Nominal setoran belum diisi.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    widget.goal.deposits.add(
      Deposit(id: newId(), date: _date, amount: amount),
    );
    final ok = await widget.store.save();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Gagal menyimpan. Penyimpanan HP penuh?';
      });
      return;
    }
    final message = widget.goal.done
        ? 'Target "${widget.goal.name}" tercapai.'
        : 'Disetor ${fmtRp(amount)}. Sisa ${fmtRp(widget.goal.remaining)}.';
    Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final quick = <Widget>[
      if (goal.planAmount > 0)
        MoneyChip(
          label: 'Sesuai rencana',
          onTap: () => _fill(goal.planAmount),
        ),
      if (goal.planAmount > 0)
        MoneyChip(label: '2× rencana', onTap: () => _fill(goal.planAmount * 2)),
      if (goal.remaining > 0)
        MoneyChip(label: 'Sisa target', onTap: () => _fill(goal.remaining)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RyField(
          label: 'Nominal setoran',
          child: RyInput(
            controller: _amount,
            prefix: 'Rp ',
            hint: '0',
            autofocus: true,
            keyboardType: TextInputType.number,
            formatters: const <TextInputFormatter>[RupiahInputFormatter()],
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (quick.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: quick),
        ],
        const SizedBox(height: 14),
        RyField(
          label: 'Tanggal',
          child: RyDateField(
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
        ),
        FormMessage(_error),
        const SizedBox(height: 14),
        SheetButtons(
          submitLabel: 'Setor',
          onSubmit: _busy ? null : _save,
          busy: _busy,
        ),
      ],
    );
  }
}

/* ---------- transaksi ---------- */

Future<String?> showTxnSheet(BuildContext context, RyStore store) {
  return showRySheet<String>(
    context,
    title: 'Catat transaksi',
    subtitle: 'Pengeluaran atau pemasukan di luar gaji.',
    body: _TxnForm(store: store),
  );
}

class _TxnForm extends StatefulWidget {
  const _TxnForm({required this.store});

  final RyStore store;

  @override
  State<_TxnForm> createState() => _TxnFormState();
}

class _TxnFormState extends State<_TxnForm> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _type = 'keluar';
  String _category = kCategories.first;
  String _date = todayISO();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseRp(_amount.text);
    if (amount <= 0) {
      setState(() => _error = 'Nominal belum diisi.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    widget.store.state.txns.add(
      Txn(
        id: newId(),
        date: _date,
        type: _type,
        category: _category,
        note: _note.text.trim(),
        amount: amount,
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
    Navigator.of(context).pop(
      '${_type == 'masuk' ? 'Pemasukan' : 'Pengeluaran'} ${fmtRp(amount)} dicatat.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RySegmented<String>(
          options: const <SegmentOption<String>>[
            SegmentOption<String>('keluar', 'Keluar'),
            SegmentOption<String>('masuk', 'Masuk'),
          ],
          value: _type,
          onChanged: (value) => setState(() => _type = value),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Nominal',
          child: RyInput(
            controller: _amount,
            prefix: 'Rp ',
            hint: '0',
            autofocus: true,
            keyboardType: TextInputType.number,
            formatters: const <TextInputFormatter>[RupiahInputFormatter()],
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Kategori',
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              for (final category in kCategories)
                _CategoryChip(
                  label: category,
                  selected: category == _category,
                  onTap: () => setState(() => _category = category),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Tanggal',
          child: RyDateField(
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
        ),
        const SizedBox(height: 14),
        RyField(
          label: 'Catatan',
          child: RyInput(
            controller: _note,
            hint: 'mis. nasi padang, bensin',
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        FormMessage(_error),
        const SizedBox(height: 14),
        SheetButtons(
          submitLabel: 'Simpan',
          onSubmit: _busy ? null : _save,
          busy: _busy,
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? R.acid : R.ink3,
          border: Border.all(color: selected ? R.acid : R.line),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: T.body(
            12.5,
            color: selected ? R.acidInk : R.paperDim,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/* ---------- pengaturan & cadangan ---------- */

Future<String?> showSettingsSheet(BuildContext context, RyStore store) {
  return showRySheet<String>(
    context,
    title: 'Pengaturan',
    subtitle: 'Data tinggal di HP ini. Tidak ada akun, tidak ada server.',
    body: _SettingsBody(store: store),
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.store});

  final RyStore store;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (!context.mounted) return;
    showToast(context, 'Cadangan disalin ke papan klip.');
  }

  void _view(BuildContext context) {
    final json = store.exportJson();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: R.ink2,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: const BorderSide(color: R.line2),
          ),
          title: Text('Cadangan', style: T.display(22)),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style: T.mono(10, color: R.paperDim, height: 1.5),
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: <Widget>[
            RyButton(
              label: 'Tutup',
              kind: RyButtonKind.ghost,
              small: true,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
            RyButton(
              label: 'Salin',
              small: true,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!dialogContext.mounted) return;
                showToast(dialogContext, 'Cadangan disalin.');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _restore(BuildContext context) async {
    final message = await _showRestoreDialog(context, store);
    if (message != null && context.mounted) {
      Navigator.of(context).pop(message);
    }
  }

  Future<void> _reset(BuildContext context) async {
    final sure = await confirmAction(
      context,
      title: 'Hapus semua data?',
      body:
          'Gaji, rutinitas, target, dan catatan akan hilang dari HP ini. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Hapus',
    );
    if (!sure || !context.mounted) return;
    store.state = AppState.fresh();
    await store.save();
    if (!context.mounted) return;
    Navigator.of(context).pop('Semua data dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const InfoLine(
          'Cadangan berguna sebelum ganti HP atau membersihkan data aplikasi.',
        ),
        const SizedBox(height: 16),
        RyButton(
          label: 'Salin cadangan (JSON)',
          icon: Icons.copy_rounded,
          kind: RyButtonKind.ghost,
          block: true,
          onTap: () => _copy(context),
        ),
        const SizedBox(height: 9),
        RyButton(
          label: 'Lihat cadangan',
          icon: Icons.description_outlined,
          kind: RyButtonKind.ghost,
          block: true,
          onTap: () => _view(context),
        ),
        const SizedBox(height: 9),
        RyButton(
          label: 'Pulihkan dari cadangan',
          icon: Icons.download_rounded,
          kind: RyButtonKind.ghost,
          block: true,
          onTap: () => _restore(context),
        ),
        const SizedBox(height: 22),
        const Divider(color: R.line, height: 1),
        const SizedBox(height: 22),
        RyButton(
          label: 'Hapus semua data',
          icon: Icons.delete_outline_rounded,
          kind: RyButtonKind.danger,
          block: true,
          onTap: () => _reset(context),
        ),
        const SizedBox(height: 18),
        Text(
          'Ry-Money · data lokal, tanpa iklan, tanpa internet.',
          style: T.mono(10, color: R.muted, letter: 0.4),
        ),
      ],
    );
  }
}

Future<String?> _showRestoreDialog(BuildContext context, RyStore store) {
  final controller = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setLocal) {
          return AlertDialog(
            backgroundColor: R.ink2,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
              side: const BorderSide(color: R.line2),
            ),
            title: Text('Pulihkan data', style: T.display(22)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Tempel isi berkas cadangan Ry-Money di bawah.',
                    style: T.body(13, color: R.muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: T.mono(10.5, height: 1.5),
                      cursorColor: R.acid,
                      decoration: InputDecoration(
                        hintText: '{"version":2, …}',
                        hintStyle: T.mono(10.5, color: R.muted),
                        filled: true,
                        fillColor: R.ink3,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: const BorderSide(color: R.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: const BorderSide(color: R.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: const BorderSide(color: R.acid),
                        ),
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error!,
                        style: T.body(12, color: R.rust, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            actions: <Widget>[
              RyButton(
                label: 'Tempel',
                kind: RyButtonKind.ghost,
                small: true,
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  final text = data?.text;
                  if (text != null && text.isNotEmpty) {
                    controller.text = text;
                    setLocal(() => error = null);
                  }
                },
              ),
              RyButton(
                label: 'Pulihkan',
                small: true,
                onTap: () {
                  final problem = store.restore(controller.text);
                  if (problem != null) {
                    setLocal(() => error = problem);
                    return;
                  }
                  Navigator.of(dialogContext).pop('Data dipulihkan.');
                },
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
