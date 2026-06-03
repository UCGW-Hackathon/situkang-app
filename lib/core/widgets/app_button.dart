import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Button variant types for [AppButton].
enum AppButtonVariant {
  /// Filled button with primary color background.
  primary,

  /// Filled button with secondary (teal) color background.
  secondary,

  /// Outlined button with border and transparent background.
  outline,
}

/// A reusable button widget with primary, secondary, and outline variants.
///
/// Supports loading state, disabled state, and optional leading icon.
class AppButton extends StatelessWidget {
  /// Creates an [AppButton].
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  });

  /// The button label text.
  final String text;

  /// Callback when the button is pressed. If null, button appears disabled.
  final VoidCallback? onPressed;

  /// The visual variant of the button.
  final AppButtonVariant variant;

  /// Whether to show a loading indicator instead of the text.
  final bool isLoading;

  /// Whether the button is disabled (ignores [onPressed]).
  final bool isDisabled;

  /// Optional leading icon displayed before the text.
  final IconData? icon;

  /// Optional fixed width. Defaults to full width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isDisabled || isLoading) ? null : onPressed;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : _buildContent();

    final buttonStyle = _getButtonStyle();

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: child,
        );
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: child,
        );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }

  Widget _buildContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizing.iconSm),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSizing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          textStyle: AppTypography.buttonMedium,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSizing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          textStyle: AppTypography.buttonMedium,
        );
      case AppButtonVariant.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSizing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          side: BorderSide(
            color: isDisabled ? AppColors.border : AppColors.primary,
            width: 1.5,
          ),
          textStyle: AppTypography.buttonMedium.copyWith(
            color: AppColors.primary,
          ),
        );
    }
  }
}
