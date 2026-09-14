import 'package:freezed_annotation/freezed_annotation.dart';

part 'variant_attribute.freezed.dart';
part 'variant_attribute.g.dart';

@freezed
class VariantAttribute with _$VariantAttribute {
  const factory VariantAttribute({
    required int id,
    required String name,
    required String value,
  }) = _VariantAttribute;

  factory VariantAttribute.fromJson(Map<String, dynamic> json) =>
      _$VariantAttributeFromJson(json);
}
