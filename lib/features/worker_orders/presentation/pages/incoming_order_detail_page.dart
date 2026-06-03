import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/incoming_order_bloc.dart';

class IncomingOrderDetailPage extends StatefulWidget {
  const IncomingOrderDetailPage({
    super.key,
    required this.order,
    required this.remainingSeconds,
  });

  final Order order;
  final int remainingSeconds;

  @override
  State<IncomingOrderDetailPage> createState() => _IncomingOrderDetailPageState();
}

class _IncomingOrderDetailPageState extends State<IncomingOrderDetailPage> {
  int _estimatedArrival = 30; // Default 30 mins

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan Masuk'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(
                '00:${widget.remainingSeconds.toString().padLeft(2, '0')}',
                style: AppTypography.h6.copyWith(
                  color: widget.remainingSeconds <= 10 ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dummy map placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/600x200.png?text=Map+View'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                  ),
                  child: const Text('2.5 km dari lokasi Anda', style: AppTypography.caption),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(widget.order.title, style: AppTypography.h5),
            Text(widget.order.serviceName ?? 'Jasa Tukang', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: AppSpacing.sm),
                Text('Pelanggan', style: AppTypography.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Lokasi Pelanggan', style: AppTypography.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            
            Text('Deskripsi Keluhan', style: AppTypography.h6),
            const SizedBox(height: AppSpacing.sm),
            Text(widget.order.title),
            
            const SizedBox(height: AppSpacing.lg),
            
            if (widget.order.totalPrice != null) ...[
              AppCard(
                color: AppColors.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimasi Biaya', style: AppTypography.bodyMedium),
                    Text(
                      'Rp${formatter.format(widget.order.totalPrice)}',
                      style: AppTypography.h6.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            Text('Estimasi Waktu Tiba', style: AppTypography.h6),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _estimatedArrival.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23, // Every 5 mins
                    label: '$_estimatedArrival menit',
                    onChanged: (val) {
                      setState(() {
                        _estimatedArrival = val.toInt();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text('$_estimatedArrival menit', style: AppTypography.bodyMedium),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Accept Button
            AppButton(
              text: 'Terima Pesanan',
              onPressed: () {
                context.read<IncomingOrderBloc>().add(
                  AcceptIncomingOrder(
                    orderId: widget.order.id,
                    estimatedArrivalMinutes: _estimatedArrival,
                  ),
                );
                // The parent IncomingOrderPage's BlocConsumer will handle the success and pop.
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Batal',
              variant: AppButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
