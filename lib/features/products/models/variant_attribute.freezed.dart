// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'variant_attribute.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VariantAttribute _$VariantAttributeFromJson(Map<String, dynamic> json) {
  return _VariantAttribute.fromJson(json);
}

/// @nodoc
mixin _$VariantAttribute {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;

  /// Serializes this VariantAttribute to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VariantAttribute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VariantAttributeCopyWith<VariantAttribute> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VariantAttributeCopyWith<$Res> {
  factory $VariantAttributeCopyWith(
    VariantAttribute value,
    $Res Function(VariantAttribute) then,
  ) = _$VariantAttributeCopyWithImpl<$Res, VariantAttribute>;
  @useResult
  $Res call({int id, String name, String value});
}

/// @nodoc
class _$VariantAttributeCopyWithImpl<$Res, $Val extends VariantAttribute>
    implements $VariantAttributeCopyWith<$Res> {
  _$VariantAttributeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VariantAttribute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? value = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VariantAttributeImplCopyWith<$Res>
    implements $VariantAttributeCopyWith<$Res> {
  factory _$$VariantAttributeImplCopyWith(
    _$VariantAttributeImpl value,
    $Res Function(_$VariantAttributeImpl) then,
  ) = __$$VariantAttributeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String value});
}

/// @nodoc
class __$$VariantAttributeImplCopyWithImpl<$Res>
    extends _$VariantAttributeCopyWithImpl<$Res, _$VariantAttributeImpl>
    implements _$$VariantAttributeImplCopyWith<$Res> {
  __$$VariantAttributeImplCopyWithImpl(
    _$VariantAttributeImpl _value,
    $Res Function(_$VariantAttributeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VariantAttribute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? value = null}) {
    return _then(
      _$VariantAttributeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VariantAttributeImpl implements _VariantAttribute {
  const _$VariantAttributeImpl({
    required this.id,
    required this.name,
    required this.value,
  });

  factory _$VariantAttributeImpl.fromJson(Map<String, dynamic> json) =>
      _$$VariantAttributeImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String value;

  @override
  String toString() {
    return 'VariantAttribute(id: $id, name: $name, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VariantAttributeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, value);

  /// Create a copy of VariantAttribute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VariantAttributeImplCopyWith<_$VariantAttributeImpl> get copyWith =>
      __$$VariantAttributeImplCopyWithImpl<_$VariantAttributeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VariantAttributeImplToJson(this);
  }
}

abstract class _VariantAttribute implements VariantAttribute {
  const factory _VariantAttribute({
    required final int id,
    required final String name,
    required final String value,
  }) = _$VariantAttributeImpl;

  factory _VariantAttribute.fromJson(Map<String, dynamic> json) =
      _$VariantAttributeImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get value;

  /// Create a copy of VariantAttribute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VariantAttributeImplCopyWith<_$VariantAttributeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
