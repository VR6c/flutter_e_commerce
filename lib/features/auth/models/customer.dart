import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    required int id,
    required String name,
    required String email,
    required String status,
    @JsonKey(name: 'profile_image') String? profileImage,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'avatar_type') String? avatarType,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}

extension CustomerAvatarX on Customer {
  String? get effectiveAvatarUrl =>
      (avatarUrl != null && avatarUrl!.isNotEmpty) ? avatarUrl : profileImage;
}
