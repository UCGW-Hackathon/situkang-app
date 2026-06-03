import 'package:equatable/equatable.dart';

/// Represents a promotional banner displayed on the home screen.
///
/// Up to 10 banners are shown, each with a title, description,
/// image, and call-to-action label.
class PromoBanner extends Equatable {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ctaLabel,
  });

  /// Unique promo identifier.
  final String id;

  /// Promo title text.
  final String title;

  /// Promo description text.
  final String description;

  /// URL to the promo banner image.
  final String imageUrl;

  /// Call-to-action button label (e.g., "Klaim Sekarang").
  final String ctaLabel;

  @override
  List<Object?> get props => [id, title, description, imageUrl, ctaLabel];
}
