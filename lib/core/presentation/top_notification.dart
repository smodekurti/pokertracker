// lib/core/presentation/widgets/top_notification.dart

import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';

enum NotificationType { success, error, info, warning }

class TopNotification extends StatelessWidget {
  final String message;
  final NotificationType type;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const TopNotification({
    super.key,
    required this.message,
    this.type = NotificationType.success,
    this.icon,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.success,
    IconData? icon,
    Duration duration = const Duration(seconds: 1),
  }) {
    // Remove any existing notifications first
    _removeCurrentNotification(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        message: message,
        type: type,
        icon: icon,
        onDismiss: () {
          _removeCurrentNotification(context);
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Store the current overlay entry
    _currentOverlayEntry = overlayEntry;

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (_currentOverlayEntry == overlayEntry) {
        _removeCurrentNotification(context);
      }
    });
  }

  static OverlayEntry? _currentOverlayEntry;

  static void _removeCurrentNotification(BuildContext context) {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This won't be used directly
  }
}

class _NotificationOverlay extends StatefulWidget {
  final String message;
  final NotificationType type;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const _NotificationOverlay({
    required this.message,
    required this.type,
    this.icon,
    this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.info:
        return AppColors.info;
      case NotificationType.warning:
        return AppColors.warning;
    }
  }

  IconData get _icon {
    return widget.icon ?? _defaultIcon;
  }

  IconData get _defaultIcon {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + AppSizes.spacingL.dp,
          left: AppSizes.paddingL.dp,
          right: AppSizes.paddingL.dp,
          child: Transform.translate(
            offset: Offset(0, -50 * (1 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _backgroundColor.withOpacity(0.9),
                          _backgroundColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL.dp),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8.dp,
                          offset: Offset(0, 2.dp),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingL.dp,
                      vertical: AppSizes.paddingM.dp,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _icon,
                          color: AppColors.textPrimary,
                          size: AppSizes.iconM.dp,
                        ),
                        SizedBox(width: AppSizes.spacingM.dp),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppSizes.fontM.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Padding(
                            padding:
                                EdgeInsets.only(left: AppSizes.paddingM.dp),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                              size: AppSizes.iconS.dp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
