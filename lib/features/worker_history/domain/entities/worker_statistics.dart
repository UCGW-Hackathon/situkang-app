import 'package:equatable/equatable.dart';

class WorkerStatistics extends Equatable {
  const WorkerStatistics({
    required this.totalEarnings,
    required this.totalJobsCompleted,
    required this.averageRating,
    required this.cancellationRate,
  });

  final int totalEarnings;
  final int totalJobsCompleted;
  final double averageRating;
  final double cancellationRate;

  @override
  List<Object?> get props => [
        totalEarnings,
        totalJobsCompleted,
        averageRating,
        cancellationRate,
      ];
}
