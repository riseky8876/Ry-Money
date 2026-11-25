import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Menyimpan satu keadaan aplikasi di penyimpanan lokal HP.
class RyStore extends ChangeNotifier {
  static const String _key = 'rymoney.v2';
  static const String _legacyKey = 'rymoney.v1';

  AppState state = AppState.fresh();
  bool ready = false;
  String? loadWarning;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key) ?? prefs.getString(_legacyKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          state = AppState.fromJson(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    } catch (error) {
      debugPrint('Data lokal tidak terbaca: $error');
      loadWarning = 'Data lama tidak terbaca, mulai dari kosong.';
      state = AppState.fresh();
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (error) {
      debugPrint('Gagal menyimpan: $error');
      return false;
    }
  }

  /// Simpan tanpa menunggu (dipakai dari tombol kecil).
  void changed() {
    save();
  }

  void touch() => notifyListeners();

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(state.toJson());

  /// Kembalikan pesan galat, atau null kalau berhasil.
  String? restore(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Teks cadangan masih kosong.';
    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return 'Bukan JSON yang valid.';
    }
    if (decoded is! Map) return 'Cadangan harus berupa objek JSON.';
    final map = decoded.map((k, v) => MapEntry(k.toString(), v));
    final known = <String>['incomes', 'routines', 'goals', 'txns'];
    if (!known.any(map.containsKey)) {
      return 'Bukan cadangan Ry-Money.';
    }
    state = AppState.fromJson(map);
    save();
    return null;
  }
}
