import 'package:equatable/equatable.dart';

import '../../../../core/constants/enums.dart';

/// Represents a single step in the order progress timeline.
///
/// Each entry corresponds to an order status transition, showing the
/// progression from accepted → on_the_way → arrived → in_progress → completed.
/// Completed steps are visually distinguished from pending steps.
///
/// Requirements: 9.5
class TimelineEntry extends Equatable {
  const TimelineEntry({
    required this.status,
    required this.title,
    required this.description,
    this.timestamp,
    this.isCompleted = false,
  });

  /// The order status this timeline step represents.
  final OrderStatus status;

  /// Human-readable title for this step (e.g., "Dalam Perjalanan").
  final String title;

  /// Description text for this step (e.g., "Tukang sedang menuju lokasi Anda").
  final String description;

  /// When this step was completed, or null if still pending.
  final DateTime? timestamp;

  /// Whether this step has been completed.
  ///
  /// Completed steps show a visual distinction (e.g., filled icon, checkmark).
  final bool isCompleted;

  /// Creates a copy of this entry with the given fields replaced.
  TimelineEntry copyWith({
    OrderStatus? status,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isCompleted,
  }) {
    return TimelineEntry(
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [status, title, description, timestamp, isCompleted];
}
