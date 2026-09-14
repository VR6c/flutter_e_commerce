import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner.freezed.dart';
part 'banner.g.dart';

@freezed
class BannerModel with _$BannerModel {
  const factory BannerModel({
    required int id,
    String? type,
    required String title,
    String? description,
    @JsonKey(name: 'image_url') required String imageUrl,
  }) = _BannerModel;

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
}
