import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/category_item.dart';

/// Grid widget displaying service categories.
///
/// Shows 8 categories (AC, Pipa, Atap, Listrik, Kunci, Kayu, Cat, Kebun)
/// in a 4x2 grid layout with icons and names. Categories are displayed
/// in their configured display order.
///
/// Requirement 3.5: Display the service category grid with icons for
/// AC, Pipa, Atap, Listrik, Kunci, Kayu, Cat, and Kebun in their
/// configured display order.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    required this.categories,
    super.key,
    this.onCategoryTap,
    this.onViewAllTap,
  });

  /// List of category items to display.
  final List<CategoryItem> categories;

  /// Callback when a category is tapped.
  final void Function(CategoryItem category)? onCategoryTap;

  /// Callback when "Lihat Semua" is tapped.
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Layanan', style: AppTypography.h5),
              if (onViewAllTap != null)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    'Lihat Semua',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Category grid
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryGridItem(
                category: category,
                onTap: () => onCategoryTap?.call(category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.category,
    this.onTap,
  });

  final CategoryItem category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Center(
              child: CachedNetworkImage(
                imageUrl: category.icon,
                width: AppSizing.iconLg,
                height: AppSizing.iconLg,
                placeholder: (context, url) => const Icon(
                  Icons.category_outlined,
                  color: AppColors.primary,
                  size: AppSizing.iconMd,
                ),
                errorWidget: (context, url, error) => Icon(
                  _getCategoryFallbackIcon(category.name),
                  color: AppColors.primary,
                  size: AppSizing.iconMd,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.name,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryFallbackIcon(String name) {
    switch (name.toLowerCase()) {
      case 'ac':
        return Icons.ac_unit;
      case 'pipa':
        return Icons.plumbing;
      case 'atap':
        return Icons.roofing;
      case 'listrik':
        return Icons.electrical_services;
      case 'kunci':
        return Icons.lock;
      case 'kayu':
        return Icons.carpenter;
      case 'cat':
        return Icons.format_paint;
      case 'kebun':
        return Icons.yard;
      default:
        return Icons.category;
    }
  }
}
