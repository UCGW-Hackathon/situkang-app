import 'package:equatable/equatable.dart';

import 'active_order.dart';
import 'article_item.dart';
import 'category_item.dart';
import 'featured_worker.dart';
import 'promo_banner.dart';

/// Aggregated data for the User Home screen.
///
/// Contains all sections displayed on the home screen:
/// greeting, active order banner, promotions, categories,
/// featured workers, and articles.
class HomeData extends Equatable {
  const HomeData({
    required this.fullName,
    required this.currentAddress,
    required this.promos,
    required this.categories,
    required this.featuredWorkers,
    required this.articles,
    this.avatarUrl,
    this.activeOrder,
  });

  /// User's full name for the greeting (e.g., "Budi").
  final String fullName;

  /// User's current location address.
  final String currentAddress;

  /// User's avatar URL, or null if not set.
  final String? avatarUrl;

  /// The user's currently active order, or null if none.
  final ActiveOrder? activeOrder;

  /// Promotional banners (up to 10).
  final List<PromoBanner> promos;

  /// Service category grid items.
  final List<CategoryItem> categories;

  /// Featured nearby workers (up to 10, within 10km, sorted by distance).
  final List<FeaturedWorker> featuredWorkers;

  /// Article cards for the home screen.
  final List<ArticleItem> articles;

  @override
  List<Object?> get props => [
        fullName,
        currentAddress,
        avatarUrl,
        activeOrder,
        promos,
        categories,
        featuredWorkers,
        articles,
      ];
}
