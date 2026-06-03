import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/worker_dashboard.dart';
import '../bloc/worker_home_bloc.dart';

/// Worker's main dashboard page.
///
/// Displays earnings, statistics, active orders, and allows toggling availability.
class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({
    super.key,
  });
  

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
      body: SafeArea(
        child: BlocConsumer<WorkerHomeBloc, WorkerHomeState>(
          listener: (context, state) {
            if (state is WorkerHomeLoaded && state.actionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionError!.message),
                  backgroundColor: AppColors.error,
                ),
              );
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, state.dashboard),
                      const SizedBox(height: AppSpacing.lg),
                      
                      _buildEarningsCards(state.dashboard),
                      const SizedBox(height: AppSpacing.lg),
                      
                      _buildWeeklySummary(state.dashboard),
                      const SizedBox(height: AppSpacing.lg),

                      if (state.dashboard.incomingOrderCount > 0)
                        _buildIncomingOrderBanner(state.dashboard.incomingOrderCount),
                      
                      if (state.dashboard.activeOrderId != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildActiveOrderCard(state.dashboard),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      _buildQuickMenu(context),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkerDashboard dashboard) {
    return Row(
      children: [
        CircleAvatar(
          radius: AppSizing.avatarMd / 2,
          backgroundImage: '' != null
              ? NetworkImage(''!)
              : null,
          child: '' == null
              ? const Icon(Icons.person, size: AppSizing.iconMd)
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Tukang',
                    style: AppTypography.h6,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (VerificationStatus.verified == VerificationStatus.verified)
                    const Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: AppSizing.iconSm,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Saldo: Rp${NumberFormat('#,###', 'id').format(dashboard.walletBalance)}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Switch(
              value: dashboard.isAvailable,
              activeColor: AppColors.primary,
              onChanged: (value) {
                context
                    .read<WorkerHomeBloc>()
                    .add(ToggleAvailability(isAvailable: value));
              },
            ),
            Text(
              dashboard.isAvailable ? 'Tersedia' : 'Sibuk',
              style: AppTypography.caption.copyWith(
                color: dashboard.isAvailable
                    ? AppColors.success
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsCards(WorkerDashboard dashboard) {
    final formatter = NumberFormat('#,###', 'id');
    
    return Row(
      children: [
        Expanded(
          child: _buildEarningItem(
            'Hari Ini',
            'Rp${formatter.format(dashboard.earningsToday)}',
            Icons.today,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildEarningItem(
            'Minggu Ini',
            'Rp${formatter.format(dashboard.earningsWeek)}',
            Icons.date_range,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningItem(
      String title, String amount, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizing.iconMd),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(WorkerDashboard dashboard) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performa Mingguan', style: AppTypography.h6),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Penerimaan',
                '${(dashboard.acceptanceRate * 100).toInt()}%',
                Icons.thumb_up_outlined,
              ),
              _buildStatItem(
                'Rating',
                dashboard.averageRating.toStringAsFixed(1),
                Icons.star_outline,
              ),
              _buildStatItem(
                'Selesai',
                '${dashboard.jobsCompleted}',
                Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.h5),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildIncomingOrderBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Ada $count pesanan baru masuk!',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                
              ),
            ),
          ),
          AppButton(
            text: 'Lihat',
            
            
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka pesanan masuk...')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(WorkerDashboard dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pesanan Aktif', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          color: AppColors.primaryContainer,
          onTap: () {
            context.push(
              '/worker/orders',
              extra: Order(
                id: dashboard.activeOrderId!,
                orderNumber: dashboard.activeOrderId!,
                title: dashboard.activeOrderTitle ?? 'Pekerjaan',
                status: OrderStatus.fromString(
                  dashboard.activeOrderStatus ?? 'accepted',
                ),
                createdAt: dashboard.activeOrderStartTime ?? DateTime.now(),
              ),
            );
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

  Widget _buildQuickMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Cepat', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMenuItem(
              icon: Icons.history,
              label: 'Riwayat',
              onTap: () {
                context.push('/worker/history');
              },
            ),
            _buildMenuItem(
              icon: Icons.account_balance_wallet,
              label: 'Tarik Dana',
              onTap: () {
                context.push('/worker/wallet');
              },
            ),
            _buildMenuItem(
              icon: Icons.person_outline,
              label: 'Profil & Jasa',
              onTap: () {
                context.push('/worker/profile');
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              label: 'Bantuan',
              onTap: () {
                context.push('/help');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
