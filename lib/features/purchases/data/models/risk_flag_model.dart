import '../../domain/entities/risk_flag.dart';

/// Data model for a risk flag, mapping API JSON to domain entity.
class RiskFlagModel {
  const RiskFlagModel({
    required this.type,
    required this.message,
  });

  /// Creates a [RiskFlagModel] from a JSON map.
  factory RiskFlagModel.fromJson(Map<String, dynamic> json) {
    return RiskFlagModel(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  /// The risk flag type identifier.
  final String type;

  /// The human-readable risk message.
  final String message;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
      };

  /// Converts this model to a domain [RiskFlag] entity.
  RiskFlag toEntity() => RiskFlag(
        type: type,
        message: message,
      );
}
