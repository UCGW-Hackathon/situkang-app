import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/service.dart';
import '../bloc/categories_bloc.dart';

/// Service listing page displaying services within a category.
///
/// Services are sorted alphabetically by name (case-insensitive) per Requirement 4.1.
/// Each service shows name, description, base price, price unit, and estimated duration.
/// Handles empty states (no services) per Requirement 4.4 and
/// inactive/non-existent category errors per Requirement 4.5.
///
/// Validates:
/// - Requirement 4.1: Services sorted alphabetically by name
/// - Requirement 4.4: Empty state for no active services
/// - Requirement 4.5: Error for inactive/non-existent categories
class ServiceListPage extends StatelessWidget {
  /// Creates a [ServiceListPage].
  const ServiceListPage({
    required this.category,
    super.key,
    this.onServiceTap,
  });

  /// The category whose services are being displayed.
  final Category category;

  /// Callback when a service is tapped. Receives the selected [Service].
  final void Function(Service service)? onServiceTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const LoadingIndicator(message: 'Memuat layanan...');
          }

          if (state is CategoriesError) {
            return AppErrorWidget(
              message: _getErrorMessage(state),
              onRetry: () {
                context.read<CategoriesBloc>().add(
                      FetchCategoryServices(categoryId: category.id),
                    );
              },
            );
          }

          if (state is ServicesLoaded) {
            if (state.services.isEmpty) {
              // Empty state per Requirement 4.4
              return const _EmptyServicesState();
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: state.services.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.listItemSpacing),
              itemBuilder: (context, index) {
                final service = state.services[index];
                return _ServiceListItem(
                  service: service,
                  onTap: () => onServiceTap?.call(service),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Returns an appropriate error message based on the failure type.
  String _getErrorMessage(CategoriesError state) {
    // Requirement 4.5: category unavailable message
    return state.failure.message;
  }
}

/// Empty state widget shown when a category has no active services.
///
/// Validates: Requirement 4.4.
class _EmptyServicesState extends StatelessWidget {
  const _EmptyServicesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.handyman_outlined,
              size: AppSizing.iconXl,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada layanan tersedia',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Saat ini belum ada layanan aktif dalam kategori ini',
              style: AppTypography.bodySmall.copyWith(
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

/// A single service item in the list.
class _ServiceListItem extends StatelessWidget {
  const _ServiceListItem({
    required this.service,
    this.onTap,
  });

  final Service service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (service.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              service.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildPriceChip(),
              const SizedBox(width: AppSpacing.sm),
              _buildDurationChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Text(
        'Rp${_formatPrice(service.basePrice)} / ${service.priceUnit}',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDurationChip() {
    if (service.estimatedDuration.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            service.estimatedDuration,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a price integer with thousand separators.
  String _formatPrice(int price) {
    final priceStr = price.toString();
    final buffer = StringBuffer();
    final length = priceStr.length;

    for (var i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceStr[i]);
    }

    return buffer.toString();
  }
}
