import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/timeline_entry.dart';

/// Widget displaying the order progress timeline.
///
/// Shows each step (accepted, on the way, arrived, in progress, completed)
/// with a visual distinction between completed steps and pending steps.
///
/// Validates: Requirement 9.5
class OrderTimelineWidget extends StatelessWidget {
  const OrderTimelineWidget({
    required this.timeline, super.key,
  });

  /// The list of timeline entries to display.
  final List<TimelineEntry> timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progress Pesanan', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.md),
        ...timeline.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == timeline.length - 1;

          return _buildTimelineEntry(item, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineEntry(TimelineEntry entry, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Status dot
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isCompleted
                        ? AppColors.primary
                        : AppColors.surface,
                    border: Border.all(
                      color: entry.isCompleted
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: entry.isCompleted
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: entry.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.onPrimary,
                        )
                      : Icon(
                          _getStatusIcon(entry.status),
                          size: 12,
                          color: AppColors.textDisabled,
                        ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.isCompleted
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTypography.label.copyWith(
                      color: entry.isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontWeight:
                          entry.isCompleted ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: entry.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                    ),
                  ),
                  if (entry.timestamp != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('dd MMM, HH:mm', 'id')
                          .format(entry.timestamp!),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.onTheWay:
        return Icons.directions_car_outlined;
      case OrderStatus.arrived:
        return Icons.location_on_outlined;
      case OrderStatus.inProgress:
        return Icons.build_outlined;
      case OrderStatus.completed:
        return Icons.task_alt;
      default:
        return Icons.circle_outlined;
    }
  }
}
