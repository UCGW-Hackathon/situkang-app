import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_review.dart';
import '../bloc/worker_detail_bloc.dart';

class WorkerDetailPage extends StatefulWidget {
  const WorkerDetailPage({required this.workerId, super.key});

  final String workerId;

  @override
  State<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends State<WorkerDetailPage> {
  void _onBookNow(WorkerProfile worker) {
    context.push(
      '/workers/${worker.id}/order',
      extra: {
        'workerProfile': worker,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<WorkerDetailBloc, WorkerDetailState>(
        builder: (context, state) {
          return switch (state) {
            WorkerDetailInitial() || WorkerDetailLoading() => const _WorkerDetailSkeleton(),
            WorkerDetailLoaded(:final worker, :final recentReviews) => _buildContent(worker, recentReviews),
            WorkerDetailError(:final failure) => AppErrorWidget(
                message: failure.message,
                onRetry: () => context.read<WorkerDetailBloc>().add(FetchWorkerDetail(workerId: widget.workerId)),
              ),
            WorkerReviewsLoading() => const LoadingIndicator(),
            WorkerReviewsLoaded() => const SizedBox.shrink(),
            WorkerReviewsError() => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildContent(WorkerProfile worker, List<WorkerReview> recentReviews) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildCoverPhoto(worker),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _buildWorkerInfoCard(worker),
                    const SizedBox(height: AppSpacing.md),
                    _buildSkillsAndServices(worker),
                    const SizedBox(height: AppSpacing.lg),
                    if (recentReviews.isNotEmpty) _buildReviewsSnippet(recentReviews.first, worker.totalReviews),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildBottomBar(worker),
      ],
    );
  }

  Widget _buildCoverPhoto(WorkerProfile worker) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: worker.coverPhotoUrl != null || worker.avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: worker.coverPhotoUrl ?? worker.avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.primaryLight,
                  child: Icon(Icons.person, color: Colors.white54, size: 80),
                ),
              )
            : const ColoredBox(
                color: AppColors.primaryLight,
                child: Icon(Icons.person, color: Colors.white54, size: 80),
              ),
      ),
    );
  }

  Widget _buildWorkerInfoCard(WorkerProfile worker) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  worker.fullName,
                  style: AppTypography.h4,
                ),
              ),
              if (worker.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Terverifikasi',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            worker.specialization ?? 'Spesialis',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star,
                iconColor: AppColors.ratingStar,
                value: worker.ratingAvg.toStringAsFixed(1),
                label: '${worker.totalReviews} Ulasan',
              ),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.primary,
                value: '${worker.completedJobs}+',
                label: 'Pesanan Selesai',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.h6),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsAndServices(WorkerProfile worker) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keahlian & Layanan', style: AppTypography.h6),
          const SizedBox(height: AppSpacing.sm),
          Text(
            worker.bio ?? 'Berpengalaman menangani berbagai masalah rumah tangga dengan standar keamanan tinggi.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: worker.services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (service.iconUrl != null) ...[
                      CachedNetworkImage(
                        imageUrl: service.iconUrl!,
                        width: 16,
                        height: 16,
                        errorWidget: (_, _, _) => const Icon(Icons.build, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      const Icon(Icons.build, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      service.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSnippet(WorkerReview review, int totalReviews) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            radius: 20,
            child: Text('"', style: TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingStars(rating: review.rating.toDouble(), size: 14),
                const SizedBox(height: 8),
                Text(
                  '"${review.comment ?? 'Sangat memuaskan.'}"',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${review.reviewerName}, ${review.reviewerLocation ?? 'Indonesia'}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(WorkerProfile worker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Fee', style: AppTypography.caption),
                  Text(
                    'Rp${NumberFormat('#,###', 'id').format(worker.bookingFee)}',
                    style: AppTypography.priceMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C84), // Deep teal
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _onBookNow(worker),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Pesan Tukang', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerDetailSkeleton extends StatelessWidget {
  const _WorkerDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppColors.primaryLight,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Skeleton(height: 300, width: double.infinity, borderRadius: 0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Skeleton(height: 24, width: 150),
                                  Skeleton(height: 24, width: 80, borderRadius: 12),
                                ],
                              ),
                              SizedBox(height: 8),
                              Skeleton(height: 16, width: 100),
                              SizedBox(height: 16),
                              Divider(),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Skeleton(height: 40, width: 80),
                                  Skeleton(height: 40, width: 80),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(height: 20, width: 150),
                              SizedBox(height: 8),
                              Skeleton(height: 14, width: double.infinity),
                              SizedBox(height: 4),
                              Skeleton(height: 14, width: 250),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Skeleton(height: 30, width: 100, borderRadius: 8),
                                  SizedBox(width: 8),
                                  Skeleton(height: 30, width: 120, borderRadius: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: const SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(child: Skeleton(height: 40)),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: Skeleton(height: 48, borderRadius: 8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


