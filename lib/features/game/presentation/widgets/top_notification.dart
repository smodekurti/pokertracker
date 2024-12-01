// widgets/top_notification.dart
import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';

enum NotificationType { success, error, warning, info }

class TopNotification {
  static OverlayEntry? _currentNotification;

  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentNotification?.remove();

    final overlayState = Overlay.of(context);

    _currentNotification = OverlayEntry(
      builder: (context) => SafeArea(
        child: Material(
          color: Colors.transparent,
          child: _NotificationWidget(
            message: message,
            type: type,
            icon: icon,
            onDismiss: () => _currentNotification?.remove(),
          ),
        ),
      ),
    );

    overlayState.insert(_currentNotification!);

    Future.delayed(duration, () {
      _currentNotification?.remove();
      _currentNotification = null;
    });
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final IconData? icon;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.type,
    this.icon,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_animation),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
