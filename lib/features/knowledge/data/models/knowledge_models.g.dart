// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArticleModel _$ArticleModelFromJson(Map<String, dynamic> json) => ArticleModel(
  id: json['id'] as String,
  title: json['title'] as String,
  category: json['category'] as String,
  excerpt: json['excerpt'] as String,
  body: json['body'] as String?,
  readTime: (json['read_time'] as num).toInt(),
  author: json['author'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ArticleModelToJson(ArticleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'excerpt': instance.excerpt,
      'body': instance.body,
      'read_time': instance.readTime,
      'author': instance.author,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
    };

FaqModel _$FaqModelFromJson(Map<String, dynamic> json) => FaqModel(
  id: json['id'] as String,
  question: json['question'] as String,
  answer: json['answer'] as String,
  category: json['category'] as String,
);

Map<String, dynamic> _$FaqModelToJson(FaqModel instance) => <String, dynamic>{
  'id': instance.id,
  'question': instance.question,
  'answer': instance.answer,
  'category': instance.category,
};
