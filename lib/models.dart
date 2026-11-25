// Model data + hitungan. Semua nominal rupiah disimpan sebagai double.

import 'format.dart';

/// Rata-rata panjang satu bulan dalam hari.
const double kDaysPerMonth = 30.4375;

const List<String> kCycleChoices = <String>[
  'harian',
  'mingguan',
  'bulanan',
  'custom',
];

const List<String> kCategories = <String>[
  'Makan',
  'Transport',
  'Kos',
  'Tagihan',
  'Belanja',
  'Hiburan',
  'Kesehatan',
  'Lainnya',
];

double asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String asText(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == 'true' || value == '1';
  return fallback;
}

var _idCounter = 0;

String newId() {
  _idCounter++;
  return 'id-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_idCounter';
}

/// Menyeragamkan nama siklus, termasuk data lama (hari/minggu/bulan).
String normalizeCycle(Object? raw) {
  switch (asText(raw)) {
    case 'hari':
    case 'harian':
      return 'harian';
    case 'minggu':
    case 'mingguan':
      return 'mingguan';
    case 'custom':
      return 'custom';
    default:
      return 'bulanan';
  }
}

double cycleDays(String cycle, int customDays) {
  switch (cycle) {
    case 'harian':
      return 1;
    case 'mingguan':
      return 7;
    case 'custom':
      return customDays > 0 ? customDays.toDouble() : 1;
    default:
      return kDaysPerMonth;
  }
}

String cycleName(String cycle) {
  switch (cycle) {
    case 'harian':
      return 'Harian';
    case 'mingguan':
      return 'Mingguan';
    case 'custom':
      return 'Custom';
    default:
      return 'Bulanan';
  }
}

String cycleLabel(String cycle, int customDays) {
  switch (cycle) {
    case 'harian':
      return 'per hari';
    case 'mingguan':
      return 'per minggu';
    case 'custom':
      return 'per ${customDays > 0 ? customDays : 1} hari';
    default:
      return 'per bulan';
  }
}

class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.amount,
    this.cycle = 'bulanan',
    this.customDays = 0,
    this.active = true,
  });

  final String id;
  String name;
  double amount;
  String cycle;
  int customDays;
  bool active;

  double get periodDays => cycleDays(cycle, customDays);

  /// Perkiraan biaya per bulan.
  double get monthly => amount * kDaysPerMonth / periodDays;

  String get rhythmLabel => cycleLabel(cycle, customDays);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'amount': amount,
        'cycle': cycle,
        'customDays': customDays,
        'active': active,
      };

  factory Routine.fromJson(Map<String, dynamic> json) {
    final cycle = normalizeCycle(json['cycle']);
    return Routine(
      id: asText(json['id'], newId()),
      name: asText(json['name'], 'Rutinitas'),
      amount: asDouble(json['amount']),
      cycle: cycle,
      customDays: cycle == 'custom' ? asInt(json['customDays'], 10) : 0,
      active: asBool(json['active'], true),
    );
  }
}

class Deposit {
  Deposit({
    required this.id,
    required this.date,
    required this.amount,
    this.incomeId,
  });

  final String id;
  String date;
  double amount;

  /// Diisi kalau setoran ini dibuat otomatis saat gaji dicatat.
  String? incomeId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date,
        'amount': amount,
        if (incomeId != null) 'incomeId': incomeId,
      };

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
        id: asText(json['id'], newId()),
        date: asText(json['date'], todayISO()),
        amount: asDouble(json['amount']),
        incomeId: json['incomeId'] == null ? null : asText(json['incomeId']),
      );
}

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.target,
    this.planAmount = 0,
    this.planPeriod = 'bulanan',
    this.customDays = 0,
    this.autoDeduct = false,
    List<Deposit>? deposits,
  }) : deposits = deposits ?? <Deposit>[];

  final String id;
  String name;
  double target;
  double planAmount;
  String planPeriod;
  int customDays;

  /// Ikut dipotong otomatis dari gaji.
  bool autoDeduct;
  final List<Deposit> deposits;

  double get saved => deposits.fold<double>(0, (sum, d) => sum + d.amount);

  double get remaining {
    final left = target - saved;
    return left > 0 ? left : 0;
  }

  double get periodDays => cycleDays(planPeriod, customDays);

  /// Rencana tabungan per bulan (dipakai saat memotong gaji).
  double get monthlyPlan => planAmount * kDaysPerMonth / periodDays;

  double? get daysLeft {
    final perDay = planAmount / periodDays;
    if (perDay <= 0) return null;
    return remaining / perDay;
  }

  bool get done => target > 0 && remaining <= 0.0001;

  double get progress {
    if (target <= 0) return 0;
    return (saved / target).clamp(0.0, 1.0).toDouble();
  }

  String get rhythmLabel => cycleLabel(planPeriod, customDays);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'target': target,
        'planAmount': planAmount,
        'planPeriod': planPeriod,
        'customDays': customDays,
        'autoDeduct': autoDeduct,
        'deposits': deposits.map((d) => d.toJson()).toList(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    final period = normalizeCycle(json['planPeriod']);
    final deposits = <Deposit>[];
    final raw = json['deposits'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          deposits.add(Deposit.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ));
        }
      }
    }
    return Goal(
      id: asText(json['id'], newId()),
      name: asText(json['name'], 'Target'),
      target: asDouble(json['target']),
      planAmount: asDouble(json['planAmount']),
      planPeriod: period,
      customDays: period == 'custom' ? asInt(json['customDays'], 10) : 0,
      autoDeduct: asBool(json['autoDeduct']),
      deposits: deposits,
    );
  }
}

