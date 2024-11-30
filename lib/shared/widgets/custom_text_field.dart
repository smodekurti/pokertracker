import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final double? prefixIconSize; // Added prefixIconSize
  final double? fontSize; // Added fontSize
  final Widget? suffix;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? errorText;
  final bool readOnly;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;
  final bool? showCursor;
  final double? cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final TextCapitalization textCapitalization;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final TextStyle? labelStyle;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.prefixIconSize, // Added to constructor
    this.fontSize, // Added to constructor
    this.suffix,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.focusNode,
    this.errorText,
    this.readOnly = false,
    this.fillColor,
    this.contentPadding,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.showCursor,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: style?.copyWith(
            color: enabled
                ? style?.color ?? theme.textTheme.bodyLarge?.color
                : theme.disabledColor,
            fontSize: fontSize,
          ) ??
          TextStyle(
            fontSize: fontSize ?? AppSizes.fontL.sp,
            color: enabled
                ? theme.textTheme.bodyLarge?.color
                : theme.disabledColor,
          ),
      textAlign: textAlign,
      autofocus: autofocus,
      showCursor: showCursor,
      cursorWidth: cursorWidth ?? 2.0.dp,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius ?? const Radius.circular(2.0),
      cursorColor: cursorColor ?? colorScheme.primary,
      keyboardAppearance: keyboardAppearance,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: fillColor != null,
        fillColor: fillColor,
        enabled: enabled,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled ? colorScheme.primary : theme.disabledColor,
                size: prefixIconSize ?? AppSizes.iconM.dp,
              )
            : null,
        prefixIconConstraints: prefixIconConstraints ??
            BoxConstraints(
              minWidth: (prefixIconSize ?? AppSizes.iconM.dp) * 2,
              minHeight: (prefixIconSize ?? AppSizes.iconM.dp) * 2,
            ),
        suffix: suffix,
        suffixIconConstraints: suffixIconConstraints,
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: AppSizes.paddingL.dp,
              vertical: AppSizes.paddingL.dp,
            ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2.dp,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.dp,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM.dp),
          borderSide: BorderSide(
            color: theme.disabledColor,
          ),
        ),
        labelStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize ?? AppSizes.fontM.sp,
        ),
        hintStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize ?? AppSizes.fontM.sp,
        ),
        errorStyle: TextStyle(
          color: colorScheme.error,
          fontSize: AppSizes.fontS.sp,
        ),
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }
}

// Also update the variant classes to support the new properties
class PasswordTextField extends CustomTextField {
  PasswordTextField({
    super.key,
    required super.label,
    required super.controller,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.enabled = true,
    super.errorText,
    super.prefixIconSize,
    super.fontSize,
  }) : super(
          obscureText: true,
          prefixIcon: Icons.lock,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
        );
}

class EmailTextField extends CustomTextField {
  EmailTextField({
    super.key,
    required super.controller,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.enabled = true,
    super.errorText,
    super.prefixIconSize,
    super.fontSize,
  }) : super(
          label: 'Email',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
        );
}

class SearchTextField extends CustomTextField {
  SearchTextField({
    super.key,
    required super.controller,
    super.onChanged,
    super.onSubmitted,
    super.enabled = true,
    super.prefixIconSize,
    super.fontSize,
  }) : super(
          label: 'Search',
          prefixIcon: Icons.search,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );
}

// Example usage class remains the same
class ValidationExample extends StatefulWidget {
  const ValidationExample({super.key});

  @override
  State<ValidationExample> createState() => _ValidationExampleState();
}

class _ValidationExampleState extends State<ValidationExample> {
  final _controller = TextEditingController();
  String? _errorText;

  void _validateInput(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = 'This field is required';
      } else if (value.length < 3) {
        _errorText = 'Must be at least 3 characters';
      } else {
        _errorText = null;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Example Field',
      controller: _controller,
      errorText: _errorText,
      onChanged: _validateInput,
      fontSize: AppSizes.fontL.sp,
      prefixIconSize: AppSizes.iconM.dp,
    );
  }
}
