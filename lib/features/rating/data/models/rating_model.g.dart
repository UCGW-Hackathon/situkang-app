// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingModel _$RatingModelFromJson(Map<String, dynamic> json) => RatingModel(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  workerId: json['worker_id'] as String,
  userId: json['user_id'] as String,
  score: (json['score'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  comment: json['comment'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$RatingModelToJson(RatingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'worker_id': instance.workerId,
      'user_id': instance.userId,
      'score': instance.score,
      'comment': instance.comment,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
    };
