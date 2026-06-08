import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/category.dart';
import '../bloc/categories_bloc.dart';

/// Full category listing page displaying all active categories.
///
/// Categories are sorted by display order (ascending) per Requirement 4.2.
/// Each category shows its icon, name, and description per Requirement 4.3.
/// Tapping a category navigates to the [ServiceListPage] for that category.
///
/// Validates:
/// - Requirement 4.2: Full category listing sorted by display order
/// - Requirement 4.3: Display icon, name, and description
class CategoryListPage extends StatelessWidget {
  /// Creates a [CategoryListPage].
  const CategoryListPage({
    super.key,
    this.onCategoryTap,
  });

  /// Callback when a category is tapped. Receives the selected [Category].
  final void Function(Category category)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Kategori'),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const GridSkeleton();
          }

          if (state is CategoriesError) {
            return AppErrorWidget(
              message: state.failure.message,
              onRetry: () {
                context.read<CategoriesBloc>().add(const FetchCategories());
              },
            );
          }

          if (state is CategoriesLoaded) {
            if (state.categories.isEmpty) {
              return const AppErrorWidget(
                message: 'Tidak ada kategori tersedia saat ini',
                icon: Icons.category_outlined,
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: state.categories.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.listItemSpacing),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return _CategoryListItem(
                  category: category,
                  onTap: () => onCategoryTap?.call(category),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// A single category item in the list.
class _CategoryListItem extends StatelessWidget {
  const _CategoryListItem({
    required this.category,
    this.onTap,
  });

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (category.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    category.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Center(
        child: _resolveIcon(),
      ),
    );
  }

  Widget _resolveIcon() {
    // Map category icon strings to Material icons
    final iconMap = <String, IconData>{
      'ac': Icons.ac_unit,
      'pipa': Icons.plumbing,
      'atap': Icons.roofing,
      'listrik': Icons.electrical_services,
      'kunci': Icons.lock,
      'kayu': Icons.carpenter,
      'cat': Icons.format_paint,
      'kebun': Icons.yard,
    };

    final iconData =
        iconMap[category.icon.toLowerCase()] ?? Icons.build_outlined;

    return Icon(
      iconData,
      color: AppColors.primary,
      size: AppSizing.iconMd,
    );
  }
}
