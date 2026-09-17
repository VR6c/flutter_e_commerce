part of 'product.dart';

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String,
      name: json['name'] as String,
      shortDescription: json['short_description'] as String,
      price: (json['price'] as num).toDouble(),
      thumbnail: json['thumbnail'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'short_description': instance.shortDescription,
      'price': instance.price,
      'thumbnail': instance.thumbnail,
      'category': instance.category,
      'brand': instance.brand,
      'rating': instance.rating,
      'variants': instance.variants,
    };
