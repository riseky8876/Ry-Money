import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rymoney/format.dart';

void main() {
  group('rupiah', () {
    test('memformat ribuan dengan titik', () {
      expect(fmtRp(0), 'Rp 0');
      expect(fmtRp(1250000), 'Rp 1.250.000');
      expect(fmtNum(30437.5), '30.438');
      expect(fmtRp(-5000), '−Rp 5.000');
      expect(fmtNum(-1234), '−1.234');
    });

    test('membaca kembali nominal yang diformat', () {
      expect(parseRp('Rp 1.250.000'), 1250000);
      expect(parseRp('1.250.000'), 1250000);
      expect(parseRp('abc'), 0);
      expect(parseRp(null), 0);
    });

    test('formatter input menambah titik sambil mengetik', () {
      const formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234567'),
      );
      expect(result.text, '1.234.567');
      expect(result.selection.baseOffset, result.text.length);

      final cleared = formatter.formatEditUpdate(
        const TextEditingValue(text: '1.234.567'),
        TextEditingValue.empty,
      );
      expect(cleared.text, '');
    });
  });

  group('tanggal', () {
    test('label bulan penuh dan pendek', () {
      expect(monthLabel('2026-11'), 'November 2026');
      expect(monthShortLabel('2026-11'), 'Nov 2026');
      expect(monthLabel('2026-01'), 'Januari 2026');
    });

    test('geser bulan melewati tahun', () {
      expect(shiftMonth('2026-01', -1), '2025-12');
      expect(shiftMonth('2026-12', 1), '2027-01');
      expect(shiftMonth('2026-11', 2), '2027-01');
    });

    test('format tanggal dan kepala hari', () {
      expect(fmtDate('2026-11-25'), '25 Nov 2026');
      expect(fmtDayHead('2026-11-25'), 'Rabu, 25 November');
    });

    test('perkiraan waktu yang mudah dibaca', () {
      expect(etaLabel(null), 'rencana belum diisi');
      expect(etaLabel(0), 'sudah tercapai');
      expect(etaLabel(10), '≈ 10 hari lagi');
      expect(etaLabel(30), '≈ 4 minggu lagi');
      expect(etaLabel(400), '≈ 13 bulan lagi');
    });
  });
}
