import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/order_detail.dart';
import '../bloc/order_bloc.dart';

/// Page displaying full order detail information.
///
/// Shows worker details, service, location, schedule, pricing breakdown,
/// photos, notes, timeline, and purchase summary. Provides cancel button
/// for cancellable orders.
///
/// Validates: Requirements 8.3, 8.4, 8.5, 8.6
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  /// The ID of the order to display.
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            // Order was cancelled/updated successfully
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan berhasil diperbarui'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) {
            return const _OrderDetailSkeleton();
          }

          if (state is OrderError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context.read<OrderBloc>().add(
                      FetchOrderDetailRequested(orderId: orderId),
                    );
              },
            );
          }

          if (state is OrderDetailLoaded) {
            return _buildContent(context, state.orderDetail);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrderDetail order) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(order),
          const SizedBox(height: AppSpacing.formSectionSpacing),
          _buildOrderInfo(order),
          const SizedBox(height: AppSpacing.formSectionSpacing),
          _buildWorkerSection(order),
          const SizedBox(height: AppSpacing.formSectionSpacing),
          _buildLocationSection(order),
          if (order.preferredDate != null || order.preferredTimeStart != null)
            ...[
              const SizedBox(height: AppSpacing.formSectionSpacing),
              _buildScheduleSection(order),
            ],
          const SizedBox(height: AppSpacing.formSectionSpacing),
          _buildPricingSection(order),
          if (order.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.formSectionSpacing),
            _buildPhotosSection(order),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.formSectionSpacing),
            _buildNotesSection(order),
          ],
          const SizedBox(height: AppSpacing.formSectionSpacing),
          _buildTimeline(order),
          if (order.purchaseSummary != null) ...[
            const SizedBox(height: AppSpacing.formSectionSpacing),
            _buildPurchaseSummary(order),
          ],
          if (order.canCancel) ...[
            const SizedBox(height: AppSpacing.formSectionSpacing),
            _buildCancelButton(context, order),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(OrderDetail order) {
    return AppCard(
      color: _getStatusColor(order.status).withValues(alpha: 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: _getStatusColor(order.status),
              size: AppSizing.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(order.status),
                  style: AppTypography.h6.copyWith(
                    color: _getStatusColor(order.status),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  order.orderNumber,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (order.urgency == OrderUrgency.urgent)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.priority_high,
                    size: AppSizing.iconXs,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Urgent',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informasi Pesanan', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.title, style: AppTypography.h6),
              const SizedBox(height: AppSpacing.sm),
              Text(order.description, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              if (order.serviceInfo != null) ...[
                _buildInfoRow(
                  Icons.build_outlined,
                  'Layanan',
                  order.serviceInfo!.name,
                ),
                if (order.serviceInfo!.category != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _buildInfoRow(
                    Icons.category_outlined,
                    'Kategori',
                    order.serviceInfo!.category!,
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.xs),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Dibuat',
                DateFormat('dd MMMM yyyy, HH:mm', 'id').format(order.createdAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerSection(OrderDetail order) {
    if (order.workerInfo == null) return const SizedBox.shrink();

    final worker = order.workerInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tukang', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSizing.avatarLg / 2,
                backgroundImage: worker.avatarUrl != null
                    ? NetworkImage(worker.avatarUrl!)
                    : null,
                child: worker.avatarUrl == null
                    ? const Icon(Icons.person, size: AppSizing.iconLg)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(worker.fullName, style: AppTypography.h6),
                        ),
                        if (worker.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: AppSizing.iconSm,
                          ),
                      ],
                    ),
                    if (worker.specialization != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        worker.specialization!,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                    if (worker.rating != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          RatingStars(
                            rating: worker.rating!,
                            size: AppSizing.iconSm,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${worker.rating!.toStringAsFixed(1)} (${worker.totalReviews ?? 0})',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lokasi', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: AppSizing.iconMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      order.location.address,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (order.location.addressDetail != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    order.location.addressDetail!,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jadwal Preferensi', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.preferredDate != null)
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal',
                  DateFormat('dd MMMM yyyy', 'id').format(order.preferredDate!),
                ),
              if (order.preferredTimeStart != null ||
                  order.preferredTimeEnd != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildInfoRow(
                  Icons.access_time,
                  'Waktu',
                  '${order.preferredTimeStart ?? '-'} - ${order.preferredTimeEnd ?? '-'}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(OrderDetail order) {
    final formatter = NumberFormat('#,###', 'id');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rincian Biaya', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              _buildPriceRow(
                'Biaya Booking',
                formatter.format(order.bookingFee),
              ),
              if (order.baseServiceFee != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildPriceRow(
                  'Biaya Layanan',
                  formatter.format(order.baseServiceFee),
                ),
              ],
              if (order.totalMaterialCost > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildPriceRow(
                  'Biaya Material',
                  formatter.format(order.totalMaterialCost),
                ),
              ],
              if (order.totalAdditionalCost > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildPriceRow(
                  'Biaya Tambahan',
                  formatter.format(order.totalAdditionalCost),
                ),
              ],
              if (order.grandTotal != null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: AppTypography.h6),
                    Text(
                      'Rp${formatter.format(order.grandTotal)}',
                      style: AppTypography.priceLarge,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSizing.thumbnailLg,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: order.photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                child: Image.network(
                  order.photos[index],
                  width: AppSizing.thumbnailLg,
                  height: AppSizing.thumbnailLg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: AppSizing.thumbnailLg,
                    height: AppSizing.thumbnailLg,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catatan', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Text(order.notes!, style: AppTypography.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildTimeline(OrderDetail order) {
    if (order.timeline.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Timeline', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: order.timeline.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == order.timeline.length - 1;

              return _buildTimelineItem(item, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(OrderTimelineEntry item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  border: Border.all(
                    color: item.isCompleted
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.onPrimary,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: item.isCompleted
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Timeline content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.label.copyWith(
                      color: item.isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                  if (item.timestamp != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'id')
                          .format(item.timestamp!),
                      style: AppTypography.caption,
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

  Widget _buildPurchaseSummary(OrderDetail order) {
    final summary = order.purchaseSummary!;
    final formatter = NumberFormat('#,###', 'id');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan Pembelian', style: AppTypography.h5),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              _buildPriceRow(
                'Total Item',
                '${summary.totalItems} item',
                isPrice: false,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildPriceRow(
                'Total Biaya',
                formatter.format(summary.totalCost),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildPriceRow(
                'Disetujui',
                formatter.format(summary.approved),
                valueColor: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildPriceRow(
                'Menunggu',
                formatter.format(summary.pendingApproval),
                valueColor: AppColors.warning,
              ),
              if (summary.rejected > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildPriceRow(
                  'Ditolak',
                  formatter.format(summary.rejected),
                  valueColor: AppColors.error,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, OrderDetail order) {
    return SizedBox(
      width: double.infinity,
      height: AppSizing.buttonHeightMd,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelDialog(context, order),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Batalkan Pesanan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          textStyle: AppTypography.buttonMedium,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, OrderDetail order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan ${order.orderNumber} akan dibatalkan. Tindakan ini tidak bisa dikembalikan.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan *',
                hintText: 'Masukkan alasan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 1000,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                context.read<OrderBloc>().add(
                      CancelOrderRequested(
                        orderId: order.id,
                        reason: reason,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizing.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: AppTypography.caption),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isPrice = true,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          isPrice ? 'Rp$value' : value,
          style: AppTypography.label.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.accepted:
        return AppColors.statusAccepted;
      case OrderStatus.onTheWay:
        return AppColors.statusOnTheWay;
      case OrderStatus.arrived:
        return AppColors.statusArrived;
      case OrderStatus.inProgress:
        return AppColors.statusInProgress;
      case OrderStatus.workPaused:
        return AppColors.statusInProgress;
      case OrderStatus.completed:
        return AppColors.statusCompleted;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      case OrderStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.onTheWay:
        return Icons.directions_car;
      case OrderStatus.arrived:
        return Icons.location_on;
      case OrderStatus.inProgress:
        return Icons.build;
      case OrderStatus.workPaused:
        return Icons.pause_circle_outline;
      case OrderStatus.completed:
        return Icons.task_alt;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.block;
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
        return 'Tukang Tiba di Lokasi';
      case OrderStatus.inProgress:
        return 'Sedang Dikerjakan';
      case OrderStatus.workPaused:
        return 'Pekerjaan Dijeda';
      case OrderStatus.completed:
        return 'Pesanan Selesai';
      case OrderStatus.cancelled:
        return 'Pesanan Dibatalkan';
      case OrderStatus.rejected:
        return 'Ditolak';
    }
  }
}

class _OrderDetailSkeleton extends StatelessWidget {
  const _OrderDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoader(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(height: 80, width: double.infinity, borderRadius: 16),
            SizedBox(height: AppSpacing.formSectionSpacing),
            Skeleton(height: 24, width: 150),
            SizedBox(height: AppSpacing.sm),
            Skeleton(height: 180, width: double.infinity, borderRadius: 16),
            SizedBox(height: AppSpacing.formSectionSpacing),
            Skeleton(height: 24, width: 100),
            SizedBox(height: AppSpacing.sm),
            Skeleton(height: 120, width: double.infinity, borderRadius: 16),
            SizedBox(height: AppSpacing.formSectionSpacing),
            Skeleton(height: 24, width: 80),
            SizedBox(height: AppSpacing.sm),
            Skeleton(height: 100, width: double.infinity, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}
