import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../domain/entities/worker_profile.dart';

/// A card widget displaying a worker's summary information.
///
/// Shows avatar, name, specialization, rating (numeric), total reviews,
/// completed jobs, distance in km, verification badge, availability status,
/// and base price in Rupiah.
///
/// Validates: Requirement 5.6.
class WorkerCard extends StatelessWidget {
  /// Creates a [WorkerCard] with the given [worker] data.
  const WorkerCard({
    required this.worker,
    super.key,
    this.onTap,
  });

  /// The worker profile data to display.
  final WorkerProfile worker;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: AppSizing.avatarLg / 2,
          backgroundColor: AppColors.surfaceVariant,
          backgroundImage: worker.avatarUrl != null
              ? CachedNetworkImageProvider(worker.avatarUrl!)
              : null,
          child: worker.avatarUrl == null
              ? Icon(
                  Icons.person,
                  size: AppSizing.iconLg,
                  color: AppColors.textDisabled,
                )
              : null,
        ),
        // Availability indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: worker.isAvailable ? AppColors.success : AppColors.textDisabled,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameRow(),
        const SizedBox(height: AppSpacing.xs),
        if (worker.specialization != null) ...[
          Text(
            worker.specialization!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        _buildRatingRow(),
        const SizedBox(height: AppSpacing.xs),
        _buildStatsRow(),
        const SizedBox(height: AppSpacing.sm),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            worker.fullName,
            style: AppTypography.h6,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (worker.isVerified)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Icon(
              Icons.verified,
              size: AppSizing.iconSm,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        RatingStars(
          rating: worker.ratingAvg,
          size: 14,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          worker.ratingAvg.toStringAsFixed(1),
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '(${worker.totalReviews} ulasan)',
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Icon(
          Icons.work_outline,
          size: AppSizing.iconXs,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          '${worker.completedJobs} pekerjaan',
          style: AppTypography.caption,
        ),
        if (worker.distance != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.location_on_outlined,
            size: AppSizing.iconXs,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 2),
          Text(
            '${worker.distance!.toStringAsFixed(1)} km',
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Availability status
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: worker.isAvailable
                ? AppColors.successLight
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizing.radiusXs),
          ),
          child: Text(
            worker.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
            style: AppTypography.caption.copyWith(
              color: worker.isAvailable
                  ? AppColors.success
                  : AppColors.textDisabled,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Base price
        if (worker.basePrice != null)
          Text(
            'Rp${_formatPrice(worker.basePrice!)}',
            style: AppTypography.priceSmall,
          ),
      ],
    );
  }

  /// Formats a price integer with thousand separators.
  String _formatPrice(int price) {
    final priceStr = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceStr[i]);
    }
    return buffer.toString();
  }
}
