import 'package:freezed_annotation/freezed_annotation.dart';
import 'product_variant.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required int id,
    required String slug,
    required String name,
    @JsonKey(name: 'short_description') required String shortDescription,
    required double price,
    required String thumbnail,
    required String category,
    String? brand,
    double? rating,
    @Default([]) List<ProductVariant> variants,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

extension ProductPriceX on Product {
  /// The primary variant, or the first variant if none is flagged as primary.
  ProductVariant? get primaryVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere(
      (v) => v.isPrimary,
      orElse: () => variants.first,
    );
  }

  /// The active selling price (from primary variant or product price).
  double get effectivePrice {
    final pv = primaryVariant;
    if (pv != null) {
      if (pv.discountPrice != null && pv.discountPrice! > 0) {
        return pv.discountPrice!;
      }
      if (pv.price > 0) {
        return pv.price;
      }
    }
    return price;
  }

  /// The original pre-discount price, if discounted.
  double? get originalPrice {
    final pv = primaryVariant;
    if (pv != null) {
      if (pv.discountPrice != null &&
          pv.discountPrice! > 0 &&
          pv.price > pv.discountPrice!) {
        return pv.price;
      }
    }
    if (price > effectivePrice && effectivePrice > 0) {
      return price;
    }
    return null;
  }

  /// True if there is a valid discount on this product.
  bool get hasDiscount =>
      originalPrice != null && originalPrice! > effectivePrice;

  /// Discount percentage (e.g. 28%).
  int? get discountPercentage {
    if (!hasDiscount || originalPrice == null || originalPrice! <= 0) {
      return null;
    }
    final diff = originalPrice! - effectivePrice;
    return ((diff / originalPrice!) * 100).round();
  }
}
