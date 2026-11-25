import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rymoney/theme.dart';
import 'package:rymoney/widgets.dart';

void main() {
  testWidgets('baris buku kas menampilkan label dan nilai', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ryTheme(),
        home: const Scaffold(
          body: LedgerRow('Gaji masuk', 'Rp 1.000.000'),
        ),
      ),
    );
    expect(find.text('Gaji masuk'), findsOneWidget);
    expect(find.text('Rp 1.000.000'), findsOneWidget);
  });

  testWidgets('pilihan siklus custom bisa ditekan', (tester) async {
    var picked = 'bulanan';
    await tester.pumpWidget(
      MaterialApp(
        theme: ryTheme(),
        home: Scaffold(
          body: RySegmented<String>(
            options: const <SegmentOption<String>>[
              SegmentOption<String>('harian', 'Harian'),
              SegmentOption<String>('bulanan', 'Bulanan'),
              SegmentOption<String>('custom', 'Custom'),
            ],
            value: picked,
            onChanged: (value) => picked = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(picked, 'custom');
  });

  testWidgets('sakelar mengirim nilai baru', (tester) async {
    bool? value;
    await tester.pumpWidget(
      MaterialApp(
        theme: ryTheme(),
        home: Scaffold(
          body: RySwitch(value: false, onChanged: (next) => value = next),
        ),
      ),
    );
    await tester.tap(find.byType(RySwitch));
    await tester.pumpAndSettle();
    expect(value, true);
  });
}
