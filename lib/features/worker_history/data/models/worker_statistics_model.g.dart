// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkerStatisticsModel _$WorkerStatisticsModelFromJson(
  Map<String, dynamic> json,
) => WorkerStatisticsModel(
  totalEarnings: (json['total_earnings'] as num).toInt(),
  totalJobsCompleted: (json['total_jobs_completed'] as num).toInt(),
  averageRating: (json['average_rating'] as num).toDouble(),
  cancellationRate: (json['cancellation_rate'] as num).toDouble(),
);

Map<String, dynamic> _$WorkerStatisticsModelToJson(
  WorkerStatisticsModel instance,
) => <String, dynamic>{
  'total_earnings': instance.totalEarnings,
  'total_jobs_completed': instance.totalJobsCompleted,
  'average_rating': instance.averageRating,
  'cancellation_rate': instance.cancellationRate,
};
