import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_review.dart';
import '../../domain/entities/worker_service.dart';
import '../bloc/worker_detail_bloc.dart';

/// Page displaying the full detail of a worker's profile.
///
/// Shows cover photo, worker info, services list, recent reviews,
/// and a fixed bottom bar with booking fee and booking button.
///
/// Validates:
/// - Requirement 6.1: Full worker profile info
/// - Requirement 6.2: Services list with name, icon, base price, price unit
/// - Requirement 6.3: Up to 3 recent reviews
/// - Requirement 6.4: Booking fee (Rp2.000) in fixed bottom section
/// - Requirement 6.6: Booking action button navigates to order creation
/// - Requirement 6.7: Error state with retry
/// - Requirement 6.8: Empty reviews state
class WorkerDetailPage extends StatelessWidget {
  /// Creates a [WorkerDetailPage].
  const WorkerDetailPage({
    required this.workerId,
    super.key,
    this.onBookNow,
    this.onViewAllReviews,
  });

  /// The ID of the worker to display.
  final String workerId;

  /// Callback when the "Pesan Sekarang" button is tapped.
  final ValueChanged<WorkerProfile>? onBookNow;

  /// Callback when "Lihat Semua Ulasan" is tapped.
  final VoidCallback? onViewAllReviews;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WorkerDetailBloc, WorkerDetailState>(
        builder: (context, state) {
          return switch (state) {
            WorkerDetailInitial() => const LoadingIndicator(
                message: 'Memuat profil...',
              ),
            WorkerDetailLoading() => const LoadingIndicator(
                message: 'Memuat profil...',
              ),
            WorkerDetailLoaded(:final worker, :final recentReviews) =>
              _WorkerDetailContent(
                worker: worker,
                recentReviews: recentReviews,
                onBookNow: onBookNow,
                onViewAllReviews: onViewAllReviews,
              ),
            WorkerDetailError(:final failure) => AppErrorWidget(
                message: failure.message,
                onRetry: () => context
                    .read<WorkerDetailBloc>()
                    .add(FetchWorkerDetail(workerId: workerId)),
              ),
            // Handle reviews states gracefully on detail page
            WorkerReviewsLoading() => const LoadingIndicator(),
            WorkerReviewsLoaded() => const SizedBox.shrink(),
            WorkerReviewsError() => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _WorkerDetailContent extends StatelessWidget {
  const _WorkerDetailContent({
    required this.worker,
    required this.recentReviews,
    this.onBookNow,
    this.onViewAllReviews,
  });

  final WorkerProfile worker;
  final List<WorkerReview> recentReviews;
  final ValueChanged<WorkerProfile>? onBookNow;
  final VoidCallback? onViewAllReviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Cover photo with back button
              _CoverPhotoSection(worker: worker),
              // Worker info section
              SliverToBoxAdapter(
                child: _WorkerInfoSection(worker: worker),
              ),
              // Services section
              SliverToBoxAdapter(
                child: _ServicesSection(services: worker.services),
              ),
              // Reviews section
              SliverToBoxAdapter(
                child: _ReviewsSection(
                  reviews: recentReviews,
                  totalReviews: worker.totalReviews,
                  onViewAll: onViewAllReviews,
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.lg),
              ),
            ],
          ),
        ),
        // Fixed bottom bar with booking fee and button
        _BookingBottomBar(
          worker: worker,
          bookingFee: worker.bookingFee,
          onBookNow: onBookNow,
        ),
      ],
    );
  }
}

/// Cover photo section with a back button overlay.
class _CoverPhotoSection extends StatelessWidget {
  const _CoverPhotoSection({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: AppSizing.coverPhotoHeight,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: worker.coverPhotoUrl != null
            ? CachedNetworkImage(
                imageUrl: worker.coverPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: AppColors.primaryLight,
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.primaryLight,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: AppSizing.iconXl,
                  ),
                ),
              )
            : const ColoredBox(
                color: AppColors.primaryLight,
                child: Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: AppSizing.iconXl,
                ),
              ),
      ),
    );
  }
}

