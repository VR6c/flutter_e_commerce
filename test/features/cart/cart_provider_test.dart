import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_e_commerce/features/cart/providers/cart_provider.dart';
import 'package:flutter_e_commerce/features/products/models/product.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  const testProduct1 = Product(
    id: 1,
    slug: 'iphone-13',
    name: 'iPhone 13',
    shortDescription: 'Latest Apple iPhone',
    price: 999.0,
    thumbnail: 'https://example.com/iphone13.png',
    category: 'Electronics',
    brand: 'Apple',
    rating: 4.8,
  );

  const testProduct2 = Product(
    id: 2,
    slug: 'macbook-pro',
    name: 'MacBook Pro',
    shortDescription: 'Powerful laptop',
    price: 1999.0,
    thumbnail: 'https://example.com/macbook.png',
    category: 'Electronics',
    brand: 'Apple',
    rating: 4.9,
  );

  test('Cart starts empty', () {
    final cart = container.read(cartProvider);
    expect(cart, isEmpty);
    expect(container.read(cartTotalAmountProvider), 0.0);
    expect(container.read(cartItemsCountProvider), 0);
  });

  test('Add item to cart', () {
    container.read(cartProvider.notifier).addItem(testProduct1, quantity: 2);
    
    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart[0].product, testProduct1);
    expect(cart[0].quantity, 2);

    expect(container.read(cartTotalAmountProvider), 1998.0);
    expect(container.read(cartItemsCountProvider), 2);
  });

  test('Add duplicate item increments quantity', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(testProduct1, quantity: 1);
    notifier.addItem(testProduct1, quantity: 2);

    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart[0].quantity, 3);
    expect(container.read(cartTotalAmountProvider), 2997.0);
    expect(container.read(cartItemsCountProvider), 3);
  });

  test('Remove item from cart', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(testProduct1, quantity: 2);
    notifier.addItem(testProduct2, quantity: 1);

    notifier.removeItem(testProduct1.id);

    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart[0].product, testProduct2);
    expect(container.read(cartTotalAmountProvider), 1999.0);
    expect(container.read(cartItemsCountProvider), 1);
  });

  test('Update item quantity', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(testProduct1, quantity: 1);
    notifier.updateQuantity(testProduct1.id, 5);

    var cart = container.read(cartProvider);
    expect(cart[0].quantity, 5);
    expect(container.read(cartTotalAmountProvider), 4995.0);

    // Quantity <= 0 removes item
    notifier.updateQuantity(testProduct1.id, 0);
    cart = container.read(cartProvider);
    expect(cart, isEmpty);
  });

  test('Clear cart removes all items', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(testProduct1);
    notifier.addItem(testProduct2);

    notifier.clear();

    expect(container.read(cartProvider), isEmpty);
    expect(container.read(cartTotalAmountProvider), 0.0);
  });
}
