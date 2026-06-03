import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_button.dart';

/// A widget that displays an error message with an icon and optional retry button.
///
/// Used throughout the app to show error states with a consistent look.
class AppErrorWidget extends StatelessWidget {
  /// Creates an [AppErrorWidget].
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.retryText = 'Coba Lagi',
  });

  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed. If null, no retry button is shown.
  final VoidCallback? onRetry;

  /// Icon displayed above the error message.
  final IconData icon;

  /// Color of the error icon. Defaults to [AppColors.error].
  final Color? iconColor;

  /// Text for the retry button.
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizing.iconXl,
              color: iconColor ?? AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: retryText,
                onPressed: onRetry,
                variant: AppButtonVariant.outline,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
