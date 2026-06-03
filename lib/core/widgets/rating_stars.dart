import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A widget that displays star ratings in either display (read-only) or input (tappable) mode.
///
/// In display mode, shows filled/half/empty stars based on the rating value.
/// In input mode, allows the user to tap stars to set a rating (1-5).
class RatingStars extends StatelessWidget {
  /// Creates a [RatingStars] widget in display mode (read-only).
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.color,
    this.emptyColor,
    this.onRatingChanged,
    this.showValue = false,
  });

  /// Creates a [RatingStars] widget in input mode (tappable).
  const RatingStars.input({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 36.0,
    this.color,
    this.emptyColor,
    this.showValue = false,
  });

  /// The current rating value (1.0 - 5.0).
  final double rating;

  /// Size of each star icon.
  final double size;

  /// Color of filled stars. Defaults to [AppColors.ratingStar].
  final Color? color;

  /// Color of empty stars. Defaults to [AppColors.ratingStarEmpty].
  final Color? emptyColor;

  /// Callback when a star is tapped (input mode). If null, widget is read-only.
  final ValueChanged<int>? onRatingChanged;

  /// Whether to show the numeric rating value next to the stars.
  final bool showValue;

  bool get _isInputMode => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppColors.ratingStar;
    final emptyStarColor = emptyColor ?? AppColors.ratingStarEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          final icon = _getStarIcon(starIndex);

          final starWidget = Icon(
            icon,
            size: size,
            color: _getStarColor(starIndex, starColor, emptyStarColor),
          );

          if (_isInputMode) {
            return GestureDetector(
              onTap: () => onRatingChanged?.call(starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: starWidget,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: starWidget,
          );
        }),
        if (showValue) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStarIcon(int starIndex) {
    if (rating >= starIndex) {
      return Icons.star;
    } else if (rating >= starIndex - 0.5) {
      return Icons.star_half;
    }
    return Icons.star_border;
  }

  Color _getStarColor(int starIndex, Color filled, Color empty) {
    if (rating >= starIndex - 0.5) {
      return filled;
    }
    return empty;
  }
}