class Allocation {
  Allocation({
    required this.kind,
    required this.name,
    required this.amount,
    this.refId,
  });

  /// 'rutin' untuk penyisihan, 'tabungan' untuk setoran otomatis dari gaji.
  final String kind;
  final String name;
  final double amount;
  final String? refId;

  bool get isSaving => kind == 'tabungan';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind,
        'name': name,
        'amount': amount,
        if (refId != null) 'refId': refId,
      };

  factory Allocation.fromJson(Map<String, dynamic> json) {
    final goalId = json['goalId'];
    final routineId = json['routineId'];
    final kind = json['kind'] == null
        ? (goalId != null ? 'tabungan' : 'rutin')
        : asText(json['kind']);
    return Allocation(
      kind: kind,
      name: asText(json['name'], 'Penyisihan'),
      amount: asDouble(json['amount']),
      refId: json['refId'] != null
          ? asText(json['refId'])
          : (goalId != null
              ? asText(goalId)
              : (routineId != null ? asText(routineId) : null)),
    );
  }
}

class Income {
  Income({
    required this.id,
    required this.date,
    required this.label,
    required this.amount,
    List<Allocation>? allocations,
    int? createdAt,
  })  : allocations = allocations ?? <Allocation>[],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String date;
  String label;
  double amount;
  final List<Allocation> allocations;
  final int createdAt;

  double get allocatedRoutine => allocations
      .where((a) => !a.isSaving)
      .fold<double>(0, (sum, a) => sum + a.amount);

  double get allocatedSaving =>
      allocations.where((a) => a.isSaving).fold<double>(0, (sum, a) => sum + a.amount);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date,
        'label': label,
        'amount': amount,
        'allocations': allocations.map((a) => a.toJson()).toList(),
        'createdAt': createdAt,
      };

  factory Income.fromJson(Map<String, dynamic> json) {
    final allocations = <Allocation>[];
    final raw = json['allocations'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          allocations.add(Allocation.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ));
        }
      }
    }
    return Income(
      id: asText(json['id'], newId()),
      date: asText(json['date'], todayISO()),
      label: asText(json['label'], 'Gaji'),
      amount: asDouble(json['amount']),
      allocations: allocations,
      createdAt: asInt(json['createdAt'], DateTime.now().millisecondsSinceEpoch),
    );
  }
}

class Txn {
  Txn({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    this.note = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String date;

  /// 'keluar' atau 'masuk'.
  String type;
  String category;
  double amount;
  String note;
  final int createdAt;

  bool get isIncome => type == 'masuk';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date,
        'type': type,
        'category': category,
        'note': note,
        'amount': amount,
        'createdAt': createdAt,
      };

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
        id: asText(json['id'], newId()),
        date: asText(json['date'], todayISO()),
        type: asText(json['type'], 'keluar') == 'masuk' ? 'masuk' : 'keluar',
        category: asText(json['category'], 'Lainnya'),
        note: asText(json['note']),
        amount: asDouble(json['amount']),
        createdAt: asInt(json['createdAt'], DateTime.now().millisecondsSinceEpoch),
      );
}

class AppState {
  AppState({
    this.version = 2,
    String? month,
    List<Income>? incomes,
    List<Routine>? routines,
    List<Goal>? goals,
    List<Txn>? txns,
  })  : month = month ?? currentMonthKey(),
        incomes = incomes ?? <Income>[],
        routines = routines ?? <Routine>[],
        goals = goals ?? <Goal>[],
        txns = txns ?? <Txn>[];

  int version;
  String month;
  final List<Income> incomes;
  final List<Routine> routines;
  final List<Goal> goals;
  final List<Txn> txns;

  factory AppState.fresh() => AppState();

