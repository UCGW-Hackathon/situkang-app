import '../../domain/entities/promo_banner.dart';

/// Data Transfer Object for promotional banner API responses.
///
/// Maps snake_case JSON fields from the `/home` endpoint to the
/// domain [PromoBanner] entity.
class PromoBannerModel {
  const PromoBannerModel({
    required this.promoId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ctaLabel,
  });

  /// Parses a [PromoBannerModel] from a JSON map.
  factory PromoBannerModel.fromJson(Map<String, dynamic> json) {
    return PromoBannerModel(
      promoId: json['promo_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      ctaLabel: json['cta_label'] as String? ?? '',
    );
  }

  final String promoId;
  final String title;
  final String description;
  final String imageUrl;
  final String ctaLabel;

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'promo_id': promoId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'cta_label': ctaLabel,
    };
  }

  /// Converts this data model to the domain [PromoBanner] entity.
  PromoBanner toEntity() {
    return PromoBanner(
      id: promoId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      ctaLabel: ctaLabel,
    );
  }
}
