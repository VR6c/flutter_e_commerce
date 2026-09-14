import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../products/models/product.dart';
import '../models/cart_item.dart';

part 'cart_provider.g.dart';

const _kCartKey = 'guest_cart_items_v2';

@riverpod
class Cart extends _$Cart {
  @override
  List<CartItem> build() {
    // Load persisted cart asynchronously after first build
    _loadPersistedCart();
    return [];
  }

  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _loadPersistedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartKey) ?? prefs.getString('guest_cart_items');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final items = decoded
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = items;
      }
    } catch (_) {
      // Silently ignore persistence errors — fall back to empty cart
    }
  }

  Future<void> _persistCart(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_kCartKey, encoded);
    } catch (_) {
      // Silently ignore
    }
  }

  // ── Cart operations ───────────────────────────────────────────────────────────

  void addItem(
    Product product, {
    int quantity = 1,
    int? variantId,
    String? variantName,
    String? selectedColor,
    String? selectedSize,
    double? unitPrice,
  }) {
    final key = '${product.id}_${variantId ?? 0}_${selectedColor ?? ''}_${selectedSize ?? ''}';
    final index = state.indexWhere((item) => item.cartKey == key);
    List<CartItem> next;
    if (index >= 0) {
      final existing = state[index];
      next = [
        ...state.sublist(0, index),
        existing.copyWith(quantity: existing.quantity + quantity),
        ...state.sublist(index + 1),
      ];
    } else {
      next = [
        ...state,
        CartItem(
          product: product,
          quantity: quantity,
          variantId: variantId,
          variantName: variantName,
          selectedColor: selectedColor,
          selectedSize: selectedSize,
          unitPrice: unitPrice,
        ),
      ];
    }
    state = next;
    _persistCart(next);
  }

  void removeItemByKey(String cartKey) {
    final next = state.where((item) => item.cartKey != cartKey).toList();
    state = next;
    _persistCart(next);
  }

  void removeItem(int productId) {
    final next = state.where((item) => item.product.id != productId).toList();
    state = next;
    _persistCart(next);
  }

  void updateQuantityByKey(String cartKey, int quantity) {
    if (quantity <= 0) {
      removeItemByKey(cartKey);
      return;
    }
    final next = state.map((item) {
      if (item.cartKey == cartKey) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = next;
    _persistCart(next);
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final next = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = next;
    _persistCart(next);
  }

  void clear() {
    state = [];
    _persistCart([]);
  }
}

final cartTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

final cartItemsCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalWeightProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + (item.quantity * 0.45));
});
