part of 'product_variant.dart';

_$ProductVariantImpl _$$ProductVariantImplFromJson(Map<String, dynamic> json) =>
    _$ProductVariantImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sku: json['sku'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      attributes:
          (json['attributes'] as List<dynamic>?)
              ?.map((e) => VariantAttribute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProductVariantImplToJson(
  _$ProductVariantImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'discount_price': instance.discountPrice,
  'stock': instance.stock,
  'sku': instance.sku,
  'is_primary': instance.isPrimary,
  'attributes': instance.attributes,
};
