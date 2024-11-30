import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF4ade80);
  static const Color secondary = Color(0xFF3b82f6);

  // Background colors
  static const Color backgroundDark = Color(0xFF1a1a1a);
  static const Color backgroundMedium = Color(0xFF2d2d2d);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Gradient combinations
  static const List<Color> primaryGradient = [primary, secondary];
  static const List<Color> backgroundGradient = [
    backgroundDark,
    backgroundMedium,
    backgroundDark
  ];
}
