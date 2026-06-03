import 'package:equatable/equatable.dart';

/// Represents an AI-detected risk flag on a purchase.
///
/// Risk flags indicate potential issues with a purchase that the AI processor
/// has identified, such as unreasonable pricing, irrelevant items, or
/// incomplete data.
class RiskFlag extends Equatable {
  const RiskFlag({
    required this.type,
    required this.message,
  });

  /// The type of risk detected.
  ///
  /// Valid types:
  /// - `harga_tidak_wajar` — Unreasonable price
  /// - `item_tidak_relevan` — Irrelevant item for the job
  /// - `data_tidak_lengkap` — Incomplete data
  /// - `nota_tidak_jelas` — Unclear receipt
  /// - `duplikat` — Duplicate purchase
  /// - `alasan_tidak_lengkap` — Incomplete reason
  final String type;

  /// A human-readable message describing the detected issue.
  final String message;

  @override
  List<Object?> get props => [type, message];
}
