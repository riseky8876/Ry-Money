// Token desain — arah "Nordic calm": kertas terang, netral hangat,
// satu aksen hijau tenang, dan ruang kosong yang lega.
//
// Catatan penting: nama token dipertahankan agar seluruh pemakaian di
// layar tetap valid, tapi maknanya sudah dibalik untuk tema terang —
//   `ink*`  = permukaan (latar)
//   `paper` = teks utama

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

class R {
  R._();

  // Permukaan.
  static const ink = Color(0xFFF4F3EE);
  static const ink2 = Color(0xFFFDFCFA);
  static const ink3 = Color(0xFFECEBE4);
  static const line = Color(0xFFE2E1D8);
  static const line2 = Color(0xFFCDCBC0);

  // Teks.
  static const paper = Color(0xFF1B1D16);
  static const paperDim = Color(0xFF5A5D52);
  static const muted = Color(0xFF6E7165);

  // Aksen tunggal — hijau tenang, bukan hijau asam.
  static const acid = Color(0xFF2F6B3F);
  static const acidInk = Color(0xFFF3F7EF);
  static const rust = Color(0xFFBE4318);
  static const olive = Color(0xFFA88A2E);
  static const save = Color(0xFF4E8C3F);
  static const spend = Color(0xFFB2451F);
}

class T {
  T._();

  static const displayFamily = 'Fraunces';
  static const bodyFamily = 'Karla';
  static const monoFamily = 'JetBrainsMono';

  static const tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Judul serif. Ukuran besar memakai tracking lebih rapat.
  static TextStyle display(
    double size, {
    Color color = R.paper,
    double height = 1.0,
    double letter = -0.035,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      height: height,
      letterSpacing: letter * size,
      color: color,
      fontWeight: weight,
      fontFeatures: tabular,
    );
  }

  static TextStyle body(
    double size, {
    Color color = R.paper,
    double height = 1.45,
    double letter = 0,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      height: height,
      letterSpacing: letter,
      color: color,
      fontWeight: weight,
    );
  }

  static TextStyle mono(
    double size, {
    Color color = R.paper,
    double height = 1.25,
    double letter = 0,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      height: height,
      letterSpacing: letter,
      color: color,
      fontWeight: weight,
      fontFeatures: tabular,
    );
  }

  /// Label seksi. Sengaja tidak teriak: huruf kecil, tracking ringan.
  static TextStyle eyebrow({Color color = R.muted}) => mono(
        11.5,
        color: color,
        letter: 0.8,
        height: 1.2,
        weight: FontWeight.w600,
      );
}

ThemeData ryTheme() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: R.ink,
    canvasColor: R.ink,
    colorScheme: const ColorScheme.light(
      primary: R.acid,
      onPrimary: R.acidInk,
      secondary: R.rust,
      onSecondary: R.acidInk,
      surface: R.ink2,
      onSurface: R.paper,
      error: R.rust,
      onError: R.acidInk,
    ),
    splashColor: R.acid.withAlpha(26),
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: R.acid,
      selectionColor: Color(0x332F6B3F),
      selectionHandleColor: R.acid,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: R.paper,
      contentTextStyle: TextStyle(
        fontFamily: T.bodyFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: R.ink,
      ),
    ),
  );
}
