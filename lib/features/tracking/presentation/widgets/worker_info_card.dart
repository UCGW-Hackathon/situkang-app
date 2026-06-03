import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Card widget displaying worker information during tracking.
///
/// Shows name, avatar, specialization, and rating in a compact card format.
///
/// Validates: Requirement 9.6
class WorkerInfoCard extends StatelessWidget {
  const WorkerInfoCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.specialization,
    this.rating,
  });

  /// Worker's display name.
  final String name;

  /// Worker's avatar URL.
  final String? avatarUrl;

  /// Worker's specialization description.
  final String? specialization;

  /// Worker's average rating.
  final double? rating;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizing.avatarMd / 2,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: AppSizing.iconMd)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.h6),
                if (specialization != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    specialization!,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (rating != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: AppSizing.iconSm,
                      color: AppColors.ratingStar,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
