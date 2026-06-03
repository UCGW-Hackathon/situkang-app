import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// A widget that displays password strength based on criteria met.
///
/// Shows a visual indicator with colored bars and text describing
/// the password strength level. Criteria checked:
/// - Minimum 8 characters
/// - Contains uppercase letter
/// - Contains lowercase letter
/// - Contains digit
///
/// Validates: Requirement 1.4 (password requirements feedback).
class PasswordStrengthIndicator extends StatelessWidget {
  /// Creates a [PasswordStrengthIndicator] for the given [password].
  const PasswordStrengthIndicator({
    required this.password,
    super.key,
  });

  /// The password to evaluate strength for.
  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculateStrength(password);
    final color = _getStrengthColor(strength);
    final label = _getStrengthLabel(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 3 ? AppSpacing.xs : 0,
                ),
                decoration: BoxDecoration(
                  color: index < strength ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: color),
        ),
      ],
    );
  }

  /// Calculates strength score (0-4) based on criteria met.
  int _calculateStrength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp('[A-Z]'))) score++;
    if (password.contains(RegExp('[a-z]'))) score++;
    if (password.contains(RegExp('[0-9]'))) score++;
    return score;
  }

  /// Returns the color for the given strength score.
  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.accent;
      case 4:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  /// Returns the label text for the given strength score.
  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat';
      default:
        return '';
    }
  }
}
