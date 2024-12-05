// lib/core/presentation/widgets/password_strength_indicator.dart

import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  medium,
  strong;

  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String get message {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak password';
      case PasswordStrength.medium:
        return 'Medium strength';
      case PasswordStrength.strong:
        return 'Strong password';
    }
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool isVisible;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.isVisible,
  });

  PasswordStrength _calculateStrength() {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score < 3) return PasswordStrength.weak;
    if (score < 5) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: switch (strength) {
                PasswordStrength.weak => 0.33,
                PasswordStrength.medium => 0.66,
                PasswordStrength.strong => 1.0,
              },
              backgroundColor: Colors.grey[800],
              color: strength.color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strength.message,
            style: TextStyle(
              color: strength.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
