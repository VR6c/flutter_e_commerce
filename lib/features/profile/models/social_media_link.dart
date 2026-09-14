import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_media_link.freezed.dart';
part 'social_media_link.g.dart';

@freezed
class SocialMediaLink with _$SocialMediaLink {
  const factory SocialMediaLink({
    required int id,
    required String type,
    required String platform,
    required String link,
    required String name,
  }) = _SocialMediaLink;

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) =>
      _$SocialMediaLinkFromJson(json);
}
