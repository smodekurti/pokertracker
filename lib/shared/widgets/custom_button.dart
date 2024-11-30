import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? fontSize;
  final double? iconSize;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ??
        (isOutlined ? Colors.transparent : AppColors.primary);
    final effectiveTextColor =
        textColor ?? (isOutlined ? AppColors.primary : AppColors.textPrimary);

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        disabledBackgroundColor: theme.disabledColor,
        elevation: isOutlined ? 0 : 2.dp,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppSizes.radiusL.dp),
          side: isOutlined
              ? BorderSide(
                  color: onPressed != null
                      ? effectiveTextColor
                      : theme.disabledColor,
                  width: 2.dp,
                )
              : BorderSide.none,
        ),
      ),
      child: Container(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: AppSizes.paddingL.dp,
              vertical: AppSizes.paddingM.dp,
            ),
        child: _buildButtonContent(effectiveTextColor, theme),
      ),
    );

    if (width != null || height != null) {
      button = SizedBox(
        width: width,
        height: height ?? AppSizes.spacing3XL.dp,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent(Color effectiveTextColor, ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: iconSize ?? AppSizes.iconM.dp,
        width: iconSize ?? AppSizes.iconM.dp,
        child: CircularProgressIndicator(
          strokeWidth: 2.dp,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: onPressed != null ? effectiveTextColor : theme.disabledColor,
            size: iconSize ?? AppSizes.iconM.dp,
          ),
          SizedBox(width: AppSizes.spacingS.dp),
          Text(
            text,
            style: TextStyle(
              color:
                  onPressed != null ? effectiveTextColor : theme.disabledColor,
              fontSize: fontSize ?? AppSizes.fontL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: onPressed != null ? effectiveTextColor : theme.disabledColor,
        fontSize: fontSize ?? AppSizes.fontL.sp,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
