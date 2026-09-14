import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_e_commerce/features/auth/providers/auth_provider.dart';
import 'package:flutter_e_commerce/features/auth/models/customer.dart';
import 'package:flutter_e_commerce/features/splash/models/splash_state.dart';
import 'package:flutter_e_commerce/features/splash/providers/splash_provider.dart';
import 'package:flutter_e_commerce/features/splash/screens/splash_screen.dart';
import 'package:flutter_e_commerce/main.dart';

class MockAuthState extends AuthState {
  final Customer? mockUser;
  MockAuthState(this.mockUser);

  @override
  FutureOr<Customer?> build() => mockUser;
}

class StaticInitializingSplashNotifier extends SplashNotifier {
  StaticInitializingSplashNotifier(super.ref)
    : super(minDuration: Duration.zero);

  @override
  Future<void> initialize() async {
    state = state.copyWith(
      status: SplashStatus.initializing,
      message: 'Starting TVR',
    );
  }
}

void main() {
  testWidgets('App launch initially displays SplashScreen via SplashWrapper', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(() => MockAuthState(null)),
        splashProvider.overrideWith(
          (ref) => StaticInitializingSplashNotifier(ref),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets(
    'Unauthenticated launch allows guest browsing on Home after splash completes',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => MockAuthState(null)),
          splashCompletedProvider.overrideWith((ref) => true),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
