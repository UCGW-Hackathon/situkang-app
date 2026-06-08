import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/worker_statistics_bloc.dart';

class WorkerStatisticsPage extends StatefulWidget {
  const WorkerStatisticsPage({super.key});

  @override
  State<WorkerStatisticsPage> createState() => _WorkerStatisticsPageState();
}

class _WorkerStatisticsPageState extends State<WorkerStatisticsPage> {
  final NumberFormat _formatter = NumberFormat('#,###', 'id');
  String _selectedRange = 'month'; // week, month, year, all

  @override
  void initState() {
    super.initState();
    context.read<WorkerStatisticsBloc>().add(FetchWorkerStatistics(_selectedRange));
  }

  void _onRangeChanged(String newRange) {
    setState(() => _selectedRange = newRange);
    context.read<WorkerStatisticsBloc>().add(FetchWorkerStatistics(newRange));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Pekerjaan'),
      ),
      body: BlocConsumer<WorkerStatisticsBloc, WorkerStatisticsState>(
        listener: (context, state) {
          if (state is WorkerStatisticsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WorkerStatisticsBloc>().add(FetchWorkerStatistics(_selectedRange));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Range Selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'week', label: Text('Minggu')),
                      ButtonSegment(value: 'month', label: Text('Bulan')),
                      ButtonSegment(value: 'year', label: Text('Tahun')),
                      ButtonSegment(value: 'all', label: Text('Semua')),
                    ],
                    selected: {_selectedRange},
                    onSelectionChanged: (Set<String> newSelection) {
                      _onRangeChanged(newSelection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (state is WorkerStatisticsLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(child: LoadingIndicator()),
                    )
                  else if (state is WorkerStatisticsError)
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: AppErrorWidget(
                        message: state.failure.message,
                        onRetry: () => _onRangeChanged(_selectedRange),
                      ),
                    )
                  else if (state is WorkerStatisticsLoaded)
                    _buildStatisticsContent(state.statistics)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsContent(dynamic statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Earnings Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          ),
          child: Column(
            children: [
              Text(
                'Total Pendapatan',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Rp${_formatter.format(statistics.totalEarnings)}',
                style: AppTypography.h3.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Grid Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              title: 'Pekerjaan Selesai',
              value: '${statistics.totalJobsCompleted}',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            _buildStatCard(
              title: 'Rating Rata-rata',
              value: (statistics.averageRating as num).toStringAsFixed(1),
              icon: Icons.star,
              color: AppColors.warning,
            ),
            _buildStatCard(
              title: 'Tingkat Pembatalan',
              value: '${(statistics.cancellationRate * 100).toStringAsFixed(1)}%',
              icon: Icons.cancel,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        
        const Text('Grafik Pendapatan', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.md),
        
        // Placeholder for chart
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: AppColors.textSecondary),
                SizedBox(height: AppSpacing.sm),
                Text('Grafik akan tampil di sini', style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.h5),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