/// Worker info section showing name, avatar, specialization, stats, etc.
class _WorkerInfoSection extends StatelessWidget {
  const _WorkerInfoSection({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: AppSizing.avatarLg / 2,
                backgroundColor: AppColors.border,
                backgroundImage: worker.avatarUrl != null
                    ? CachedNetworkImageProvider(worker.avatarUrl!)
                    : null,
                child: worker.avatarUrl == null
                    ? const Icon(Icons.person, size: AppSizing.iconLg)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and specialization
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            worker.fullName,
                            style: AppTypography.h5,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (worker.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: AppSizing.iconMd,
                          ),
                        ],
                      ],
                    ),
                    if (worker.specialization != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        worker.specialization!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats row: rating, reviews, jobs, distance
          _StatsRow(worker: worker),
          // Bio
          if (worker.bio != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              worker.bio!,
              style: AppTypography.bodyMedium,
            ),
          ],
          // Member since
          if (worker.memberSince != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bergabung sejak ${DateFormat('MMMM yyyy', 'id').format(worker.memberSince!)}',
              style: AppTypography.caption,
            ),
          ],
          const Divider(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Stats row showing rating, total reviews, completed jobs, and distance.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rating
        _StatItem(
          icon: Icons.star,
          iconColor: AppColors.ratingStar,
          value: worker.ratingAvg.toStringAsFixed(1),
          label: 'Rating',
        ),
        const SizedBox(width: AppSpacing.lg),
        // Total reviews
        _StatItem(
          icon: Icons.rate_review_outlined,
          iconColor: AppColors.secondary,
          value: '${worker.totalReviews}',
          label: 'Ulasan',
        ),
        const SizedBox(width: AppSpacing.lg),
        // Completed jobs
        _StatItem(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
          value: '${worker.completedJobs}',
          label: 'Selesai',
        ),
        if (worker.distance != null) ...[
          const SizedBox(width: AppSpacing.lg),
          _StatItem(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.info,
            value: '${worker.distance!.toStringAsFixed(1)} km',
            label: 'Jarak',
          ),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: AppSizing.iconMd),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

/// Services section showing the worker's offered services.
class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.services});

  final List<WorkerService> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.pageHorizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layanan', style: AppTypography.h6),
          const SizedBox(height: AppSpacing.sm),
          ...services.map((service) => _ServiceItem(service: service)),
          const Divider(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({required this.service});

  final WorkerService service;

  @override
  Widget build(BuildContext context) {
    final priceText = service.basePrice != null
        ? 'Rp${NumberFormat('#,###', 'id').format(service.basePrice)}'
        : '-';
    final unitText = service.priceUnit ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Service icon
          Container(
            width: AppSizing.thumbnailSm,
            height: AppSizing.thumbnailSm,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            ),
            child: service.iconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                    child: CachedNetworkImage(
                      imageUrl: service.iconUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.build,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.build, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          // Service name
          Expanded(
            child: Text(
              service.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(priceText, style: AppTypography.priceSmall),
              if (unitText.isNotEmpty)
                Text(unitText, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reviews section showing up to 3 recent reviews.
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.totalReviews,
    this.onViewAll,
  });

  final List<WorkerReview> reviews;
  final int totalReviews;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pageHorizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ulasan ($totalReviews)', style: AppTypography.h6),
              if (totalReviews > 3)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('Lihat Semua Ulasan'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (reviews.isEmpty)
            const _EmptyReviewsWidget()
          else
            ...reviews.map((review) => _ReviewItem(review: review)),
        ],
      ),
    );
  }
}

/// Empty state widget for when a worker has no reviews.
///
/// Validates: Requirement 6.8.
class _EmptyReviewsWidget extends StatelessWidget {
  const _EmptyReviewsWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: AppSizing.iconXl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum ada ulasan',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single review item card.
class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review});

  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
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
                // Date
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fixed bottom bar with booking fee and "Pesan Sekarang" button.
///
/// Validates: Requirement 6.4 (booking fee Rp2.000 visible without scrolling).
class _BookingBottomBar extends StatelessWidget {
  const _BookingBottomBar({
    required this.worker,
    required this.bookingFee,
    this.onBookNow,
  });

  final WorkerProfile worker;
  final int bookingFee;
  final ValueChanged<WorkerProfile>? onBookNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingHorizontal,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Booking fee info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Biaya Booking',
                    style: AppTypography.caption,
                  ),
                  Text(
                    'Rp${NumberFormat('#,###', 'id').format(bookingFee)}',
                    style: AppTypography.priceMedium,
                  ),
                ],
              ),
            ),
            // Book now button
            SizedBox(
              width: 160,
              child: AppButton(
                text: 'Pesan Sekarang',
                onPressed: onBookNow == null ? null : () => onBookNow!(worker),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
