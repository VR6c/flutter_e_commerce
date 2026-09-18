import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../models/splash_state.dart';
import '../providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // ── Entrance Animation Setup ──────────────────────────────────────────
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // ── Pulsing Aura Animation Setup ─────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();

    // ── Start Initialization ──────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(splashProvider.notifier).initialize();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final splashState = ref.watch(splashProvider);

    // Navigate to Home upon successful completion if on standalone /splash route
    ref.listen<SplashState>(splashProvider, (previous, next) {
      if (next.status == SplashStatus.completed && mounted) {
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          try {
            final loc = GoRouterState.of(context).matchedLocation;
            if (loc == AppRoutes.splash) {
              router.go(AppRoutes.home);
            }
          } catch (_) {
            // Handled seamlessly by SplashWrapper
          }
        }
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [AppTheme.darkBackground, AppTheme.darkSurface]
                    : [Colors.white, AppTheme.lightBackground],
              ),
            ),
          ),

          // ── Ambient Glow Background Orb ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(
                          alpha: isDark ? 0.12 : 0.08,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Main Content Column ──────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // ── Glowing Animated Brand Logo ───────────────────────
                    RepaintBoundary(
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, staticChild) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer breathing ring
                                  Container(
                                    width: 130 * _pulseAnimation.value,
                                    height: 130 * _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  ?staticChild,
                                ],
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Mid ring
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                ),
                                // Core circle with shopping badge
                                Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? AppTheme.darkSurface
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: isDark ? 0.35 : 0.25,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Image.asset(
                                    'assets/images/shopping.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── App Title & Tagline ─────────────────────────────────
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: SlideTransition(
                        position: _contentSlideAnimation,
                        child: Column(
                          children: [
                            Text(
                              'TVR',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                color: isDark
                                    ? AppTheme.darkOnSurface
                                    : AppTheme.lightOnSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.greatQualityAndQuickShipping,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.darkSubtext
                                    : AppTheme.lightSubtext,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── Dynamic Status / Error Panel ────────────────────────
                    if (splashState.status == SplashStatus.error) ...[
                      _buildErrorWidget(context, splashState),
                    ] else ...[
                      _buildLoadingIndicator(context, splashState),
                    ],

                    const Spacer(flex: 2),

                    // ── Version & Footer Branding ───────────────────────────
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          context.l10n.v100FastSecureDelivery,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: AppTheme.fontFamily,
                            color:
                                (isDark
                                        ? AppTheme.darkSubtext
                                        : AppTheme.lightSubtext)
                                    .withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, SplashState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    String displayMessage = state.message;
    if (state.message.contains('Wait') || state.message.contains('minute')) {
      displayMessage = l10n.splashPleaseWait;
    } else if (state.message.contains('Starting')) {
      displayMessage = l10n.splashStarting;
    } else if (state.message.contains('Ready')) {
      displayMessage = l10n.splashReady;
    }

    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: isDark
                    ? AppTheme.darkBorderStrong
                    : AppTheme.primaryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              displayMessage,
              key: ValueKey<String>(displayMessage),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, SplashState state) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final String errorText = state.errorMessage ?? l10n.splashInitError;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  errorText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: AppTheme.fontFamily,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(splashProvider.notifier).retry();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  l10n.tryAgain,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  ref.read(splashProvider.notifier).skipToGuest();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  l10n.continueAsGuest,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
