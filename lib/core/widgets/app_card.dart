import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A reusable card widget with consistent styling for list items.
///
/// Provides optional tap handling, customizable padding, and elevation.
class AppCard extends StatelessWidget {
  /// Creates an [AppCard].
  const AppCard({
    required this.child, super.key,
    this.onTap,
    this.padding,
    this.elevation,
    this.margin,
    this.borderRadius,
    this.color,
  });

  /// The content of the card.
  final Widget child;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Padding inside the card. Defaults to [AppSpacing.cardPadding].
  final EdgeInsetsGeometry? padding;

  /// Card elevation. Defaults to [AppSizing.elevationSm].
  final double? elevation;

  /// Margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Border radius of the card.
  final BorderRadius? borderRadius;

  /// Background color of the card.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(AppSizing.radiusMd);

    return Card(
      elevation: elevation ?? AppSizing.elevationSm,
      margin: margin ?? EdgeInsets.zero,
      color: color ?? AppColors.surface,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: Padding(
          padding: padding ?? AppSpacing.cardPadding,
          child: child,
        ),
      ),
    );
  }
}
