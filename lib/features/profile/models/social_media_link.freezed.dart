// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_media_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SocialMediaLink _$SocialMediaLinkFromJson(Map<String, dynamic> json) {
  return _SocialMediaLink.fromJson(json);
}

/// @nodoc
mixin _$SocialMediaLink {
  int get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get platform => throw _privateConstructorUsedError;
  String get link => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this SocialMediaLink to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SocialMediaLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SocialMediaLinkCopyWith<SocialMediaLink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SocialMediaLinkCopyWith<$Res> {
  factory $SocialMediaLinkCopyWith(
    SocialMediaLink value,
    $Res Function(SocialMediaLink) then,
  ) = _$SocialMediaLinkCopyWithImpl<$Res, SocialMediaLink>;
  @useResult
  $Res call({int id, String type, String platform, String link, String name});
}

/// @nodoc
class _$SocialMediaLinkCopyWithImpl<$Res, $Val extends SocialMediaLink>
    implements $SocialMediaLinkCopyWith<$Res> {
  _$SocialMediaLinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SocialMediaLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? platform = null,
    Object? link = null,
    Object? name = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as String,
            link: null == link
                ? _value.link
                : link // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SocialMediaLinkImplCopyWith<$Res>
    implements $SocialMediaLinkCopyWith<$Res> {
  factory _$$SocialMediaLinkImplCopyWith(
    _$SocialMediaLinkImpl value,
    $Res Function(_$SocialMediaLinkImpl) then,
  ) = __$$SocialMediaLinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String type, String platform, String link, String name});
}

/// @nodoc
class __$$SocialMediaLinkImplCopyWithImpl<$Res>
    extends _$SocialMediaLinkCopyWithImpl<$Res, _$SocialMediaLinkImpl>
    implements _$$SocialMediaLinkImplCopyWith<$Res> {
  __$$SocialMediaLinkImplCopyWithImpl(
    _$SocialMediaLinkImpl _value,
    $Res Function(_$SocialMediaLinkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SocialMediaLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? platform = null,
    Object? link = null,
    Object? name = null,
  }) {
    return _then(
      _$SocialMediaLinkImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String,
        link: null == link
            ? _value.link
            : link // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SocialMediaLinkImpl implements _SocialMediaLink {
  const _$SocialMediaLinkImpl({
    required this.id,
    required this.type,
    required this.platform,
    required this.link,
    required this.name,
  });

  factory _$SocialMediaLinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$SocialMediaLinkImplFromJson(json);

  @override
  final int id;
  @override
  final String type;
  @override
  final String platform;
  @override
  final String link;
  @override
  final String name;

  @override
  String toString() {
    return 'SocialMediaLink(id: $id, type: $type, platform: $platform, link: $link, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SocialMediaLinkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, platform, link, name);

  /// Create a copy of SocialMediaLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SocialMediaLinkImplCopyWith<_$SocialMediaLinkImpl> get copyWith =>
      __$$SocialMediaLinkImplCopyWithImpl<_$SocialMediaLinkImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SocialMediaLinkImplToJson(this);
  }
}

abstract class _SocialMediaLink implements SocialMediaLink {
  const factory _SocialMediaLink({
    required final int id,
    required final String type,
    required final String platform,
    required final String link,
    required final String name,
  }) = _$SocialMediaLinkImpl;

  factory _SocialMediaLink.fromJson(Map<String, dynamic> json) =
      _$SocialMediaLinkImpl.fromJson;

  @override
  int get id;
  @override
  String get type;
  @override
  String get platform;
  @override
  String get link;
  @override
  String get name;

  /// Create a copy of SocialMediaLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SocialMediaLinkImplCopyWith<_$SocialMediaLinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
