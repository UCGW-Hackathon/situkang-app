import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  Widget _buildFilterChips(String currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.pagePadding,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Selesai'),
            selected: currentFilter == 'completed',
            onSelected: (selected) {
              if (selected) {
                context.read<WorkerHistoryBloc>().add(const FilterWorkerHistory('completed'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Dibatalkan'),
            selected: currentFilter == 'cancelled',
            onSelected: (selected) {
              if (selected) {
                context.read<WorkerHistoryBloc>().add(const FilterWorkerHistory('cancelled'));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pekerjaan'),
      ),
      body: BlocBuilder<WorkerHistoryBloc, WorkerHistoryState>(
        builder: (context, state) {
          if (state.status == WorkerHistoryStatus.initial || 
              (state.status == WorkerHistoryStatus.loading && state.orders.isEmpty)) {
            return Column(
              children: [
                _buildFilterChips(state.filter),
                const Expanded(child: Center(child: LoadingIndicator())),
              ],
            );
          }

          if (state.status == WorkerHistoryStatus.error && state.orders.isEmpty) {
            return Column(
              children: [
                _buildFilterChips(state.filter),
                Expanded(
                  child: AppErrorWidget(
                    message: state.failure?.message ?? 'Terjadi kesalahan',
                    onRetry: () => context.read<WorkerHistoryBloc>().add(FetchWorkerHistory()),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterChips(state.filter),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<WorkerHistoryBloc>().add(FetchWorkerHistory());
                  },
                  child: state.orders.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Belum ada riwayat pesanan.')),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            left: AppSpacing.md,
                            right: AppSpacing.md,
                            bottom: AppSpacing.xl,
                          ),
                          itemCount: state.hasReachedMax
                              ? state.orders.length
                              : state.orders.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= state.orders.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Center(child: LoadingIndicator()),
                              );
                            }
                            
                            final order = state.orders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(order.createdAt),
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              _buildStatusBadge(order.status.name),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(order.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.serviceName ?? 'Jasa Tukang',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pendapatan', style: AppTypography.caption),
                  Text(
                    'Rp${_formatter.format(order.totalPrice ?? 0)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppButton(
                text: 'Detail',
                variant: AppButtonVariant.outline,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka detail pesanan...')));
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = AppColors.success;
        label = 'Selesai';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Dibatalkan';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
