import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/slide_to_accept_button.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../worker_orders/presentation/bloc/incoming_order_bloc.dart';

class IncomingOrderOverlay extends StatelessWidget {
  const IncomingOrderOverlay({
    required this.order, required this.remainingSeconds, super.key,
  });

  final Order order;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        
        // Centered Dialog
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Order Baru Masuk!',
                            style: AppTypography.h6.copyWith(color: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003C4A), // Darker teal
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '00:${remainingSeconds.toString().padLeft(2, '0')}',
                                  style: AppTypography.caption.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Body
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE0E0), // Light pink
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.build, color: AppColors.error, size: 28),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.title,
                                      style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      order.serviceName ?? 'Perbaikan / Jasa Tukang',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: AppSpacing.lg),
                          
                          Text(
                            'Deskripsi Pekerjaan:',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            order.title, // using title as description fallback since model lacks description
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Location Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Jarak ke lokasi:',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Text(
                                  '1.5 km', // Placeholder, map actual distance if available
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          Center(
                            child: Text(
                              'Pelanggan sedang menunggu konfirmasi Anda.',
                              style: AppTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          SlideToAcceptButton(
                            onAccept: () {
                              context.read<IncomingOrderBloc>().add(
                                AcceptIncomingOrder(orderId: order.id, estimatedArrivalMinutes: 15),
                              );
                              // We also pop to handle any internal navigation if needed,
                              // but since it's an overlay layer managed by Bloc, 
                              // the state will change to Accepted and the overlay will disappear!
                              // We might want to navigate to the order active screen though.
                              // Wait, worker_home_page.dart's BlocListener will handle navigation if we put it there.
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
