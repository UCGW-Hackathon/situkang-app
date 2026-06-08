import 'package:equatable/equatable.dart';

class Article extends Equatable {
  const Article({
    required this.id,
    required this.title,
    required this.category, // 'faq', 'guide', 'tips', 'safety', 'payment'
    required this.excerpt,
    required this.readTime, // in minutes
    required this.author,
    required this.tags,
    required this.createdAt,
    this.body,
  });

  final String id;
  final String title;
  final String category;
  final String excerpt;
  final String? body;
  final int readTime;
  final String author;
  final List<String> tags;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        excerpt,
        body,
        readTime,
        author,
        tags,
        createdAt,
      ];
}

class Faq extends Equatable {
  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  final String id;
  final String question;
  final String answer;
  final String category;

  @override
  List<Object?> get props => [id, question, answer, category];
}
