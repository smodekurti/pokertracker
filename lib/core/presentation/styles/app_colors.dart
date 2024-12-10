import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF4AE8C0); // Mint green
  static const Color secondary = Color(0xFF4AB8E8); // Light blue

  // Background colors
  static const Color backgroundDark = Color(0xFF0B1120); // Dark navy
  static const Color backgroundMedium =
      Color(0xFF1A2232); // Slightly lighter navy

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Rank colors
  static const Color rankGold = Color(0xFFFFD700); // Gold for 1st
  static const Color rankSilver = Color(0xFFC0C0C0); // Silver for 2nd
  static const Color rankBronze = Color(0xFFB87333); // Bronze for 3rd

  static const Color backgroundLight =
      Color(0xFF2A3441); // Lighter background for progress bar
  static const Color inputBackground =
      Color(0xFF374151); // Background for input fields
  static const Color cancelButton =
      Color(0xFF4B5563); // Color for the cancel button

  // Action button color
  static const Color actionButton = Color(0xFF4AE8C0); // Mint green

  // Gradient combinations
  static const List<Color> primaryGradient = [
    Color(0xFF4AE8C0), // Mint green
    Color(0xFF4AB8E8), // Light blue
  ];

  static const List<Color> backgroundGradient = [
    backgroundDark,
    backgroundMedium,
    backgroundDark
  ];

  // Stats icon colors
  static const Color statsIconPurple =
      Color(0xFFA78BFA); // Purple for history icon
  static const Color statsIconGreen =
      Color(0xFF4AE8C0); // Green for trending icon
}
