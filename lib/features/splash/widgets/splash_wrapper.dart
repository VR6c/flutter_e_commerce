import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/splash_provider.dart';
import '../screens/splash_screen.dart';

class SplashWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SplashWrapper({super.key, required this.child});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    final initiallyCompleted = ref.read(splashCompletedProvider);
    if (initiallyCompleted) {
      _dismissed = true;
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _dismissed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = ref.watch(splashCompletedProvider);

    if (isCompleted &&
        !_dismissed &&
        !_fadeController.isAnimating &&
        !_fadeController.isCompleted) {
      _fadeController.forward();
    }

    if (_dismissed) {
      return widget.child;
    }

    return Stack(
      children: [
        // The underlying app shell (mounted and ready)
        widget.child,

        // The splash overlay dissolving smoothly on top
        Positioned.fill(
          child: IgnorePointer(
            ignoring: isCompleted,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: const SplashScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
