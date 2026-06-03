import 'package:json_annotation/json_annotation.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/worker_profile.dart';

part 'worker_profile_model.g.dart';

@JsonSerializable()
class WorkerServiceModel extends WorkerService {
  const WorkerServiceModel({
    required super.id,
    required super.name,
    @JsonKey(name: 'base_price') required super.basePrice,
    @JsonKey(name: 'price_unit') required super.priceUnit,
  });

  factory WorkerServiceModel.fromJson(Map<String, dynamic> json) =>
      _$WorkerServiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkerServiceModelToJson(this);
}

@JsonSerializable()
class WorkerProfileModel extends WorkerProfile {
  const WorkerProfileModel({
    required super.id,
    required super.name,
    @JsonKey(name: 'avatar_url') super.avatarUrl,
    @JsonKey(name: 'cover_url') super.coverUrl,
    @JsonKey(name: 'phone_number') required super.phoneNumber,
    super.bio,
    @JsonKey(name: 'verification_status') required super.verificationStatus,
    @JsonKey(name: 'verification_reason') super.verificationReason,
    this.servicesModel = const [],
    @JsonKey(name: 'joined_at') required super.joinedAt,
  }) : super(services: servicesModel);

  @JsonKey(name: 'services')
  final List<WorkerServiceModel> servicesModel;

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) =>
      _$WorkerProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkerProfileModelToJson(this);
}
