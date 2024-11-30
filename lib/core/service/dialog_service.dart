// lib/core/services/dialog_service.dart

import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';

class DialogService {
  static final DialogService _instance = DialogService._internal();
  factory DialogService() => _instance;
  DialogService._internal();

  // Basic alert dialog
  static Future<T?> showAlert<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    return _showDialog<T>(
      context: context,
      builder: (context) => _AppDialog(
        title: title,
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontM,
          ),
        ),
        actions: [
          if (cancelText != null)
            _DialogButton(
              text: cancelText,
              onPressed: () => Navigator.pop(context, false),
            ),
          _DialogButton(
            text: confirmText ?? 'OK',
            onPressed: () => Navigator.pop(context, true),
            isPrimary: true,
            isDestructive: isDestructive,
          ),
        ],
      ),
    );
  }

  // Confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    return _showDialog<bool>(
      context: context,
      builder: (context) => _AppDialog(
        title: title,
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontM,
          ),
        ),
        actions: [
          _DialogButton(
            text: cancelText,
            onPressed: () => Navigator.pop(context, false),
          ),
          _DialogButton(
            text: confirmText,
            onPressed: () => Navigator.pop(context, true),
            isPrimary: true,
            isDestructive: isDestructive,
          ),
        ],
      ),
    );
  }

  // Custom content dialog
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return _showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _AppDialog(
        title: title,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
      ),
    );
  }

  // Base dialog show method
  static Future<T?> _showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Builder(builder: builder),
      ),
    );
  }
}

// Internal dialog widget
class _AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  const _AppDialog({
    required this.title,
    required this.content,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppSizes.font2XL,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: content,
      contentPadding: contentPadding ?? const EdgeInsets.all(AppSizes.paddingL),
      actions: actions,
    );
  }
}

// Internal button widget
class _DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _DialogButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? AppColors.error
        : isPrimary
            ? AppColors.primary
            : Colors.transparent;

    return Container(
      decoration: isPrimary && !isDestructive
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            )
          : null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              isPrimary ? AppColors.textPrimary : AppColors.textSecondary,
          backgroundColor: isPrimary ? null : backgroundColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingL,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppSizes.fontM,
          ),
        ),
      ),
    );
  }
}
