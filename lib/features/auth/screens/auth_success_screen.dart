import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';

class AuthSuccessScreen extends ConsumerStatefulWidget {
  final String userName;
  final String returnTo;

  const AuthSuccessScreen({
    super.key,
    required this.userName,
    this.returnTo = AppRoutes.home,
  });

  @override
  ConsumerState<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends ConsumerState<AuthSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _countdownTimer;
  int _secondsRemaining = 4;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _proceed();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _proceed() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _countdownTimer?.cancel();
    context.go(widget.returnTo.isNotEmpty ? widget.returnTo : AppRoutes.home);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final isCheckoutReturn = widget.returnTo == AppRoutes.checkout;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _proceed();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // ── Animated Celebration Badge ───────────────────────
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer subtle glow pulse
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.15 : 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.25 : 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Inner solid emerald badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                AppTheme.secondaryColor,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                        // Floating star accent badge
                        Positioned(
                          top: 14,
                          right: 18,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF131D38) : Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Titles & Welcome Message ──────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        l10n.accountCreatedTitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (widget.userName.isNotEmpty)
                        Text(
                          l10n.welcomeUser(widget.userName),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.accountReadySub,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontSize: 13.5,
                          height: 1.45,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // ── Perks Card ─────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildPerkRow(
                          context,
                          icon: Icons.electric_bolt_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: l10n.perkDeliveryTitle,
                          subtitle: l10n.perkDeliverySub,
                          isDark: isDark,
                        ),
                        Divider(
                          height: 20,
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        _buildPerkRow(
                          context,
                          icon: Icons.eco_rounded,
                          iconColor: theme.colorScheme.primary,
                          title: l10n.perkFreshTitle,
                          subtitle: l10n.perkFreshSub,
                          isDark: isDark,
                        ),
                        Divider(
                          height: 20,
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        _buildPerkRow(
                          context,
                          icon: Icons.card_giftcard_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: l10n.perkDealsTitle,
                          subtitle: l10n.perkDealsSub,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Auto Redirect Indicator ────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.redirectingIn(_secondsRemaining),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Primary Action Button ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCheckoutReturn
                              ? l10n.proceedToCheckout
                              : l10n.startShopping,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Secondary Action: Back to Home ─────────────────────
                if (isCheckoutReturn)
                  TextButton(
                    onPressed: () {
                      _navigated = true;
                      _countdownTimer?.cancel();
                      context.go(AppRoutes.home);
                    },
                    child: Text(
                      l10n.backToHome,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
