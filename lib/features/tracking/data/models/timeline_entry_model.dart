import '../../../../core/constants/enums.dart';
import '../../domain/entities/timeline_entry.dart';

/// Data transfer object for timeline entries from the API.
///
/// Maps the JSON response from the tracking timeline endpoint
/// to the domain [TimelineEntry] entity.
class TimelineEntryModel {
  const TimelineEntryModel({
    required this.status,
    required this.title,
    required this.description,
    this.timestamp,
    this.isCompleted = false,
  });

  /// Creates a [TimelineEntryModel] from a JSON map.
  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return TimelineEntryModel(
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  final OrderStatus status;
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'status': status.value,
        'title': title,
        'description': description,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        'is_completed': isCompleted,
      };

  /// Converts this DTO to the domain entity.
  TimelineEntry toEntity() => TimelineEntry(
        status: status,
        title: title,
        description: description,
        timestamp: timestamp,
        isCompleted: isCompleted,
      );
}
