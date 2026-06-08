import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/knowledge_entities.dart';

part 'knowledge_models.g.dart';

@JsonSerializable()
class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.title,
    required super.category,
    required super.excerpt,
    @JsonKey(name: 'read_time') required super.readTime,
    required super.author,
    @JsonKey(defaultValue: []) required super.tags,
    @JsonKey(name: 'created_at') required super.createdAt,
    super.body,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleModelToJson(this);
}

@JsonSerializable()
class FaqModel extends Faq {
  const FaqModel({
    required super.id,
    required super.question,
    required super.answer,
    required super.category,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) =>
      _$FaqModelFromJson(json);

  Map<String, dynamic> toJson() => _$FaqModelToJson(this);
}
