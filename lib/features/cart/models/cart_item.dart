import '../../products/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final int? variantId;
  final String? variantName;
  final String? selectedColor;
  final String? selectedSize;
  final double? unitPrice;

  const CartItem({
    required this.product,
    required this.quantity,
    this.variantId,
    this.variantName,
    this.selectedColor,
    this.selectedSize,
    this.unitPrice,
  });

  /// Unique composite identifier for cart line items (supports same product with different variants)
  String get cartKey =>
      '${product.id}_${variantId ?? 0}_${selectedColor ?? ''}_${selectedSize ?? ''}';

  /// The effective price for this item (variant price if available, else product price)
  double get effectivePrice => unitPrice ?? product.price;

  /// Total price for this cart line item
  double get totalPrice => effectivePrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    int? variantId,
    String? variantName,
    String? selectedColor,
    String? selectedSize,
    double? unitPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      if (variantId != null) 'variantId': variantId,
      if (variantName != null) 'variantName': variantName,
      if (selectedColor != null) 'selectedColor': selectedColor,
      if (selectedSize != null) 'selectedSize': selectedSize,
      if (unitPrice != null) 'unitPrice': unitPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variantId: (json['variantId'] as num?)?.toInt(),
      variantName: json['variantName'] as String?,
      selectedColor: json['selectedColor'] as String?,
      selectedSize: json['selectedSize'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          cartKey == other.cartKey &&
          quantity == other.quantity &&
          effectivePrice == other.effectivePrice;

  @override
  int get hashCode => cartKey.hashCode ^ quantity.hashCode ^ effectivePrice.hashCode;
}
