import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double widthScale;
  static late double heightScale;
  static late double fontScale;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // Calculate scale factors
    widthScale = (screenWidth / AppSizes.minScreenWidth).clamp(1.0, 1.5);
    heightScale = (screenHeight / AppSizes.minScreenHeight).clamp(1.0, 1.5);
    fontScale = widthScale.clamp(1.0, 1.2);
  }

  // Padding
  static double dp(double size) => size * widthScale;

  // Font sizes
  static double sp(double size) => size * fontScale;

  // Heights
  static double hp(double height) => height * heightScale;

  // Widths
  static double wp(double width) => width * widthScale;
}

// Example extension methods for easier access
extension ResponsiveSize on num {
  double get dp => Responsive.dp(toDouble());
  double get sp => Responsive.sp(toDouble());
  double get hp => Responsive.hp(toDouble());
  double get wp => Responsive.wp(toDouble());
}
