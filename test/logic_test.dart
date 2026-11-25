import 'package:flutter_test/flutter_test.dart';
import 'package:rymoney/models.dart';

Goal makeGoal({
  String id = 'g1',
  double target = 1000000,
  double planAmount = 50000,
  String planPeriod = 'custom',
  int customDays = 5,
  bool autoDeduct = false,
  List<Deposit>? deposits,
}) {
  return Goal(
    id: id,
    name: 'Laptop',
    target: target,
    planAmount: planAmount,
    planPeriod: planPeriod,
    customDays: customDays,
    autoDeduct: autoDeduct,
    deposits: deposits,
  );
}

void main() {
  group('siklus fleksibel', () {
    test('nominal per bulan untuk tiap siklus', () {
      final monthly = Routine(
        id: 'r1',
        name: 'Kos',
        amount: 700000,
        cycle: 'bulanan',
      );
      final weekly = Routine(
        id: 'r2',
        name: 'Bensin',
        amount: 70000,
        cycle: 'mingguan',
      );
      final daily = Routine(
        id: 'r3',
        name: 'Parkir',
        amount: 5000,
        cycle: 'harian',
      );
      final custom = Routine(
        id: 'r4',
        name: 'Galon',
        amount: 300000,
        cycle: 'custom',
        customDays: 15,
      );

      expect(monthly.monthly, closeTo(700000, 0.01));
      expect(weekly.monthly, closeTo(304375, 0.01));
      expect(daily.monthly, closeTo(152187.5, 0.01));
      expect(custom.monthly, closeTo(608750, 0.01));
      expect(custom.rhythmLabel, 'per 15 hari');
    });

    test('custom tanpa jumlah hari dianggap satu hari', () {
      expect(cycleDays('custom', 0), 1);
      expect(cycleDays('custom', 10), 10);
      expect(cycleLabel('custom', 10), 'per 10 hari');
    });

    test('rutinitas nonaktif tidak ikut dihitung', () {
      final routines = <Routine>[
        Routine(id: 'a', name: 'Kos', amount: 700000),
        Routine(id: 'b', name: 'Gym', amount: 100000, active: false),
      ];
      expect(plannedMonthly(routines), closeTo(700000, 0.01));
    });
  });

  group('target tabungan', () {
    test('sisa, perkiraan hari, dan status tercapai', () {
      final goal = makeGoal(
        deposits: <Deposit>[
          Deposit(id: 'd1', date: '2026-11-01', amount: 200000),
        ],
      );
      expect(goal.saved, 200000);
      expect(goal.remaining, 800000);
      expect(goal.daysLeft, closeTo(80, 0.01));
      expect(goal.done, false);
      expect(goal.progress, closeTo(0.2, 0.0001));

      goal.deposits.add(
        Deposit(id: 'd2', date: '2026-11-02', amount: 800000),
      );
      expect(goal.done, true);
      expect(goal.progress, 1);
      expect(goal.remaining, 0);
    });

    test('rencana bulanan mengikuti ritme custom', () {
      final goal = makeGoal();
      expect(goal.monthlyPlan, closeTo(304375, 0.01));
    });
  });

  group('potongan gaji fleksibel', () {
    final routines = <Routine>[
      Routine(id: 'r1', name: 'Kos', amount: 700000),
      Routine(id: 'r2', name: 'Bensin', amount: 100000, active: false),
    ];
    final goals = <Goal>[
      makeGoal(id: 'g1', autoDeduct: true),
      makeGoal(id: 'g2', autoDeduct: false),
    ];

    test('hanya rutinitas kalau tabungan dimatikan', () {
      final plan = planDeductions(
        routines: routines,
        goals: goals,
        cutRoutines: true,
        saveToGoals: false,
      );
      expect(plan.allocations, hasLength(1));
      expect(plan.allocations.first.kind, 'rutin');
      expect(plan.allocations.first.amount, 700000);
      expect(plan.goalAmounts, isEmpty);
      expect(plan.total, 700000);
    });

    test('hanya tabungan kalau penyisihan dimatikan', () {
      final plan = planDeductions(
        routines: routines,
        goals: goals,
        cutRoutines: false,
        saveToGoals: true,
      );
      expect(plan.allocations, hasLength(1));
      expect(plan.allocations.first.kind, 'tabungan');
      expect(plan.allocations.first.refId, 'g1');
      expect(plan.allocations.first.amount, 304375);
      expect(plan.goalAmounts['g1'], 304375);
      expect(plan.goalAmounts.containsKey('g2'), false);
    });

    test('dua-duanya, dan bisa dimatikan semua', () {
      final both = planDeductions(
        routines: routines,
        goals: goals,
        cutRoutines: true,
        saveToGoals: true,
      );
      expect(both.allocations, hasLength(2));
      expect(both.total, closeTo(1004375, 0.01));

      final none = planDeductions(
        routines: routines,
        goals: goals,
        cutRoutines: false,
        saveToGoals: false,
      );
      expect(none.isEmpty, true);
      expect(none.total, 0);
    });
  });

  group('ringkasan bulan', () {
    test('sisa = masuk − penyisihan − tabungan − belanja', () {
      final state = AppState(
        month: '2026-11',
        incomes: <Income>[
          Income(
            id: 'i1',
            date: '2026-11-01',
            label: 'Gaji',
            amount: 5000000,
            allocations: <Allocation>[
              Allocation(kind: 'rutin', name: 'Kos', amount: 1000000),
              Allocation(kind: 'tabungan', name: 'Laptop', amount: 500000),
            ],
          ),
          Income(
            id: 'i2',
            date: '2026-12-01',
            label: 'Gaji lain bulan',
            amount: 9000000,
          ),
        ],
        goals: <Goal>[
          makeGoal(
            deposits: <Deposit>[
              Deposit(id: 'd1', date: '2026-11-05', amount: 500000),
            ],
          ),
        ],
        txns: <Txn>[
          Txn(
            id: 't1',
            date: '2026-11-06',
            type: 'keluar',
            category: 'Makan',
            amount: 200000,
          ),
          Txn(
            id: 't2',
            date: '2026-11-07',
            type: 'masuk',
            category: 'Lainnya',
            amount: 50000,
          ),
          Txn(
            id: 't3',
            date: '2026-10-07',
            type: 'keluar',
            category: 'Makan',
            amount: 999999,
          ),
        ],
      );

      final totals = monthTotals(state, '2026-11');
      expect(totals.income, 5000000);
      expect(totals.extra, 50000);
      expect(totals.allocated, 1000000);
      expect(totals.saved, 500000);
      expect(totals.spent, 200000);
      expect(totals.available, 3350000);
      expect(totals.inflow, 5050000);
    });

    test('kategori belanja diurutkan dan mengabaikan pemasukan', () {
      final state = AppState(
        month: '2026-11',
        txns: <Txn>[
          Txn(id: 'a', date: '2026-11-01', type: 'keluar', category: 'Makan', amount: 10000),
          Txn(id: 'b', date: '2026-11-02', type: 'keluar', category: 'Makan', amount: 5000),
          Txn(id: 'c', date: '2026-11-03', type: 'keluar', category: 'Transport', amount: 20000),
          Txn(id: 'd', date: '2026-11-04', type: 'masuk', category: 'Lainnya', amount: 90000),
        ],
      );
      final slices = spendingByCategory(state, '2026-11');
      expect(slices.first.name, 'Transport');
      expect(slices[1].name, 'Makan');
      expect(slices[1].amount, 15000);
      expect(slices, hasLength(2));
    });

    test('kelompok transaksi per hari', () {
      final txn = <Txn>[
        Txn(id: 'a', date: '2026-11-03', type: 'keluar', category: 'Makan', amount: 10000, createdAt: 1),
        Txn(id: 'b', date: '2026-11-03', type: 'masuk', category: 'Lainnya', amount: 25000, createdAt: 2),
        Txn(id: 'c', date: '2026-11-01', type: 'keluar', category: 'Transport', amount: 5000, createdAt: 3),
      ];
      final days = groupTxnsByDay(txn);
      expect(days, hasLength(2));
      expect(days.first.date, '2026-11-03');
      expect(days.first.items.first.id, 'b');
      expect(days.first.net, 15000);
    });
  });

  group('cadangan lama', () {
    test('membaca data versi web (hari/minggu/bulan)', () {
      final state = AppState.fromJson(<String, dynamic>{
        'version': 1,
        'month': '2026-11',
        'incomes': <dynamic>[
          <String, dynamic>{
            'id': 'i1',
            'date': '2026-11-01',
            'amount': 1000000,
            'label': 'Gaji',
            'allocations': <dynamic>[
              <String, dynamic>{
                'routineId': 'r1',
                'name': 'Kos',
                'amount': 500000,
              },
            ],
          },
        ],
        'routines': <dynamic>[
          <String, dynamic>{
            'id': 'r1',
            'name': 'Kos',
            'amount': 500000,
            'cycle': 'mingguan',
            'active': true,
          },
        ],
        'goals': <dynamic>[
          <String, dynamic>{
            'id': 'g1',
            'name': 'Laptop',
            'target': 5000000,
            'planAmount': 100000,
            'planPeriod': 'minggu',
            'deposits': <dynamic>[],
          },
        ],
        'txns': <dynamic>[],
      });

      expect(state.month, '2026-11');
      expect(state.routines.first.cycle, 'mingguan');
      expect(state.goals.first.planPeriod, 'mingguan');
      expect(state.goals.first.autoDeduct, false);
      expect(state.incomes.first.allocations.first.kind, 'rutin');
      expect(state.incomes.first.allocatedRoutine, 500000);
      expect(monthTotals(state, '2026-11').allocated, 500000);
    });

    test('bolak-balik JSON mempertahankan data baru', () {
      final goal = makeGoal(
        autoDeduct: true,
        planPeriod: 'custom',
        customDays: 12,
      );
      final state = AppState(
        month: '2026-11',
        routines: <Routine>[
          Routine(
            id: 'r1',
            name: 'Galon',
            amount: 20000,
            cycle: 'custom',
            customDays: 12,
          ),
        ],
        goals: <Goal>[goal],
      );
      final copy = AppState.fromJson(state.toJson());
      expect(copy.routines.first.cycle, 'custom');
      expect(copy.routines.first.customDays, 12);
      expect(copy.goals.first.autoDeduct, true);
      expect(copy.goals.first.customDays, 12);
      expect(copy.goals.first.planPeriod, 'custom');
    });
  });

  group('potongan menyusul ke gaji terakhir', () {
    test('rutinitas aktif setelah gaji dicatat ikut terpotong', () {
      final state = AppState(
        month: '2026-11',
        incomes: <Income>[
          Income(
            id: 'i1',
            date: '2026-11-05',
            label: 'Gaji',
            amount: 5000000,
          ),
        ],
        routines: <Routine>[Routine(id: 'r1', name: 'Kos', amount: 700000)],
      );

      applyPendingSalaryDeductions(state);

      final income = state.incomes.first;
      expect(income.allocations, hasLength(1));
      expect(income.allocatedRoutine, 700000);
      expect(monthTotals(state, '2026-11').allocated, 700000);

      // dipanggil ulang tidak menggandakan
      applyPendingSalaryDeductions(state);
      expect(income.allocations, hasLength(1));
    });

    test('target tabungan menyusul menambah alokasi dan setoran', () {
      final goal = makeGoal(id: 'g1', autoDeduct: true);
      final state = AppState(
        month: '2026-11',
        incomes: <Income>[
          Income(
            id: 'i1',
            date: '2026-11-05',
            label: 'Gaji',
            amount: 8000000,
          ),
        ],
        goals: <Goal>[goal],
      );

      applyPendingSalaryDeductions(state);

      expect(state.incomes.first.allocatedSaving, 304375);
      expect(goal.deposits, hasLength(1));
      expect(goal.deposits.first.incomeId, 'i1');
      expect(goal.saved, 304375);
    });

    test('sakelar yang dimatikan saat mencatat gaji tidak disentuh', () {
      final state = AppState(
        month: '2026-11',
        incomes: <Income>[
          Income(
            id: 'i1',
            date: '2026-11-05',
            label: 'Gaji',
            amount: 5000000,
            cutRoutine: false,
            saveGoals: false,
          ),
        ],
        routines: <Routine>[Routine(id: 'r1', name: 'Kos', amount: 700000)],
        goals: <Goal>[makeGoal(id: 'g1', autoDeduct: true)],
      );

      applyPendingSalaryDeductions(state);

      expect(state.incomes.first.allocations, isEmpty);
      expect(state.goals.first.deposits, isEmpty);
    });

    test('rutinitas nonaktif dan gaji bulan lain tidak ikut', () {
      final state = AppState(
        month: '2026-11',
        incomes: <Income>[
          Income(
            id: 'i1',
            date: '2026-10-05',
            label: 'Gaji Oktober',
            amount: 5000000,
          ),
        ],
        routines: <Routine>[
          Routine(id: 'r1', name: 'Kos', amount: 700000, active: false),
          Routine(id: 'r2', name: 'Gym', amount: 100000),
        ],
      );

      applyPendingSalaryDeductions(state);

      // hanya gaji bulan ini yang boleh disentuh; Oktober tetap kosong
      expect(state.incomes.first.allocations, isEmpty);
      expect(state.incomes, hasLength(1));
    });
  });
}
