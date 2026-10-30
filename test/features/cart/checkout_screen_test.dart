import 'dart:async' show Completer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_e_commerce/core/api/app_exception.dart';
import 'package:flutter_e_commerce/core/localization/app_localizations.dart';
import 'package:flutter_e_commerce/features/cart/models/cart_item.dart';
import 'package:flutter_e_commerce/features/cart/providers/cart_provider.dart';
import 'package:flutter_e_commerce/features/cart/providers/coupon_provider.dart';
import 'package:flutter_e_commerce/features/cart/screens/checkout_screen.dart';
import 'package:flutter_e_commerce/features/orders/data/order_repository.dart';
import 'package:flutter_e_commerce/features/orders/providers/orders_provider.dart';
import 'package:flutter_e_commerce/features/products/models/product.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class TestCartNotifier extends Cart {
  final List<CartItem> _items;
  TestCartNotifier(this._items);

  @override
  List<CartItem> build() => _items;
}

class TestCouponNotifier extends CouponNotifier {
  TestCouponNotifier(super.ref, CouponState initial) {
    state = initial;
  }
}

void main() {
  const product = Product(
    id: 1,
    slug: 'iphone-13',
    name: 'iPhone 13',
    shortDescription: 'Latest Apple iPhone',
    price: 100.0,
    thumbnail: 'https://example.com/iphone13.png',
    category: 'Electronics',
    brand: 'Apple',
    rating: 4.8,
  );
  const cartItems = [CartItem(product: product, quantity: 2, variantId: 7)];

  late MockOrderRepository repo;
  late ProviderContainer container;

  Future<void> pumpCheckout(
    WidgetTester tester, {
    CouponState coupon = const CouponState(),
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const CheckoutScreen(isGuest: true),
        ),
        GoRoute(
          path: '/order-success',
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>;
            return Scaffold(body: Text('SUCCESS ${extra['orderId']}'));
          },
        ),
      ],
    );

    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repo),
        cartProvider.overrideWith(() => TestCartNotifier(cartItems)),
        couponProvider.overrideWith((ref) => TestCouponNotifier(ref, coupon)),
      ],
    );
    addTearDown(container.dispose);
    // couponProvider is autoDispose; keep it alive after the screen unmounts.
    container.listen(couponProvider, (_, _) {});

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Form order: address, first name, last name, phone, email.
  Future<void> fillContact(WidgetTester tester, {String email = 'a@b.com'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Sok');
    await tester.enterText(fields.at(2), 'Dara');
    await tester.enterText(fields.at(3), '012345678');
    await tester.enterText(fields.at(4), email);
  }

  Future<void> selectCod(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.payments_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> tapPay(WidgetTester tester) async {
    final button = find.byType(ElevatedButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockOrderRepository();
  });

  group('CheckoutScreen', () {
    testWidgets('shows guest title and the total on the pay button', (tester) async {
      await pumpCheckout(tester);

      expect(find.text('Guest Checkout'), findsOneWidget);
      expect(find.text('Pay Now · \$200.00'), findsOneWidget);
    });

    testWidgets('applies coupon discount to the pay button total', (tester) async {
      await pumpCheckout(
        tester,
        coupon: const CouponState(code: 'SAVE20', discountAmount: 20, isApplied: true),
      );

      expect(find.text('Pay Now · \$180.00'), findsOneWidget);
    });

    testWidgets('blocks submit and shows errors when required fields are empty', (tester) async {
      await pumpCheckout(tester);
      await tester.enterText(find.byType(TextFormField).at(0), '');

      await tapPay(tester);

      expect(find.text('Address is required'), findsOneWidget);
      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Phone is required'), findsOneWidget);
      expect(find.text('Valid email required'), findsOneWidget);
      verifyNever(() => repo.submitCheckout(any()));
    });

    testWidgets('rejects an email without @', (tester) async {
      await pumpCheckout(tester);
      await fillContact(tester, email: 'not-an-email');

      await tapPay(tester);

      expect(find.text('Valid email required'), findsOneWidget);
      verifyNever(() => repo.submitCheckout(any()));
    });

    testWidgets('COD success sends payload, clears cart and opens success page', (tester) async {
      when(() => repo.submitCheckout(any())).thenAnswer(
        (_) async => {
          'status': true,
          'data': {'order_id': 555},
        },
      );
      await pumpCheckout(tester);
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);
      await tester.pumpAndSettle();

      final payload =
          verify(() => repo.submitCheckout(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(payload['first_name'], 'Sok');
      expect(payload['last_name'], 'Dara');
      expect(payload['phone'], '012345678');
      expect(payload['email'], 'a@b.com');
      expect(payload['gateway'], 'cod');
      expect(payload.containsKey('coupon_code'), isFalse);
      expect(payload['cart'], [
        {'product_id': 1, 'quantity': 2, 'variant_id': 7},
      ]);

      expect(container.read(cartProvider), isEmpty);
      expect(find.text('SUCCESS 555'), findsOneWidget);
    });

    testWidgets('includes coupon code in payload and resets coupon on success', (tester) async {
      when(() => repo.submitCheckout(any())).thenAnswer(
        (_) async => {
          'status': true,
          'data': {'order_id': 9},
        },
      );
      await pumpCheckout(
        tester,
        coupon: const CouponState(code: 'SAVE20', discountAmount: 20, isApplied: true),
      );
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);
      await tester.pumpAndSettle();

      final payload =
          verify(() => repo.submitCheckout(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(payload['coupon_code'], 'SAVE20');
      expect(container.read(couponProvider).isApplied, isFalse);
    });

    testWidgets('keeps cart and shows error when server returns status false', (tester) async {
      when(() => repo.submitCheckout(any()))
          .thenAnswer((_) async => {'status': false});
      await pumpCheckout(tester);
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);
      await tester.pumpAndSettle();

      expect(find.text('Failed to create order. Please try again.'), findsOneWidget);
      expect(container.read(cartProvider), isNotEmpty);
      expect(find.textContaining('SUCCESS'), findsNothing);
    });

    testWidgets('shows AppException message on API failure', (tester) async {
      when(() => repo.submitCheckout(any())).thenThrow(
        const NetworkException(message: 'No internet connection.'),
      );
      await pumpCheckout(tester);
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);
      await tester.pumpAndSettle();

      expect(find.text('No internet connection.'), findsOneWidget);
      expect(container.read(cartProvider), isNotEmpty);
    });

    testWidgets('shows a friendly message on timeout', (tester) async {
      when(() => repo.submitCheckout(any()))
          .thenThrow(const TimeoutException(message: 'timeout'));
      await pumpCheckout(tester);
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Order processing took longer than expected. Please check your Orders or try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows generic message on unexpected error', (tester) async {
      when(() => repo.submitCheckout(any())).thenThrow(StateError('boom'));
      await pumpCheckout(tester);
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred during checkout.'), findsOneWidget);
    });

    testWidgets('disables pay button while the request is in flight', (tester) async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => repo.submitCheckout(any())).thenAnswer((_) => completer.future);
      await pumpCheckout(tester);
      await selectCod(tester);
      await fillContact(tester);

      await tapPay(tester);

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete({'status': false});
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
    });
  });
}
