import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_e_commerce/features/auth/providers/auth_provider.dart';
import 'package:flutter_e_commerce/features/auth/models/customer.dart';
import 'package:flutter_e_commerce/features/splash/models/splash_state.dart';
import 'package:flutter_e_commerce/features/splash/providers/splash_provider.dart';
import 'package:flutter_e_commerce/features/splash/screens/splash_screen.dart';

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

class FailingSplashNotifier extends SplashNotifier {
  FailingSplashNotifier(super.ref) : super(minDuration: Duration.zero);

  @override
  Future<void> initialize() async {
    state = state.copyWith(
      status: SplashStatus.error,
      errorMessage: 'Initialization failed',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashNotifier Unit Tests', () {
    test('initializes and completes successfully with zero duration', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => MockAuthState(null)),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
        ],
      );

      final notifier = container.read(splashProvider.notifier);
      expect(container.read(splashProvider).status, SplashStatus.initial);

      await notifier.initialize();

      expect(container.read(splashProvider).status, SplashStatus.completed);
      expect(container.read(splashCompletedProvider), true);
    });

    test('skipToGuest completes splash state immediately', () {
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith(() => MockAuthState(null))],
      );

      final notifier = container.read(splashProvider.notifier);
      notifier.skipToGuest();

      expect(container.read(splashProvider).status, SplashStatus.completed);
      expect(container.read(splashCompletedProvider), true);
    });

    test('retry resets state and restarts initialization', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => MockAuthState(null)),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
        ],
      );

      final notifier = container.read(splashProvider.notifier);
      await notifier.retry();

      expect(container.read(splashProvider).status, SplashStatus.completed);
      expect(container.read(splashCompletedProvider), true);
    });
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('renders brand title, tagline, version and logo', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          splashProvider.overrideWith(
            (ref) => StaticInitializingSplashNotifier(ref),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SplashScreen()),
        ),
      );

      // Fast forward entrance animations
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('TVR'), findsOneWidget);
      expect(find.text('Great quality and quick shipping'), findsOneWidget);
      expect(find.textContaining('v1.0.0'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'shows error state with Retry and Guest buttons when initialization fails',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            splashProvider.overrideWith((ref) => FailingSplashNotifier(ref)),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SplashScreen()),
          ),
        );

        await tester.pump(const Duration(milliseconds: 800));

        expect(find.text('Initialization failed'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.text('Continue as Guest'), findsOneWidget);
      },
    );

    testWidgets('tapping Continue as Guest calls skipToGuest', (tester) async {
      final container = ProviderContainer(
        overrides: [
          splashProvider.overrideWith((ref) => FailingSplashNotifier(ref)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SplashScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.text('Continue as Guest'));
      await tester.pump();

      expect(container.read(splashCompletedProvider), true);
    });
  });
}
