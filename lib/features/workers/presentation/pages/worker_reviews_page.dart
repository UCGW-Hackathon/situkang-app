import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/worker_review.dart';
import '../bloc/worker_detail_bloc.dart';

/// Page displaying all reviews for a worker with pagination and filtering.
///
/// Shows rating distribution breakdown, star filter, and paginated reviews
/// (10 per page) using PaginatedListView.
///
/// Validates:
/// - Requirement 6.5: Paginated review list (10/page), rating distribution,
///   star filter
/// - Requirement 6.7: Error state with retry
/// - Requirement 6.8: Empty reviews state
class WorkerReviewsPage extends StatelessWidget {
  /// Creates a [WorkerReviewsPage].
  const WorkerReviewsPage({
    required this.workerId,
    required this.totalReviews,
    required this.ratingAvg,
    super.key,
  });

  /// The ID of the worker whose reviews to display.
  final String workerId;

  /// Total number of reviews for this worker.
  final int totalReviews;

  /// Average rating of this worker.
  final double ratingAvg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Ulasan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<WorkerDetailBloc, WorkerDetailState>(
        builder: (context, state) {
          return switch (state) {
            WorkerReviewsLoading() => const LoadingIndicator(
                message: 'Memuat ulasan...',
              ),
            WorkerReviewsLoaded(
              :final reviews,
              :final hasMore,
              :final isLoadingMore,
              :final starFilter,
              :final allReviews,
            ) =>
              _ReviewsContent(
                reviews: reviews,
                allReviews: allReviews ?? reviews,
                hasMore: hasMore,
                isLoadingMore: isLoadingMore,
                starFilter: starFilter,
                totalReviews: totalReviews,
                ratingAvg: ratingAvg,
                workerId: workerId,
              ),
            WorkerReviewsError(:final failure) => AppErrorWidget(
                message: failure.message,
                onRetry: () => context
                    .read<WorkerDetailBloc>()
                    .add(FetchWorkerReviews(workerId: workerId)),
              ),
            // Handle other states gracefully
            _ => const LoadingIndicator(),
          };
        },
      ),
    );
  }
}

class _ReviewsContent extends StatelessWidget {
  const _ReviewsContent({
    required this.reviews,
    required this.allReviews,
    required this.hasMore,
    required this.isLoadingMore,
    required this.starFilter,
    required this.totalReviews,
    required this.ratingAvg,
    required this.workerId,
  });

  final List<WorkerReview> reviews;
  final List<WorkerReview> allReviews;
  final bool hasMore;
  final bool isLoadingMore;
  final int? starFilter;
  final int totalReviews;
  final double ratingAvg;
  final String workerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rating distribution header
        _RatingDistributionSection(
          allReviews: allReviews,
          totalReviews: totalReviews,
          ratingAvg: ratingAvg,
        ),
        const Divider(height: 1),
        // Star filter chips
        _StarFilterSection(
          selectedStar: starFilter,
          onFilterChanged: (star) {
            context
                .read<WorkerDetailBloc>()
                .add(FilterReviewsByStar(starRating: star));
          },
        ),
        const Divider(height: 1),
        // Reviews list
        Expanded(
          child: reviews.isEmpty
              ? _EmptyFilteredReviews(starFilter: starFilter)
              : PaginatedListView(
                  itemCount: reviews.length,
                  hasMore: hasMore,
                  isLoadingMore: isLoadingMore,
                  onLoadMore: () {
                    context.read<WorkerDetailBloc>().add(const LoadMoreReviews());
                  },
                  padding: AppSpacing.pagePadding,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return _ReviewListItem(review: reviews[index]);
                  },
                  emptyWidget: _EmptyFilteredReviews(starFilter: starFilter),
                ),
        ),
      ],
    );
  }
}

/// Rating distribution section showing average rating and per-star breakdown.
class _RatingDistributionSection extends StatelessWidget {
  const _RatingDistributionSection({
    required this.allReviews,
    required this.totalReviews,
    required this.ratingAvg,
  });

  final List<WorkerReview> allReviews;
  final int totalReviews;
  final double ratingAvg;

  @override
  Widget build(BuildContext context) {
    // Calculate distribution from available reviews
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in allReviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Average rating display
          Column(
            children: [
              Text(
                ratingAvg.toStringAsFixed(1),
                style: AppTypography.h1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              RatingStars(rating: ratingAvg, size: 18),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$totalReviews ulasan',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          // Distribution bars
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = distribution[star] ?? 0;
                final maxCount = allReviews.isNotEmpty
                    ? distribution.values
                        .reduce((a, b) => a > b ? a : b)
                    : 1;
                final ratio =
                    maxCount > 0 ? count / maxCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.ratingStar,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusXs),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.ratingStar,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: AppTypography.caption,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Star filter section with filter chips for each star rating.
class _StarFilterSection extends StatelessWidget {
  const _StarFilterSection({
    required this.selectedStar,
    required this.onFilterChanged,
  });

  final int? selectedStar;
  final ValueChanged<int?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // "All" chip
          _FilterChip(
            label: 'Semua',
            isSelected: selectedStar == null,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Star chips 5 to 1
          ...List.generate(5, (index) {
            final star = 5 - index;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(
                label: '$star ★',
                isSelected: selectedStar == star,
                onTap: () => onFilterChanged(star),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// A single review item in the full reviews list.
class _ReviewListItem extends StatelessWidget {
  const _ReviewListItem({required this.review});

  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info row
          Row(
            children: [
              CircleAvatar(
                radius: AppSizing.avatarSm / 2,
                backgroundColor: AppColors.border,
                backgroundImage: review.reviewerAvatarUrl != null
                    ? CachedNetworkImageProvider(review.reviewerAvatarUrl!)
                    : null,
                child: review.reviewerAvatarUrl == null
                    ? const Icon(Icons.person, size: AppSizing.iconSm)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: AppTypography.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (review.reviewerLocation != null)
                      Text(
                        review.reviewerLocation!,
                        style: AppTypography.caption,
                      ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy', 'id').format(review.date),
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Rating stars
          RatingStars(rating: review.rating.toDouble(), size: 16),
          // Comment
          if (review.comment != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment!,
              style: AppTypography.bodyMedium,
            ),
          ],
          // Tags
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: review.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSizing.radiusXs),
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state when no reviews match the current filter.
///
/// Validates: Requirement 6.8.
class _EmptyFilteredReviews extends StatelessWidget {
  const _EmptyFilteredReviews({this.starFilter});

  final int? starFilter;

  @override
  Widget build(BuildContext context) {
    final message = starFilter != null
        ? 'Tidak ada ulasan dengan $starFilter bintang'
        : 'Belum ada ulasan';

    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: AppSizing.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
