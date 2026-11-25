// Angka, tanggal, dan teks — ditulis tangan supaya tidak perlu paket intl.

import 'package:flutter/services.dart';

const _monthsFull = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const _daysFull = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String groupDigits(String digits) {
  if (digits.isEmpty) return digits;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String fmtNum(num value) {
  final n = value.round();
  return n < 0 ? '−${groupDigits(n.abs().toString())}' : groupDigits(n.toString());
}

/// Rupiah tanpa desimal: `Rp 1.250.000`, negatif pakai tanda minus tipografis.
String fmtRp(num value) {
  final n = value.round();
  final body = groupDigits(n.abs().toString());
  return n < 0 ? '−Rp $body' : 'Rp $body';
}

double parseRp(String? text) {
  final digits = (text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return double.tryParse(digits) ?? 0;
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}-${_pad2(d.day)}';

String todayISO() => isoDate(DateTime.now());

String currentMonthKey() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}';
}

String monthOf(String? iso) {
  if (iso != null && RegExp(r'^\d{4}-\d{2}').hasMatch(iso) && iso.length >= 7) {
    return iso.substring(0, 7);
  }
  return currentMonthKey();
}

String monthLabel(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final year = int.tryParse(parts[0]);
  final index = int.tryParse(parts[1]);
  if (year == null || index == null || index < 1 || index > 12) return month;
  return '${_monthsFull[index - 1]} $year';
}

String monthShortLabel(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final year = int.tryParse(parts[0]);
  final index = int.tryParse(parts[1]);
  if (year == null || index == null || index < 1 || index > 12) return month;
  return '${_monthsShort[index - 1]} $year';
}

String shiftMonth(String month, int delta) {
  final parts = month.split('-');
  final year = int.tryParse(parts.first) ?? DateTime.now().year;
  final index = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
  final d = DateTime(year, index + delta, 1);
  return '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}';
}

String fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  return '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';
}

String fmtDayHead(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_daysFull[d.weekday - 1]}, ${d.day} ${_monthsFull[d.month - 1]}';
}

/// "≈ 8 minggu lagi" — perkiraan yang mudah dibaca.
String etaLabel(double? days) {
  if (days == null) return 'rencana belum diisi';
  if (days <= 0) return 'sudah tercapai';
  if (days < 1) return 'kurang dari sehari lagi';
  if (days < 14) return '≈ ${days.ceil()} hari lagi';
  if (days < 120) return '≈ ${(days / 7).round()} minggu lagi';
  if (days < 730) return '≈ ${(days / 30.44).round()} bulan lagi';
  return '≈ ${(days / 365).toStringAsFixed(1)} tahun lagi';
}

/// Memformat ketikan nominal jadi bergrup titik, tanpa desimal.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (trimmed.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final text = groupDigits(trimmed);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Hanya angka, untuk kolom "tiap N hari".
class DigitsInputFormatter extends TextInputFormatter {
  const DigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
