import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/wallet_bloc.dart';
import 'transaction_history_page.dart';
import 'withdrawal_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final NumberFormat _formatter = NumberFormat('#,###', 'id');

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchWalletSummary());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Tukang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
              );
            },
          )
        ],
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.summaryStatus == WalletStatus.error && state.summary == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure?.message ?? 'Terjadi kesalahan'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.summaryStatus == WalletStatus.loading && state.summary == null) {
            return const Center(child: LoadingIndicator());
          }

          if (state.summaryStatus == WalletStatus.error && state.summary == null) {
            return AppErrorWidget(
              message: state.failure?.message ?? 'Gagal memuat data dompet',
              onRetry: () => context.read<WalletBloc>().add(FetchWalletSummary()),
            );
          }

          final summary = state.summary;
          if (summary == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(FetchWalletSummary());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Balance Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Tersedia',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Rp${_formatter.format(summary.availableBalance)}',
                          style: AppTypography.h3.copyWith(color: AppColors.onPrimary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          text: 'Tarik Dana',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WithdrawalPage(
                                  availableBalance: summary.availableBalance,
                                ),
                              ),
                            );
                          },
                          // Custom styling for button on primary bg
                          // AppButton doesn't accept color, use variant if needed
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  Text('Ringkasan Keuangan', style: AppTypography.h6),
                  const SizedBox(height: AppSpacing.md),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.5,
                    children: [
                      _buildSummaryCard(
                        title: 'Total Pendapatan',
                        value: summary.totalEarnings,
                        icon: Icons.account_balance_wallet,
                        color: AppColors.primary,
                      ),
                      _buildSummaryCard(
                        title: 'Total Ditarik',
                        value: summary.totalWithdrawn,
                        icon: Icons.money_off,
                        color: AppColors.error,
                      ),
                      _buildSummaryCard(
                        title: 'Pendapatan Tertunda',
                        value: summary.pendingEarnings,
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Quick Actions
                  AppCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                          ),
                          child: const Icon(Icons.history, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Riwayat Transaksi', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              const Text('Lihat detail pemasukan dan penarikan', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Rp${_formatter.format(value)}',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
