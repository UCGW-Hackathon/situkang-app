import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/rating.dart';

part 'rating_model.g.dart';

@JsonSerializable()
class RatingModel extends Rating {

  factory RatingModel.fromEntity(Rating entity) {
    return RatingModel(
      id: entity.id,
      orderId: entity.orderId,
      workerId: entity.workerId,
      userId: entity.userId,
      score: entity.score,
      comment: entity.comment,
      tags: entity.tags,
      createdAt: entity.createdAt,
    );
  }
  const RatingModel({
    required super.id,
    @JsonKey(name: 'order_id') required super.orderId,
    @JsonKey(name: 'worker_id') required super.workerId,
    @JsonKey(name: 'user_id') required super.userId,
    required super.score,
    @JsonKey(name: 'created_at') required super.createdAt, super.comment,
    super.tags,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) =>
      _$RatingModelFromJson(json);

  Map<String, dynamic> toJson() => _$RatingModelToJson(this);
}
