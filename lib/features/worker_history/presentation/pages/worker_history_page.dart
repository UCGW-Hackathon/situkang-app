import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/worker_history_bloc.dart';

class WorkerHistoryPage extends StatefulWidget {
  const WorkerHistoryPage({super.key});

  @override
  State<WorkerHistoryPage> createState() => _WorkerHistoryPageState();
}

class _WorkerHistoryPageState extends State<WorkerHistoryPage> {
  final _scrollController = ScrollController();
  final NumberFormat _formatter = NumberFormat('#,###', 'id');

  int _selectedIndex = 0;

  static const _statusFilters = <OrderStatus?>[
    null, // Semua
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

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
    context.read<WorkerHistoryBloc>().add(FetchWorkerHistory());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WorkerHistoryBloc>().add(LoadMoreWorkerHistory());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  void _onFilterSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    final status = _statusFilters[index];
    context.read<WorkerHistoryBloc>().add(FilterWorkerHistory(status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F8FC,
      ), // Light blue-grey background matching user UI
      appBar: AppBar(
        title: const Text('Riwayat Pekerjaan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A202C),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A202C)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Filter Row
            BlocBuilder<WorkerHistoryBloc, WorkerHistoryState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_statusLabels.length, (
                              index,
                            ) {
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
                );
              },
            ),

            // List View
            Expanded(
              child: BlocBuilder<WorkerHistoryBloc, WorkerHistoryState>(
                builder: (context, state) {
                  if (state.status == WorkerHistoryStatus.initial ||
                      (state.status == WorkerHistoryStatus.loading &&
                          state.orders.isEmpty)) {
                    return const _OrderListSkeleton();
                  }

                  if (state.status == WorkerHistoryStatus.error &&
                      state.orders.isEmpty) {
                    return AppErrorWidget(
                      message: state.failure?.message ?? 'Terjadi kesalahan',
                      onRetry: () => context.read<WorkerHistoryBloc>().add(
                        FetchWorkerHistory(),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WorkerHistoryBloc>().add(
                        FetchWorkerHistory(),
                      );
                    },
                    child: state.orders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: state.hasReachedMax
                                ? state.orders.length
                                : state.orders.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= state.orders.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  child: Center(child: LoadingIndicator()),
                                );
                              }

                              final order = state.orders[index];
                              return _OrderCard(
                                order: order,
                                formatter: _formatter,
                                onTap: () {
                                  context
                                      .push('/worker/orders/${order.id}/brief')
                                      .then((_) {
                                        if (!context.mounted) return;
                                        final status =
                                            _statusFilters[_selectedIndex];
                                        context.read<WorkerHistoryBloc>().add(
                                          FilterWorkerHistory(status),
                                        );
                                      });
                                },
                              );
                            },
                          ),
                  );
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
              'Riwayat pekerjaan Anda akan muncul di sini',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget displaying order summary information matching the design.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.formatter, this.onTap});

  final Order order;
  final NumberFormat formatter;
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
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2F4), // Light teal background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: const Color(0xFF006B5E), // Dark teal icon
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Middle Column (Title & Service Name)
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
                        order.serviceName ?? 'Jasa Tukang',
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

                // Right Column (Price & Status)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.totalPrice != null
                          ? 'Rp ${formatter.format(order.totalPrice)}'
                          : '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                Text(
                  DateFormat('MMM dd, yyyy').format(order.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 13,
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
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 13,
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
