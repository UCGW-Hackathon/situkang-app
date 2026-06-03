import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_bloc.dart';
import 'order_detail_page.dart';

/// Page displaying the user's order history with status filter tabs.
///
/// Shows orders sorted by creation date (newest first) with pagination.
/// Provides status filter tabs to quickly find orders by their current status.
///
/// Validates: Requirements 8.1, 8.2, 8.3
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Status filter options for the tab bar.
  static const _statusFilters = <OrderStatus?>[
    null, // All
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  /// Labels for the status filter tabs.
  static const _statusLabels = <String>[
    'Semua',
    'Menunggu',
    'Diterima',
    'Berlangsung',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initial fetch
    context.read<OrderBloc>().add(const FetchOrdersRequested());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final status = _statusFilters[_tabController.index];
    context.read<OrderBloc>().add(ApplyStatusFilterRequested(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTypography.label,
          unselectedLabelStyle: AppTypography.bodySmall,
          tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const LoadingIndicator();
          }

          if (state is OrderError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                final status = _statusFilters[_tabController.index];
                context.read<OrderBloc>().add(
                      ApplyStatusFilterRequested(status: status),
                    );
              },
            );
          }

          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return _buildEmptyState();
            }
            return _buildOrderList(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: AppSizing.iconXxl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada pesanan',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pesanan Anda akan muncul di sini',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(OrdersLoaded state) {
    return ListView.separated(
      padding: AppSpacing.pagePadding,
      itemCount: state.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final order = state.orders[index];
        return _OrderCard(
          order: order,
          onTap: () {
            context.read<OrderBloc>().add(
                  FetchOrderDetailRequested(orderId: order.id),
                );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<OrderBloc>(),
                  child: OrderDetailPage(orderId: order.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Card widget displaying order summary information.
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onTap,
  });

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: order number + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Title
          Text(
            order.title,
            style: AppTypography.h6,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Worker info
          if (order.workerInfo != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: AppSizing.avatarSm / 2,
                  backgroundImage: order.workerInfo!.avatarUrl != null
                      ? NetworkImage(order.workerInfo!.avatarUrl!)
                      : null,
                  child: order.workerInfo!.avatarUrl == null
                      ? const Icon(Icons.person, size: AppSizing.iconSm)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    order.workerInfo!.fullName,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Service name
          if (order.serviceName != null)
            Text(
              order.serviceName!,
              style: AppTypography.bodySmall,
            ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Bottom: price + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.totalPrice != null)
                Text(
                  'Rp${NumberFormat('#,###', 'id').format(order.totalPrice)}',
                  style: AppTypography.priceMedium,
                )
              else
                Text(
                  'Menunggu harga',
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              Text(
                DateFormat('dd MMM yyyy', 'id').format(order.createdAt),
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status badge showing the order's current status with appropriate color.
class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        _getStatusLabel(),
        style: AppTypography.caption.copyWith(
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor() {
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

  String _getStatusLabel() {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.accepted:
        return 'Diterima';
      case OrderStatus.onTheWay:
        return 'Dalam Perjalanan';
      case OrderStatus.arrived:
        return 'Tiba di Lokasi';
      case OrderStatus.inProgress:
        return 'Sedang Dikerjakan';
      case OrderStatus.workPaused:
        return 'Dijeda';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      case OrderStatus.rejected:
        return 'Ditolak';
    }
  }
}

