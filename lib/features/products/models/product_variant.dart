import 'package:freezed_annotation/freezed_annotation.dart';
import 'variant_attribute.dart';

part 'product_variant.freezed.dart';
part 'product_variant.g.dart';

@freezed
class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required int id,
    required String name,
    required double price,
    @JsonKey(name: 'discount_price') double? discountPrice,
    @Default(0) int stock,
    String? sku,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @Default([]) List<VariantAttribute> attributes,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}
