import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_e_commerce/features/auth/models/customer.dart';
import 'package:flutter_e_commerce/features/auth/providers/auth_provider.dart';
import 'package:flutter_e_commerce/features/cart/models/cart_item.dart';
import 'package:flutter_e_commerce/features/cart/providers/cart_provider.dart';
import 'package:flutter_e_commerce/features/orders/models/order.dart';
import 'package:flutter_e_commerce/features/orders/providers/orders_provider.dart';
import 'package:flutter_e_commerce/features/products/models/product.dart';
import 'package:flutter_e_commerce/features/profile/models/social_media_link.dart';
import 'package:flutter_e_commerce/features/profile/providers/social_media_link_provider.dart';
import 'package:flutter_e_commerce/features/profile/screens/profile_screen.dart';
import 'package:flutter_e_commerce/features/wishlist/providers/wishlist_provider.dart';
import 'package:flutter_e_commerce/core/localization/app_localizations.dart';

class TestAuthStateNotifier extends AuthState {
  final Customer? _initialCustomer;
  TestAuthStateNotifier(this._initialCustomer);

  @override
  FutureOr<Customer?> build() => _initialCustomer;

  @override
  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }

  @override
  Future<Customer> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    final updated = Customer(
      id: _initialCustomer?.id ?? 1,
      name: name,
      email: email,
      status: _initialCustomer?.status ?? 'active',
    );
    state = AsyncValue.data(updated);
    return updated;
  }
}

class TestSocialMediaLinksNotifier extends SocialMediaLinks {
  final List<SocialMediaLink> _links;
  TestSocialMediaLinksNotifier([this._links = const []]);

  @override
  FutureOr<List<SocialMediaLink>> build() => _links;
}

class TestOrdersNotifier extends Orders {
  final List<Order> _orders;
  TestOrdersNotifier([this._orders = const []]);

  @override
  FutureOr<List<Order>> build() => _orders;
}

class TestWishlistNotifier extends Wishlist {
  final List<Product> _items;
  TestWishlistNotifier([this._items = const []]);

  @override
  List<Product> build() => _items;
}

class TestCartNotifier extends Cart {
  final List<CartItem> _items;
  TestCartNotifier([this._items = const []]);

  @override
  List<CartItem> build() => _items;
}

void main() {
  const testCustomer = Customer(
    id: 101,
    name: 'Thary Vireak',
    email: 'tharyvireak171@gmail.com',
    status: 'active',
  );

  Widget createSubject({
    Customer? customer,
    List<SocialMediaLink> links = const [],
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => TestAuthStateNotifier(customer)),
        socialMediaLinksProvider.overrideWith(
          () => TestSocialMediaLinksNotifier(links),
        ),
        ordersProvider.overrideWith(() => TestOrdersNotifier()),
        wishlistProvider.overrideWith(() => TestWishlistNotifier()),
        cartProvider.overrideWith(() => TestCartNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders guest mode when not signed in', (tester) async {
      await tester.pumpWidget(createSubject(customer: null));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Welcome to TVR'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Live Tracking'), findsOneWidget);
      expect(find.text('Synced Wishlist'), findsOneWidget);
      expect(find.text('Exclusive Deals'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Help Center & Support'), findsOneWidget);
      expect(find.text('TVR Mobile'), findsOneWidget);
    });

    testWidgets(
      'renders authenticated profile with user details and shopping metrics',
      (tester) async {
        await tester.pumpWidget(createSubject(customer: testCustomer));
        await tester.pumpAndSettle();

        expect(find.text('Thary Vireak'), findsOneWidget);
        expect(find.text('tharyvireak171@gmail.com'), findsOneWidget);
        expect(find.text('Verified Member'), findsOneWidget);
        expect(find.text('ID #101'), findsOneWidget);

        // Shopping metrics
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Wishlist'), findsOneWidget);
        expect(find.text('In Cart'), findsOneWidget);

        // Order status shortcuts
        expect(find.text('Recent Orders'), findsOneWidget);
        expect(find.text('To Pay'), findsOneWidget);
        expect(find.text('Processing'), findsOneWidget);
        expect(find.text('Shipped'), findsOneWidget);
        expect(find.text('Delivered'), findsOneWidget);

        // Grouped sections
        expect(find.text('SHOPPING & ACCOUNT'), findsOneWidget);
        expect(find.text('Delivery Addresses'), findsOneWidget);
        expect(find.text('Payment Methods'), findsOneWidget);
        expect(find.text('SETTINGS & PREFERENCES'), findsOneWidget);
        expect(find.text('SUPPORT & LEGAL'), findsOneWidget);
        expect(find.text('CONNECT WITH US'), findsOneWidget);

        // Logout button
        expect(find.text('Sign Out'), findsOneWidget);
      },
    );

    testWidgets('clicking sign out displays confirmation bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(customer: testCustomer));
      await tester.pumpAndSettle();

      // Tap Sign Out button (ensure visible in scroll view)
      final signOutFinder = find.widgetWithText(OutlinedButton, 'Sign Out');
      expect(signOutFinder, findsOneWidget);
      await tester.ensureVisible(signOutFinder);
      await tester.pumpAndSettle();
      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      // Bottom sheet confirmation should appear
      expect(
        find.text(
          'Are you sure you want to sign out? You will need to log back in to access your orders and account settings.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Yes, Sign Out'), findsOneWidget);

      // Tap Cancel closes sheet
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('clicking account profile button opens account details sheet', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(customer: testCustomer));
      await tester.pumpAndSettle();

      final accountProfileBtn = find.text('Account Profile');
      expect(accountProfileBtn, findsOneWidget);
      await tester.tap(accountProfileBtn);
      await tester.pumpAndSettle();

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Customer ID'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Edit Info'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Account Details'), findsNothing);
    });

    testWidgets('tapping Edit Info button opens Edit Profile sheet', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(customer: testCustomer));
      await tester.pumpAndSettle();

      final accountProfileBtn = find.text('Account Profile');
      await tester.tap(accountProfileBtn);
      await tester.pumpAndSettle();

      final editInfoBtn = find.text('Edit Info');
      expect(editInfoBtn, findsOneWidget);
      await tester.tap(editInfoBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Profile'), findsNothing);
    });
  });
}
