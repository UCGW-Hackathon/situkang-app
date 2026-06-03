import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/notification_entity.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    @JsonKey(name: 'created_at') required super.createdAt,
    @JsonKey(name: 'is_read') required super.isRead,
    @JsonKey(name: 'target_id') super.targetId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
