import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/paginated_list_view.dart';
import '../../domain/entities/worker_filter.dart';
import '../bloc/worker_list_bloc.dart';
import '../widgets/worker_card.dart';

/// Page displaying nearby workers with search, filter, and sort capabilities.
///
/// Features:
/// 1. Search field at top for name/specialization/service type search
/// 2. Filter chips (category, min rating)
/// 3. Sort dropdown (distance, rating, price, completed_jobs)
/// 4. Worker list with infinite scroll (10 per page)
/// 5. Empty state when no workers match
/// 6. Location unavailable state
///
/// Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9.
class NearbyWorkersPage extends StatefulWidget {
  /// Creates a [NearbyWorkersPage].
  const NearbyWorkersPage({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<NearbyWorkersPage> createState() => _NearbyWorkersPageState();
}

class _NearbyWorkersPageState extends State<NearbyWorkersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId == null) {
      context.read<WorkerListBloc>().add(const FetchWorkers());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tukang Terdekat'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterAndSortBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Builds the search field at the top of the page.
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: AppTextField(
        controller: _searchController,
        hint: 'Cari nama, spesialisasi, atau layanan...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: BlocBuilder<WorkerListBloc, WorkerListState>(
          builder: (context, state) {
            final hasSearch = _searchController.text.isNotEmpty;
            if (!hasSearch) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<WorkerListBloc>().add(
                      const SearchWorkers(keyword: ''),
                    );
              },
            );
          },
        ),
        onChanged: (value) {
          context.read<WorkerListBloc>().add(
                SearchWorkers(keyword: value),
              );
        },
      ),
    );
  }

  /// Builds the filter chips and sort dropdown row.
  Widget _buildFilterAndSortBar() {
    return BlocBuilder<WorkerListBloc, WorkerListState>(
      buildWhen: (previous, current) {
        // Only rebuild when filter changes
        if (current is WorkerListLoaded && previous is WorkerListLoaded) {
          return current.filter != previous.filter;
        }
        return true;
      },
      builder: (context, state) {
        final filter = state is WorkerListLoaded
            ? state.filter
            : const WorkerFilter();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(child: _buildFilterChips(filter)),
              const SizedBox(width: AppSpacing.sm),
              _buildSortDropdown(filter.sortBy),
            ],
          ),
        );
      },
    );
  }

  /// Builds the filter chips for category and rating.
  Widget _buildFilterChips(WorkerFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip(filter),
          const SizedBox(width: AppSpacing.sm),
          _buildRatingChip(filter),
        ],
      ),
    );
  }

  /// Builds the category filter chip.
  Widget _buildCategoryChip(WorkerFilter filter) {
    final isActive = filter.categoryId != null;
    return FilterChip(
      label: Text(isActive ? 'Kategori ✓' : 'Kategori'),
      selected: isActive,
      onSelected: (_) => _showCategoryFilterDialog(filter),
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.primary,
    );
  }

  /// Builds the minimum rating filter chip.
  Widget _buildRatingChip(WorkerFilter filter) {
    final isActive = filter.minRating != null;
    return FilterChip(
      label: Text(
        isActive
            ? 'Rating ≥ ${filter.minRating!.toStringAsFixed(1)}'
            : 'Rating',
      ),
      selected: isActive,
      onSelected: (_) => _showRatingFilterDialog(filter),
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.primary,
    );
  }

  /// Builds the sort dropdown button.
  Widget _buildSortDropdown(WorkerSortBy currentSort) {
    return PopupMenuButton<WorkerSortBy>(
      initialValue: currentSort,
      onSelected: (sortBy) {
        context.read<WorkerListBloc>().add(ChangeSort(sortBy: sortBy));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: WorkerSortBy.distance,
          child: Text('Jarak Terdekat'),
        ),
        const PopupMenuItem(
          value: WorkerSortBy.rating,
          child: Text('Rating Tertinggi'),
        ),
        const PopupMenuItem(
          value: WorkerSortBy.price,
          child: Text('Harga Terendah'),
        ),
        const PopupMenuItem(
          value: WorkerSortBy.completedJobs,
          child: Text('Pekerjaan Terbanyak'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: AppSizing.iconSm,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _getSortLabel(currentSort),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_drop_down,
              size: AppSizing.iconSm,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main body content based on the current state.
  Widget _buildBody() {
    return BlocBuilder<WorkerListBloc, WorkerListState>(
      builder: (context, state) {
        return switch (state) {
          WorkerListInitial() => const SizedBox.shrink(),
          WorkerListLoading() => const LoadingIndicator(
              message: 'Mencari tukang terdekat...',
            ),
          WorkerListLoaded() => _buildWorkerList(state),
          WorkerListError() => _buildErrorState(state),
        };
      },
    );
  }

  /// Builds the worker list with infinite scroll pagination.
  Widget _buildWorkerList(WorkerListLoaded state) {
    if (state.workers.isEmpty) {
      return _buildEmptyState(state.filter);
    }

    return PaginatedListView(
      itemCount: state.workers.length,
      hasMore: state.hasMore,
      isLoadingMore: state.isLoadingMore,
      onLoadMore: () {
        context.read<WorkerListBloc>().add(const LoadMore());
      },
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final worker = state.workers[index];
        return WorkerCard(
          worker: worker,
          onTap: () => _onWorkerTapped(worker.id),
        );
      },
    );
  }

  /// Builds the empty state when no workers match filters.
  ///
  /// Validates: Requirement 5.8.
  Widget _buildEmptyState(WorkerFilter filter) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppSizing.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ada tukang ditemukan',
              style: AppTypography.h6.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coba sesuaikan filter atau perluas radius pencarian',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (filter.hasActiveFilters) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Hapus Semua Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the error state with retry option.
  Widget _buildErrorState(WorkerListError state) {
    // Check if it's a location-related error
    if (_isLocationError(state.failure)) {
      return _buildLocationUnavailableState();
    }

    return AppErrorWidget(
      message: state.failure.message,
      onRetry: () {
        context.read<WorkerListBloc>().add(const FetchWorkers());
      },
    );
  }

  /// Builds the location unavailable state.
  ///
  /// Validates: Requirement 5.9.
  Widget _buildLocationUnavailableState() {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: AppSizing.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Lokasi Tidak Tersedia',
              style: AppTypography.h6.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aktifkan akses lokasi untuk menemukan tukang terdekat',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: () {
                context.read<WorkerListBloc>().add(const FetchWorkers());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the category filter dialog.
  void _showCategoryFilterDialog(WorkerFilter filter) {
    // Category IDs and labels for the SITUKANG categories
    final categories = <String, String>{
      'ac': 'AC',
      'pipa': 'Pipa',
      'atap': 'Atap',
      'listrik': 'Listrik',
      'kunci': 'Kunci',
      'kayu': 'Kayu',
      'cat': 'Cat',
      'kebun': 'Kebun',
    };

    showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Pilih Kategori'),
          children: [
            // Option to clear category filter
            if (filter.categoryId != null)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, ''),
                child: const Text(
                  'Semua Kategori',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ...categories.entries.map(
              (entry) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, entry.key),
                child: Row(
                  children: [
                    Text(entry.value),
                    if (filter.categoryId == entry.key)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(
                          Icons.check,
                          size: AppSizing.iconSm,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ).then((selectedCategory) {
      if (selectedCategory == null) return;
      if (!mounted) return;

      final bloc = context.read<WorkerListBloc>();
      if (selectedCategory.isEmpty) {
        // Clear category filter
        bloc.add(ApplyFilter(
          filter: filter.clearFields(categoryId: true),
        ));
      } else {
        bloc.add(ApplyFilter(
          filter: filter.copyWith(categoryId: selectedCategory),
        ));
      }
    });
  }

  /// Shows the rating filter dialog.
  void _showRatingFilterDialog(WorkerFilter filter) {
    final ratings = [1.0, 2.0, 3.0, 3.5, 4.0, 4.5];

    showDialog<double?>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Rating Minimum'),
          children: [
            // Option to clear rating filter
            if (filter.minRating != null)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, 0.0),
                child: const Text(
                  'Semua Rating',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ...ratings.map(
              (rating) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, rating),
                child: Row(
                  children: [
                    Text('≥ ${rating.toStringAsFixed(1)}'),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.star,
                      size: AppSizing.iconSm,
                      color: AppColors.ratingStar,
                    ),
                    if (filter.minRating == rating)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(
                          Icons.check,
                          size: AppSizing.iconSm,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ).then((selectedRating) {
      if (selectedRating == null) return;
      if (!mounted) return;

      final bloc = context.read<WorkerListBloc>();
      if (selectedRating == 0.0) {
        // Clear rating filter
        bloc.add(ApplyFilter(
          filter: filter.clearFields(minRating: true),
        ));
      } else {
        bloc.add(ApplyFilter(
          filter: filter.copyWith(minRating: selectedRating),
        ));
      }
    });
  }

  /// Clears all active filters and re-fetches workers.
  void _clearAllFilters() {
    _searchController.clear();
    context.read<WorkerListBloc>().add(
          const ApplyFilter(filter: WorkerFilter()),
        );
  }

  /// Handles tapping on a worker card.
  void _onWorkerTapped(String workerId) {
    context.push('/workers/$workerId');
  }

  /// Returns the display label for a sort criterion.
  String _getSortLabel(WorkerSortBy sortBy) {
    return switch (sortBy) {
      WorkerSortBy.distance => 'Jarak',
      WorkerSortBy.rating => 'Rating',
      WorkerSortBy.price => 'Harga',
      WorkerSortBy.completedJobs => 'Pekerjaan',
    };
  }

  /// Checks if a failure is related to location being unavailable.
  bool _isLocationError(Failure failure) {
    final message = failure.message.toLowerCase();
    return message.contains('lokasi') ||
        message.contains('location') ||
        message.contains('gps');
  }
}