  factory AppState.fromJson(Map<String, dynamic> json) {
    final rawMonth = asText(json['month']);
    final month = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(rawMonth)
        ? rawMonth
        : currentMonthKey();

    List<Map<String, dynamic>> maps(Object? raw) {
      if (raw is! List) return const <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    return AppState(
      version: asInt(json['version'], 1),
      month: month,
      incomes: maps(json['incomes']).map(Income.fromJson).toList(),
      routines: maps(json['routines']).map(Routine.fromJson).toList(),
      goals: maps(json['goals']).map(Goal.fromJson).toList(),
      txns: maps(json['txns']).map(Txn.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 2,
        'month': month,
        'incomes': incomes.map((i) => i.toJson()).toList(),
        'routines': routines.map((r) => r.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'txns': txns.map((t) => t.toJson()).toList(),
      };

  bool get hasData =>
      incomes.isNotEmpty ||
      routines.isNotEmpty ||
      goals.isNotEmpty ||
      txns.isNotEmpty;
}

bool inMonth(String iso, String month) =>
    iso.length >= 7 && iso.substring(0, 7) == month;

class SalaryDeductions {
  SalaryDeductions({required this.allocations, required this.goalAmounts});

  final List<Allocation> allocations;

  /// goalId -> nominal yang disisihkan ke target itu.
  final Map<String, double> goalAmounts;

  double get total =>
      allocations.fold<double>(0, (sum, allocation) => sum + allocation.amount);

  bool get isEmpty => allocations.isEmpty;
}

/// Menentukan potongan saat gaji dicatat. Dua sakelar terpisah: rutinitas dan tabungan.
SalaryDeductions planDeductions({
  required List<Routine> routines,
  required List<Goal> goals,
  required bool cutRoutines,
  required bool saveToGoals,
}) {
  final allocations = <Allocation>[];
  final goalAmounts = <String, double>{};

  if (cutRoutines) {
    for (final routine in routines) {
      if (!routine.active) continue;
      final value = routine.monthly.roundToDouble();
      if (value <= 0) continue;
      allocations.add(
        Allocation(
          kind: 'rutin',
          name: routine.name,
          amount: value,
          refId: routine.id,
        ),
      );
    }
  }

  if (saveToGoals) {
    for (final goal in goals) {
      if (!goal.autoDeduct || goal.done || goal.planAmount <= 0) continue;
      final value = goal.monthlyPlan.roundToDouble();
      if (value <= 0) continue;
      allocations.add(
        Allocation(
          kind: 'tabungan',
          name: goal.name,
          amount: value,
          refId: goal.id,
        ),
      );
      goalAmounts[goal.id] = value;
    }
  }

  return SalaryDeductions(allocations: allocations, goalAmounts: goalAmounts);
}

class MonthTotals {
  const MonthTotals({
    required this.income,
    required this.extra,
    required this.allocated,
    required this.saved,
    required this.spent,
  });

  final double income;
  final double extra;
  final double allocated;
  final double saved;
  final double spent;

  double get inflow => income + extra;

  double get available => income + extra - allocated - saved - spent;
}

MonthTotals monthTotals(AppState state, String month) {
  var income = 0.0;
  var allocated = 0.0;
  for (final item in state.incomes) {
    if (!inMonth(item.date, month)) continue;
    income += item.amount;
    allocated += item.allocatedRoutine;
  }

  var saved = 0.0;
  for (final goal in state.goals) {
    for (final deposit in goal.deposits) {
      if (inMonth(deposit.date, month)) saved += deposit.amount;
    }
  }

  var spent = 0.0;
  var extra = 0.0;
  for (final txn in state.txns) {
    if (!inMonth(txn.date, month)) continue;
    if (txn.isIncome) {
      extra += txn.amount;
    } else {
      spent += txn.amount;
    }
  }

  return MonthTotals(
    income: income,
    extra: extra,
    allocated: allocated,
    saved: saved,
    spent: spent,
  );
}

/// Total penyisihan rutin aktif per bulan.
double plannedMonthly(List<Routine> routines) => routines
    .where((r) => r.active)
    .fold<double>(0, (sum, r) => sum + r.monthly);

/// Total rencana tabungan yang dicentang "potong dari gaji" per bulan.
double plannedSavings(List<Goal> goals) => goals
    .where((g) => g.autoDeduct && !g.done && g.planAmount > 0)
    .fold<double>(0, (sum, g) => sum + g.monthlyPlan);

class CategorySlice {
  CategorySlice(this.name, this.amount);

  final String name;
  final double amount;
}

List<CategorySlice> spendingByCategory(AppState state, String month) {
  final map = <String, double>{};
  for (final txn in state.txns) {
    if (txn.isIncome || !inMonth(txn.date, month)) continue;
    final key = txn.category.isEmpty ? 'Lainnya' : txn.category;
    map[key] = (map[key] ?? 0) + txn.amount;
  }
  final list = map.entries
      .map((e) => CategorySlice(e.key, e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return list;
}

class TxnDay {
  TxnDay({required this.date, required this.items, required this.net});

  final String date;
  final List<Txn> items;
  final double net;
}

List<TxnDay> groupTxnsByDay(List<Txn> txns) {
  final map = <String, List<Txn>>{};
  for (final txn in txns) {
    map.putIfAbsent(txn.date, () => <Txn>[]).add(txn);
  }
  final days = map.entries.map((entry) {
    final items = List<Txn>.from(entry.value)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final net = items.fold<double>(
      0,
      (sum, txn) => sum + (txn.isIncome ? txn.amount : -txn.amount),
    );
    return TxnDay(date: entry.key, items: items, net: net);
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return days;
}
