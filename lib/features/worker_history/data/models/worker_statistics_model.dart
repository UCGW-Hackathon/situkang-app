import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/worker_statistics.dart';

part 'worker_statistics_model.g.dart';

@JsonSerializable()
class WorkerStatisticsModel extends WorkerStatistics {
  const WorkerStatisticsModel({
    @JsonKey(name: 'total_earnings') required super.totalEarnings,
    @JsonKey(name: 'total_jobs_completed') required super.totalJobsCompleted,
    @JsonKey(name: 'average_rating') required super.averageRating,
    @JsonKey(name: 'cancellation_rate') required super.cancellationRate,
  });

  factory WorkerStatisticsModel.fromJson(Map<String, dynamic> json) =>
      _$WorkerStatisticsModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkerStatisticsModelToJson(this);
}
