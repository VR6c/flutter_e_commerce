part of 'variant_attribute.dart';

_$VariantAttributeImpl _$$VariantAttributeImplFromJson(
  Map<String, dynamic> json,
) => _$VariantAttributeImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  value: json['value'] as String,
);

Map<String, dynamic> _$$VariantAttributeImplToJson(
  _$VariantAttributeImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'value': instance.value,
};
