import 'package:equatable/equatable.dart';

/// Entity representing a rating and review given by a user to a worker.
class Rating extends Equatable {
  const Rating({
    required this.id,
    required this.orderId,
    required this.workerId,
    required this.userId,
    required this.score,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String workerId;
  final String userId;
  final int score;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        orderId,
        workerId,
        userId,
        score,
        comment,
        tags,
        createdAt,
      ];
}
