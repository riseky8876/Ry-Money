// Token desain: tinta hangat, kertas, satu aksen hijau asam.

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

class R {
  R._();

  static const ink = Color(0xFF0A0B08);
  static const ink2 = Color(0xFF101208);
  static const ink3 = Color(0xFF171A10);
  static const line = Color(0xFF24281B);
  static const line2 = Color(0xFF333827);
  static const paper = Color(0xFFEFEDE3);
  static const paperDim = Color(0xFFCFCEBE);
  static const muted = Color(0xFF8C8E7C);
  static const acid = Color(0xFFC8F751);
  static const acidInk = Color(0xFF10130A);
  static const rust = Color(0xFFFF6A3D);
  static const olive = Color(0xFF6F7C3E);
  static const save = Color(0xFF9FBF48);
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

  static TextStyle eyebrow({Color color = R.muted}) => mono(
        10.5,
        color: color,
        letter: 1.7,
        height: 1.2,
        weight: FontWeight.w600,
      );
}

ThemeData ryTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: R.ink,
    canvasColor: R.ink,
    colorScheme: const ColorScheme.dark(
      primary: R.acid,
      onPrimary: R.acidInk,
      secondary: R.rust,
      onSecondary: R.ink,
      surface: R.ink2,
      onSurface: R.paper,
      error: R.rust,
      onError: R.ink,
    ),
    splashColor: R.acid.withAlpha(20),
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: R.acid,
      selectionColor: Color(0x55C8F751),
      selectionHandleColor: R.acid,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: R.acid,
      contentTextStyle: TextStyle(
        fontFamily: T.bodyFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: R.acidInk,
      ),
    ),
  );
}
