import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_filter.dart';
import '../bloc/order_bloc.dart';
import '../widgets/order_progress_icon.dart';
import 'order_detail_page.dart';

/// Page displaying the user's order history with status filter tabs.
///
/// Shows orders sorted by creation date (newest first) with pagination.
/// Matches the provided design reference.
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  int _selectedIndex = 0;
  List<Order>? _cachedOrders;

  /// Status filter options for the tabs.
  static const _statusFilters = <OrderStatus?>[
    null, // Semua
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  /// Labels for the tabs matching the design reference aesthetic.
  static const _statusLabels = <String>[
    'Semua',
    'Menunggu',
    'Diterima',
    'Berjalan',
    'Selesai',
    'Batal',
  ];

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const FetchOrdersRequested());
  }

  void _onFilterSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _cachedOrders = null;
    });
    final status = _statusFilters[index];
    context.read<OrderBloc>().add(ApplyStatusFilterRequested(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F8FC,
      ), // Light blue-grey background from design
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Filter Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_statusLabels.length, (index) {
                          final isSelected = _selectedIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _onFilterSelected(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF006B5E)
                                      : const Color(0xFFDEE8F5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  _statusLabels[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF4A5568),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Icon Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDEE8F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Color(0xFF1A202C),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Order History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List View
            Expanded(
              child: BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  if (state is OrdersLoaded) {
                    _cachedOrders = state.orders;
                  }

                  if (state is OrderLoading && _cachedOrders == null) {
                    return const _OrderListSkeleton();
                  }

                  if (state is OrderError && _cachedOrders == null) {
                    return AppErrorWidget(
                      message: state.failure.message,
                      onRetry: () {
                        final status = _statusFilters[_selectedIndex];
                        context.read<OrderBloc>().add(
                          ApplyStatusFilterRequested(status: status),
                        );
                      },
                    );
                  }

                  if (_cachedOrders != null) {
                    if (_cachedOrders!.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildOrderList(_cachedOrders!);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
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
            const Icon(
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
            const Text(
              'Pesanan Anda akan muncul di sini',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider<OrderBloc>(
                      create: (_) => getIt<OrderBloc>()
                        ..add(FetchOrderDetailRequested(orderId: order.id)),
                      child: OrderDetailPage(orderId: order.id),
                    ),
                  ),
                )
                .then((_) {
                  if (!context.mounted) return;
                  final status = _statusFilters[_selectedIndex];
                  context.read<OrderBloc>().add(
                    FetchOrdersRequested(filter: OrderFilter(status: status)),
                  );
                });
          },
        );
      },
    );
  }
}

/// Card widget displaying order summary information matching the design.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.onTap});

  final Order order;
  final VoidCallback? onTap;

  IconData _getServiceIcon(String? title) {
    final t = title?.toLowerCase() ?? '';
    if (t.contains('pipe') || t.contains('plumb')) return Icons.plumbing;
    if (t.contains('ac') || t.contains('air')) return Icons.ac_unit;
    if (t.contains('paint') || t.contains('wall')) return Icons.format_paint;
    if (t.contains('door') || t.contains('hinge')) return Icons.door_front_door;
    if (t.contains('electric')) return Icons.electrical_services;
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final iconData = _getServiceIcon(order.title);

    // Provide a default time range if completed, else show placeholder
    final timeStr = order.status == OrderStatus.completed
        ? '${DateFormat('HH:mm').format(order.createdAt)} - ${DateFormat('HH:mm').format(order.createdAt.add(const Duration(minutes: 90)))}'
        : 'Full Day';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderProgressIcon(status: order.status, icon: iconData),
                const SizedBox(width: 16),

                // Middle Column (Title & Worker)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.workerInfo?.fullName ?? 'Worker Assigned',
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Row (Date & Time)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFFA0AEC0),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('•', style: TextStyle(color: Color(0xFFA0AEC0))),
                ),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFFA0AEC0),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(
                  _getStatusLabel(order.status).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFF7B8490);
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
      case OrderStatus.inProgress:
      case OrderStatus.workPaused:
        return const Color(0xFF2563EB);
      case OrderStatus.waitingPayment:
        return const Color(0xFF2563EB);
      case OrderStatus.paid:
        return const Color(0xFF00AA13);
      case OrderStatus.completed:
        return const Color(0xFF00AA13);
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.accepted:
        return 'Diterima';
      case OrderStatus.onTheWay:
        return 'Menuju';
      case OrderStatus.arrived:
        return 'Tiba';
      case OrderStatus.inProgress:
        return 'Dikerjakan';
      case OrderStatus.workPaused:
        return 'Jeda';
      case OrderStatus.waitingPayment:
        return 'Menunggu Bayar';
      case OrderStatus.paid:
        return 'Sudah Dibayar';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Batal';
      case OrderStatus.rejected:
        return 'Ditolak';
    }
  }
}

class _OrderListSkeleton extends StatelessWidget {
  const _OrderListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 48, height: 48, borderRadius: 12),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(height: 16, width: 120),
                          SizedBox(height: 8),
                          Skeleton(height: 14, width: 80),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Skeleton(height: 16, width: 70),
                        SizedBox(height: 8),
                        Skeleton(height: 10, width: 50),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Skeleton(height: 16, width: 16, shape: BoxShape.circle),
                    SizedBox(width: 6),
                    Skeleton(height: 13, width: 80),
                    SizedBox(width: 20),
                    Skeleton(height: 16, width: 16, shape: BoxShape.circle),
                    SizedBox(width: 6),
                    Skeleton(height: 13, width: 80),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
