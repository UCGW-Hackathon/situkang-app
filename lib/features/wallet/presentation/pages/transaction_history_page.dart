import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/wallet_entities.dart';
import '../bloc/wallet_bloc.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final _scrollController = ScrollController();
  final NumberFormat _formatter = NumberFormat('#,###', 'id');

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchWalletTransactions());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WalletBloc>().add(LoadMoreWalletTransactions());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  Widget _buildFilterChips(String? currentType) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.pagePadding,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: currentType == null,
            onSelected: (selected) {
              if (selected) {
                context.read<WalletBloc>().add(const FilterWalletTransactions());
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Pendapatan'),
            selected: currentType == 'earning',
            onSelected: (selected) {
              if (selected) {
                context.read<WalletBloc>().add(const FilterWalletTransactions(type: 'earning'));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Penarikan'),
            selected: currentType == 'withdrawal',
            onSelected: (selected) {
              if (selected) {
                context.read<WalletBloc>().add(const FilterWalletTransactions(type: 'withdrawal'));
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
        title: const Text('Riwayat Transaksi'),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.transactionsStatus == WalletStatus.initial || 
              (state.transactionsStatus == WalletStatus.loading && state.transactions.isEmpty)) {
            return Column(
              children: [
                _buildFilterChips(state.filterType),
                const Expanded(child: Center(child: LoadingIndicator())),
              ],
            );
          }

          if (state.transactionsStatus == WalletStatus.error && state.transactions.isEmpty) {
            return Column(
              children: [
                _buildFilterChips(state.filterType),
                Expanded(
                  child: AppErrorWidget(
                    message: state.failure?.message ?? 'Terjadi kesalahan',
                    onRetry: () => context.read<WalletBloc>().add(FetchWalletTransactions()),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterChips(state.filterType),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<WalletBloc>().add(FetchWalletTransactions());
                  },
                  child: state.transactions.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Belum ada riwayat transaksi.')),
                          ],
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            left: AppSpacing.md,
                            right: AppSpacing.md,
                            bottom: AppSpacing.xl,
                          ),
                          itemCount: state.hasReachedMax
                              ? state.transactions.length
                              : state.transactions.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index >= state.transactions.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Center(child: LoadingIndicator()),
                              );
                            }
                            
                            final tx = state.transactions[index];
                            return _buildTransactionCard(tx);
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

  Widget _buildTransactionCard(WalletTransaction tx) {
    final isEarning = tx.type == 'earning';
    final sign = isEarning ? '+' : '-';
    final amountColor = isEarning ? AppColors.success : AppColors.error;
    final icon = isEarning ? Icons.arrow_downward : Icons.arrow_upward;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            ),
            child: Icon(icon, color: amountColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildStatusText(tx.status),
              ],
            ),
          ),
          Text(
            '$sign Rp${_formatter.format(tx.amount)}',
            style: AppTypography.bodyMedium.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = AppColors.success;
        label = 'Selesai';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'Tertunda';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Gagal';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
        break;
    }

    return Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.bold));
  }
}
