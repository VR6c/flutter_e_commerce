import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/splash_state.dart';

/// Indicates whether the splash initialization and display cycle is completed.
final splashCompletedProvider = StateProvider<bool>((ref) => false);

/// Provides the SplashNotifier instance with a configurable minimum display duration.
final splashMinDurationProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 1800);
});

final splashProvider = StateNotifierProvider<SplashNotifier, SplashState>((
  ref,
) {
  final minDuration = ref.watch(splashMinDurationProvider);
  return SplashNotifier(ref, minDuration: minDuration);
});

class SplashNotifier extends StateNotifier<SplashState> {
  final Ref _ref;
  final Duration minDuration;
  Timer? _delayTimer;

  SplashNotifier(
    this._ref, {
    this.minDuration = const Duration(milliseconds: 1800),
  }) : super(const SplashState());

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    if (state.status == SplashStatus.initializing ||
        state.status == SplashStatus.completed) {
      return;
    }

    state = state.copyWith(
      status: SplashStatus.initializing,
      message: 'Starting TVR',
      errorMessage: null,
    );

    try {
      final completer = Completer<void>();
      if (minDuration == Duration.zero) {
        completer.complete();
      } else {
        _delayTimer = Timer(minDuration, () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });
      }

      // 1. Session & Auth pre-warming
      state = state.copyWith(message: 'Loading...');
      try {
        await _ref
            .read(authStateProvider.future)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);
      } catch (_) {
        // Non-fatal for guest browsing; continue gracefully
      }

      // Ensure minimum display duration so animations display smoothly
      await completer.future;

      state = state.copyWith(message: 'Ready!');

      if (minDuration > Duration.zero) {
        await Future.delayed(const Duration(milliseconds: 250));
      }

      state = state.copyWith(status: SplashStatus.completed);
      _ref.read(splashCompletedProvider.notifier).state = true;
    } catch (e) {
      state = state.copyWith(
        status: SplashStatus.error,
        errorMessage: 'Unable to initialize the app. Please try again.',
      );
    }
  }

  Future<void> retry() async {
    _delayTimer?.cancel();
    state = const SplashState();
    await initialize();
  }

  void skipToGuest() {
    _delayTimer?.cancel();
    state = state.copyWith(status: SplashStatus.completed);
    _ref.read(splashCompletedProvider.notifier).state = true;
  }
}
