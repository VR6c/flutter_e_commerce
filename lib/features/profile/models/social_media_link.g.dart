// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_media_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SocialMediaLinkImpl _$$SocialMediaLinkImplFromJson(
  Map<String, dynamic> json,
) => _$SocialMediaLinkImpl(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  platform: json['platform'] as String,
  link: json['link'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$$SocialMediaLinkImplToJson(
  _$SocialMediaLinkImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'platform': instance.platform,
  'link': instance.link,
  'name': instance.name,
};
