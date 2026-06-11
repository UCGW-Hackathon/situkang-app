import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/active_order.dart';

/// Banner widget displaying the user's currently active order.
///
/// Shows order status, worker name, service name, and ETA.
/// Only displayed when the user has an active order (status: pending,
/// accepted, on_the_way, arrived, or in_progress).
///
/// Requirement 3.2: Display active order banner with status, worker name,
/// service name, and ETA in minutes.
/// Requirement 3.3: Hide when no active order exists.
class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({required this.activeOrder, super.key, this.onTap});

  /// The active order data to display.
  final ActiveOrder activeOrder;

  /// Callback when the banner is tapped (navigate to order detail/tracking).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(activeOrder.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingHorizontal,
        ),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.$1, colors.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: colors.$1.withValues(alpha: 0.26),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
              ),
              child: Icon(
                _getStatusIcon(activeOrder.status),
                color: AppColors.onPrimary,
                size: AppSizing.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusLabel(activeOrder.status),
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    activeOrder.serviceName,
                    style: AppTypography.h6.copyWith(
                      color: AppColors.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    activeOrder.workerName,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // ETA or arrow
            if (activeOrder.etaMinutes != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  Text(
                    '${activeOrder.etaMinutes}',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  Text(
                    'menit',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Icon(
                Icons.chevron_right,
                color: AppColors.onPrimary,
                size: AppSizing.iconMd,
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color) _getStatusColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (const Color(0xFF7B8490), const Color(0xFFA8B0BA));
      case OrderStatus.completed:
        return (const Color(0xFF00AA13), const Color(0xFF37D64A));
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
      case OrderStatus.inProgress:
      case OrderStatus.workPaused:
        return (AppColors.primary, AppColors.primaryLight);
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return (AppColors.error, const Color(0xFFFF7A7A));
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.onTheWay:
        return Icons.directions_walk;
      case OrderStatus.arrived:
        return Icons.location_on;
      case OrderStatus.inProgress:
        return Icons.build;
      default:
        return Icons.assignment;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.accepted:
        return 'Pesanan Diterima';
      case OrderStatus.onTheWay:
        return 'Tukang Dalam Perjalanan';
      case OrderStatus.arrived:
        return 'Tukang Telah Tiba';
      case OrderStatus.inProgress:
        return 'Sedang Dikerjakan';
      case OrderStatus.completed:
        return 'Pekerjaan Selesai';
      default:
        return 'Pesanan Aktif';
    }
  }
}
