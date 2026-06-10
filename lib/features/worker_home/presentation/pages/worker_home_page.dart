import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../worker_orders/presentation/bloc/incoming_order_bloc.dart';
import '../../domain/entities/worker_dashboard.dart';
import '../bloc/worker_home_bloc.dart';
import '../widgets/incoming_order_overlay.dart';

/// Worker's main dashboard page.
///
/// Displays earnings, statistics, active orders, and allows toggling availability.
class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkerHomeBloc>().add(FetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            BlocConsumer<WorkerHomeBloc, WorkerHomeState>(
              listener: (context, state) {
                if (state is WorkerHomeLoaded) {
                  if (state.actionError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.actionError!.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  if (state.dashboard.incomingOrderCount > 0) {
                    context.read<IncomingOrderBloc>().add(
                      FetchIncomingOrders(),
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state is WorkerHomeLoading) {
                  return const LoadingIndicator();
                }

                if (state is WorkerHomeError) {
                  return AppErrorWidget(
                    message: state.failure.message,
                    onRetry: () {
                      context.read<WorkerHomeBloc>().add(FetchDashboardData());
                    },
                  );
                }

                if (state is WorkerHomeLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WorkerHomeBloc>().add(FetchDashboardData());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context, state.dashboard),
                          const SizedBox(height: AppSpacing.lg),

                          _buildOnlineStatusCard(context, state.dashboard),
                          const SizedBox(height: AppSpacing.lg),

                          _buildGridMenu(context),
                          const SizedBox(height: AppSpacing.lg),

                          _buildWeeklySummary(state.dashboard),
                          const SizedBox(height: AppSpacing.lg),

                          if (state.dashboard.activeOrderId != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildActiveOrderCard(state.dashboard),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            // Incoming Order Overlay Layer
            BlocConsumer<IncomingOrderBloc, IncomingOrderState>(
              listener: (context, incomingState) {
                if (incomingState is IncomingOrderActionError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(incomingState.failure.message)),
                  );
                } else if (incomingState is IncomingOrderAccepted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pesanan berhasil diterima!')),
                  );
                  context.read<WorkerHomeBloc>().add(FetchDashboardData());
                  context.read<IncomingOrderBloc>().add(FetchIncomingOrders());
                  context.go('/worker/orders/${incomingState.orderId}/brief');
                } else if (incomingState is IncomingOrderRejected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pesanan telah ditolak')),
                  );
                  context.read<WorkerHomeBloc>().add(FetchDashboardData());
                  context.read<IncomingOrderBloc>().add(FetchIncomingOrders());
                }
              },
              builder: (context, incomingState) {
                if (incomingState is IncomingOrderPending) {
                  return IncomingOrderOverlay(
                    order: incomingState.order,
                    remainingSeconds: incomingState.remainingSeconds,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkerDashboard dashboard) {
    final authState = context.read<AuthBloc>().state;
    final workerName = authState is Authenticated
        ? authState.user.fullName
        : 'Mitra Pekerja';

    return Row(
      children: [
        const CircleAvatar(
          radius: AppSizing.avatarMd / 2,
          // Menggunakan asset image atau fall back ke icon
          child: Icon(Icons.person, size: AppSizing.iconMd),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workerName,
                style: AppTypography.h5.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Terverifikasi',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Pendapatan Hari Ini',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Rp${NumberFormat('#,###', 'id').format(dashboard.earningsToday)}',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(
                  0xFF1B2C44,
                ), // Warna hitam kebiruan sesuai deskripsi
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnlineStatusCard(
    BuildContext context,
    WorkerDashboard dashboard,
  ) {
    final isOnline = dashboard.isAvailable;

    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.primary : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.power_settings_new : Icons.bedtime,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isOnline ? 'Siap Menerima Order' : 'Sedang Istirahat',
              key: ValueKey(isOnline ? 'title_on' : 'title_off'),
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isOnline
                  ? 'Anda terlihat online oleh pelanggan di sekitar.'
                  : 'Anda sedang tidak terlihat oleh pelanggan.',
              key: ValueKey(isOnline ? 'desc_on' : 'desc_off'),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Switch(
            value: dashboard.isAvailable,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            onChanged: (value) {
              context.read<WorkerHomeBloc>().add(
                ToggleAvailability(isAvailable: value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _buildGridItem(
          icon: Icons.history,
          title: 'Riwayat',
          subtitle: '12 Selesai bulan ini',
          onTap: () => context.go('/worker/orders'),
        ),
        _buildGridItem(
          icon: Icons.support_agent,
          title: 'Pusat Bantuan',
          subtitle: 'Hubungi CS',
          onTap: () => context.push('/help'),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(WorkerDashboard dashboard) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Minggu Ini',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tingkat Penerimaan', style: AppTypography.bodyMedium),
              Text(
                '${(dashboard.acceptanceRate * 100).toInt()}%',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dashboard.acceptanceRate,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rating Rata-rata', style: AppTypography.bodyMedium),
              Row(
                children: [
                  Text(
                    dashboard.averageRating.toStringAsFixed(1),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: AppColors.warning, size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(WorkerDashboard dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pesanan Aktif', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          color: AppColors.primaryContainer,
          onTap: () {
            context.push('/worker/orders/${dashboard.activeOrderId}/brief');
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.activeOrderTitle ?? 'Pekerjaan',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pelanggan: ${dashboard.activeOrderCustomerName ?? "-"}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                      ),
                      child: Text(
                        dashboard.activeOrderStatus ?? 'Berlangsung',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}
