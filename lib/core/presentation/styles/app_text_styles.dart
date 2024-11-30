// In your styles folder, create app_text_styles.dart

import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle get headingLarge => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        overflow: TextOverflow.ellipsis,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        overflow: TextOverflow.ellipsis,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        overflow: TextOverflow.ellipsis,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        overflow: TextOverflow.ellipsis,
      );

  // Add more text styles as needed
}

// Update your theme configuration
class AppTheme {
  static ThemeData get light => ThemeData.light().copyWith(
        textTheme: TextTheme(
          headlineLarge: AppTextStyles.headingLarge,
          headlineMedium: AppTextStyles.headingMedium,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          // Add more as needed
        ),
      );

  static ThemeData get dark => ThemeData.dark().copyWith(
        textTheme: TextTheme(
          headlineLarge: AppTextStyles.headingLarge,
          headlineMedium: AppTextStyles.headingMedium,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          // Add more as needed
        ),
      );
}
