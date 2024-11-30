// lib/core/presentation/widgets/responsive_builder.dart
import 'package:flutter/material.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';

class ResponsiveBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<ResponsiveBuilder> createState() => _ResponsiveBuilderState();
}

class _ResponsiveBuilderState extends State<ResponsiveBuilder> {
  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return widget.builder(context);
  }
}
