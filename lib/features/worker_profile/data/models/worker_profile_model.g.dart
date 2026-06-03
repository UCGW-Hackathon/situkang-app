// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkerServiceModel _$WorkerServiceModelFromJson(Map<String, dynamic> json) =>
    WorkerServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      basePrice: (json['base_price'] as num).toInt(),
      priceUnit: json['price_unit'] as String,
    );

Map<String, dynamic> _$WorkerServiceModelToJson(WorkerServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'base_price': instance.basePrice,
      'price_unit': instance.priceUnit,
    };

WorkerProfileModel _$WorkerProfileModelFromJson(Map<String, dynamic> json) =>
    WorkerProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      phoneNumber: json['phone_number'] as String,
      bio: json['bio'] as String?,
      verificationStatus: $enumDecode(
        _$VerificationStatusEnumMap,
        json['verification_status'],
      ),
      verificationReason: json['verification_reason'] as String?,
      servicesModel:
          (json['services'] as List<dynamic>?)
              ?.map(
                (e) => WorkerServiceModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$WorkerProfileModelToJson(WorkerProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar_url': instance.avatarUrl,
      'cover_url': instance.coverUrl,
      'phone_number': instance.phoneNumber,
      'bio': instance.bio,
      'verification_status':
          _$VerificationStatusEnumMap[instance.verificationStatus]!,
      'verification_reason': instance.verificationReason,
      'joined_at': instance.joinedAt.toIso8601String(),
      'services': instance.servicesModel,
    };

const _$VerificationStatusEnumMap = {
  VerificationStatus.unverified: 'unverified',
  VerificationStatus.pending: 'pending',
  VerificationStatus.verified: 'verified',
  VerificationStatus.rejected: 'rejected',
};
