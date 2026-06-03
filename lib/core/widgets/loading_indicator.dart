import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A centered loading indicator with an optional message.
///
/// Displays a [CircularProgressIndicator] centered in its parent
/// with an optional descriptive message below it.
class LoadingIndicator extends StatelessWidget {
  /// Creates a [LoadingIndicator].
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 36.0,
    this.color,
  });

  /// Optional message displayed below the spinner.
  final String? message;

  /// Size of the progress indicator.
  final double size;

  /// Color of the progress indicator. Defaults to primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
