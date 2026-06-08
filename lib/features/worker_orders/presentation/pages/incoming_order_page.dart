import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/incoming_order_bloc.dart';
import 'incoming_order_detail_page.dart';

class IncomingOrderPage extends StatefulWidget {
  const IncomingOrderPage({super.key});

  @override
  State<IncomingOrderPage> createState() => _IncomingOrderPageState();
}

class _IncomingOrderPageState extends State<IncomingOrderPage> {
  @override
  void initState() {
    super.initState();
    context.read<IncomingOrderBloc>().add(FetchIncomingOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
      ),
      body: BlocConsumer<IncomingOrderBloc, IncomingOrderState>(
        listener: (context, state) {
          if (state is IncomingOrderActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is IncomingOrderAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan berhasil diterima!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Navigate to active order
            context.pop(); 
          } else if (state is IncomingOrderRejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan telah ditolak'),
              ),
            );
            context.read<IncomingOrderBloc>().add(FetchIncomingOrders());
          }
        },
        builder: (context, state) {
          if (state is IncomingOrderLoading || state is IncomingOrderProcessing) {
            return const LoadingIndicator();
          }

          if (state is IncomingOrderError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context.read<IncomingOrderBloc>().add(FetchIncomingOrders());
              },
            );
          }

          if (state is IncomingOrderEmpty) {
            return const Center(
              child: Text('Belum ada pesanan masuk.'),
            );
          }

          if (state is IncomingOrderExpired) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_off, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Pesanan telah kedaluwarsa', style: AppTypography.h6),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Kembali',
                    onPressed: () {
                      context.pop();
                    },
                  )
                ],
              ),
            );
          }

          if (state is IncomingOrderPending) {
            return _buildPendingOrder(context, state.order, state.remainingSeconds);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPendingOrder(BuildContext context, Order order, int remainingSeconds) {
    final formatter = NumberFormat('#,###', 'id');
    final progress = remainingSeconds / 30.0;
    
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Countdown Timer
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    color: remainingSeconds <= 10 ? AppColors.error : AppColors.primary,
                  ),
                ),
                Text(
                  '$remainingSeconds',
                  style: AppTypography.h3.copyWith(
                    color: remainingSeconds <= 10 ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          const Text('Pesanan Baru!', style: AppTypography.h5, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                      ),
                      child: const Icon(Icons.build, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.title,
                            style: AppTypography.h6,
                          ),
                          Text(
                            order.serviceName ?? 'Jasa Tukang',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                const Row(
                  children: [
                    Icon(Icons.person, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('Pelanggan', style: AppTypography.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    Icon(Icons.location_on,  size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Lokasi Pelanggan',
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order.totalPrice != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.payments, color: AppColors.success, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Estimasi: Rp${formatter.format(order.totalPrice)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Tolak',
                  variant: AppButtonVariant.outline,
                  
                  onPressed: () => _showRejectDialog(context, order.id),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: 'Detail & Terima',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IncomingOrderDetailPage(
                          order: order,
                          remainingSeconds: remainingSeconds,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tolak Pesanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih alasan penolakan:'),
              const SizedBox(height: AppSpacing.sm),
              _buildReasonItem(dialogContext, orderId, 'Sibuk', 'busy'),
              _buildReasonItem(dialogContext, orderId, 'Terlalu Jauh', 'too_far'),
              _buildReasonItem(dialogContext, orderId, 'Bukan Keahlian', 'not_my_expertise'),
              _buildReasonItem(dialogContext, orderId, 'Kendala Pribadi', 'personal'),
              _buildReasonItem(dialogContext, orderId, 'Lainnya', 'other'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReasonItem(BuildContext context, String orderId, String label, String code) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop(); // close dialog
        this.context.read<IncomingOrderBloc>().add(
          RejectIncomingOrder(orderId: orderId, reasonCode: code),
        );
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
