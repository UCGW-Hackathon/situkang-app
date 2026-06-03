import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

import '../bloc/tracking_bloc.dart';
import '../widgets/order_timeline_widget.dart';
import '../widgets/worker_info_card.dart';

/// Page for real-time tracking of worker location and order progress.
///
/// Displays a map with worker/user markers, ETA display, order timeline,
/// worker info card, and quick-access buttons for Chat and Call.
///
/// Validates: Requirements 9.1-9.9
class TrackingPage extends StatefulWidget {
  const TrackingPage({
    super.key,
    required this.orderId,
    this.workerName,
    this.workerAvatarUrl,
    this.workerSpecialization,
    this.workerRating,
    this.workerPhone,
    this.userLatitude,
    this.userLongitude,
  });

  /// The order ID to track.
  final String orderId;

  /// Worker's display name.
  final String? workerName;

  /// Worker's avatar URL.
  final String? workerAvatarUrl;

  /// Worker's specialization.
  final String? workerSpecialization;

  /// Worker's rating.
  final double? workerRating;

  /// Worker's phone number.
  final String? workerPhone;

  /// User's latitude for map display.
  final double? userLatitude;

  /// User's longitude for map display.
  final double? userLongitude;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(StartTracking(orderId: widget.orderId));
  }

  @override
  void dispose() {
    context.read<TrackingBloc>().add(const StopTracking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<TrackingBloc, TrackingState>(
        listener: (context, state) {
          // Navigate to completion view when status is completed
          if (state is TrackingCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan telah selesai! 🎉'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
            // Pop back to order detail
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        },
        builder: (context, state) {
          if (state is TrackingInitial) {
            return const LoadingIndicator(message: 'Menghubungkan...');
          }

          if (state is TrackingError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context.read<TrackingBloc>().add(
                      StartTracking(orderId: widget.orderId),
                    );
              },
            );
          }

          if (state is TrackingActive) {
            return _buildTrackingView(context, state);
          }

          if (state is TrackingCompleted) {
            return _buildCompletedView();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTrackingView(BuildContext context, TrackingActive state) {
    return Column(
      children: [
        // Map area
        Expanded(
          flex: 3,
          child: _buildMapPlaceholder(state),
        ),

        // Bottom panel with info
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ETA display
                  _buildEtaDisplay(state),
                  const SizedBox(height: AppSpacing.md),

                  // Worker info card
                  WorkerInfoCard(
                    name: widget.workerName ?? 'Tukang',
                    avatarUrl: widget.workerAvatarUrl,
                    specialization: widget.workerSpecialization,
                    rating: widget.workerRating,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quick action buttons
                  _buildQuickActions(context),
                  const SizedBox(height: AppSpacing.formSectionSpacing),

                  // Order timeline
                  OrderTimelineWidget(timeline: state.timeline),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(TrackingActive state) {
    // In a real implementation, this would use GoogleMap widget.
    // Using a placeholder with location info for now.
    return Container(
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: Stack(
        children: [
          // Map placeholder background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: AppSizing.iconXxl,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Google Maps',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                if (state.workerLocation != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Lat: ${state.workerLocation!.latitude.toStringAsFixed(4)}, '
                    'Lng: ${state.workerLocation!.longitude.toStringAsFixed(4)}',
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),

          // Status overlay
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Live Tracking',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaDisplay(TrackingActive state) {
    final isOnTheWay = state.status == OrderStatus.onTheWay;

    return AppCard(
      color: isOnTheWay ? AppColors.primaryContainer : AppColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isOnTheWay
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnTheWay ? Icons.directions_car : _getStatusIcon(state.status),
              color: isOnTheWay ? AppColors.primary : AppColors.textSecondary,
              size: AppSizing.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(state.status),
                  style: AppTypography.h6,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (isOnTheWay && state.etaMinutes != null)
                  Text(
                    'Perkiraan tiba: ${state.etaMinutes} menit',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (isOnTheWay)
                  Text(
                    'Menghitung waktu tiba...',
                    style: AppTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (isOnTheWay && state.etaMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    '${state.etaMinutes}',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  Text(
                    'min',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Chat',
            icon: Icons.chat_bubble_outline,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka percakapan...')));
            },
            variant: AppButtonVariant.outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            text: 'Telepon',
            icon: Icons.phone_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghubungi telepon...')));
            },
            variant: AppButtonVariant.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: AppSizing.iconXxl,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Pesanan Selesai!', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pekerjaan telah diselesaikan oleh tukang.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
        return Icons.directions_car;
      case OrderStatus.arrived:
        return Icons.location_on;
      case OrderStatus.inProgress:
        return Icons.build;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Pesanan Diterima';
      case OrderStatus.onTheWay:
        return 'Tukang Dalam Perjalanan';
      case OrderStatus.arrived:
        return 'Tukang Tiba di Lokasi';
      case OrderStatus.inProgress:
        return 'Sedang Dikerjakan';
      default:
        return 'Tracking Aktif';
    }
  }
}
