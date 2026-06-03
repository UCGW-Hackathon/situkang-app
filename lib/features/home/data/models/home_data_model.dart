import '../../domain/entities/home_data.dart';
import 'active_order_model.dart';
import 'article_item_model.dart';
import 'category_item_model.dart';
import 'featured_worker_model.dart';
import 'promo_banner_model.dart';

/// Data Transfer Object for the aggregated home screen API response.
///
/// Maps the full `/home` endpoint response to individual models
/// and provides conversion to the domain [HomeData] entity.
class HomeDataModel {
  const HomeDataModel({
    required this.fullName,
    required this.currentAddress,
    required this.promos,
    required this.categories,
    required this.featuredWorkers,
    required this.articles,
    this.avatarUrl,
    this.activeOrder,
  });

  /// Parses a [HomeDataModel] from the `/home` API response data.
  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    final userSummary = json['user_summary'] as Map<String, dynamic>? ?? {};

    return HomeDataModel(
      fullName: userSummary['full_name'] as String? ?? '',
      currentAddress: userSummary['current_address'] as String? ?? '',
      avatarUrl: userSummary['avatar_url'] as String?,
      activeOrder: ActiveOrderModel.fromJson(
        json['active_order'] as Map<String, dynamic>?,
      ),
      promos: (json['promotions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PromoBannerModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      categories: (json['service_categories'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CategoryItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      featuredWorkers: (json['featured_workers'] as List<dynamic>?)
              ?.map(
                (e) =>
                    FeaturedWorkerModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      articles: (json['articles'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ArticleItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  final String fullName;
  final String currentAddress;
  final String? avatarUrl;
  final ActiveOrderModel? activeOrder;
  final List<PromoBannerModel> promos;
  final List<CategoryItemModel> categories;
  final List<FeaturedWorkerModel> featuredWorkers;
  final List<ArticleItemModel> articles;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'user_summary': {
        'full_name': fullName,
        'current_address': currentAddress,
        'avatar_url': avatarUrl,
      },
      'active_order': activeOrder?.toJson(),
      'promotions': promos.map((e) => e.toJson()).toList(),
      'service_categories': categories.map((e) => e.toJson()).toList(),
      'featured_workers': featuredWorkers.map((e) => e.toJson()).toList(),
      'articles': articles.map((e) => e.toJson()).toList(),
    };
  }

  /// Converts this data model to the domain [HomeData] entity.
  HomeData toEntity() {
    return HomeData(
      fullName: fullName,
      currentAddress: currentAddress,
      avatarUrl: avatarUrl,
      activeOrder: activeOrder?.toEntity(),
      promos: promos.map((e) => e.toEntity()).toList(),
      categories: categories.map((e) => e.toEntity()).toList(),
      featuredWorkers: featuredWorkers.map((e) => e.toEntity()).toList(),
      articles: articles.map((e) => e.toEntity()).toList(),
    );
  }
}
