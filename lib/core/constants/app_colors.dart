import 'package:flutter/material.dart';

/// App-level colors following an Islamic palette (green, gold, dark blue).
abstract class AppColors {
  static const Color primary = Color(0xFF0B3D35);
  static const Color secondary = Color(0xFF1A8F7A);
  static const Color accent = Color(0xFFE3B23C);
  static const Color background = Color(0xFF0A1B2B);
  static const Color surface = Color(0xFF112F3B);
  static const Color text = Colors.white;

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0B3D35), Color(0xFF1A8F7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
