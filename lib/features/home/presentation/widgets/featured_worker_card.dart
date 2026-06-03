import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/featured_worker.dart';

/// Card widget displaying a featured nearby worker.
///
/// Shows worker name, specialization, avatar, rating (1.0–5.0),
/// distance in km, completed jobs count, and verification badge.
///
/// Requirement 3.6: Display up to 10 featured nearby workers within
/// a 10 km radius sorted by distance in ascending order.
class FeaturedWorkerCard extends StatelessWidget {
  const FeaturedWorkerCard({
    required this.worker,
    super.key,
    this.onTap,
  });

  /// The featured worker data to display.
  final FeaturedWorker worker;

  /// Callback when the card is tapped (navigate to worker detail).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: AppSpacing.cardPaddingSmall,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar with verification badge
            Stack(
              children: [
                CircleAvatar(
                  radius: AppSizing.avatarMd / 2,
                  backgroundColor: AppColors.surfaceVariant,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: worker.avatarUrl,
                      width: AppSizing.avatarMd,
                      height: AppSizing.avatarMd,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(
                        Icons.person,
                        color: AppColors.textDisabled,
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
                if (worker.isVerified)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: AppSizing.iconSm,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Worker name
            Text(
              worker.name,
              style: AppTypography.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Specialization
            Text(
              worker.specialization,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Rating and distance row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star,
                  color: AppColors.ratingStar,
                  size: AppSizing.iconSm,
                ),
                const SizedBox(width: 2),
                Text(
                  worker.rating.toStringAsFixed(1),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                  size: AppSizing.iconSm,
                ),
                const SizedBox(width: 2),
                Text(
                  '${worker.distance.toStringAsFixed(1)} km',
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Completed jobs
            Text(
              '${worker.completedJobs} pekerjaan selesai',
              style: AppTypography.overline.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
