import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class AuthGateScreen extends StatelessWidget {
  /// The route to navigate to after the user chooses an option.
  final String returnTo;

  const AuthGateScreen({super.key, this.returnTo = '/checkout'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // ── Handle bar ──────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Glowing Logo & Header ─────────────────────────────
                      const SizedBox(height: 28),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/images/shopping.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.secureCheckout,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n.chooseHowYou,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: AppTheme.fontFamily,
                            color: theme.hintColor,
                            height: 1.45,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Options ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // 1. Login
                            _AuthOptionCard(
                              icon: Icons.login_rounded,
                              iconBgColor: theme.colorScheme.primary,
                              title: l10n.signIn,
                              subtitle: l10n.accessYourAccountSavedAddresses,
                              badgeLabel: l10n.returningCustomer,
                              badgeColor: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              badgeTextColor: theme.colorScheme.primary,
                              onTap: () {
                                Navigator.of(context).pop();
                                context.push(
                                  '/login',
                                  extra: {'returnTo': returnTo},
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // 2. Sign Up
                            _AuthOptionCard(
                              icon: Icons.person_add_rounded,
                              iconBgColor: theme.colorScheme.secondary,
                              title: l10n.createAccount,
                              subtitle: l10n.saveYourDetailsTrackOrders,
                              badgeLabel: l10n.newCustomer,
                              badgeColor: theme.colorScheme.secondary
                                  .withValues(alpha: 0.1),
                              badgeTextColor: theme.colorScheme.secondary,
                              onTap: () {
                                Navigator.of(context).pop();
                                context.push(
                                  '/register',
                                  extra: {'returnTo': returnTo},
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // 3. Guest Checkout
                            _AuthOptionCard(
                              icon: Icons.bolt_rounded,
                              iconBgColor: const Color(0xFF059669),
                              title: l10n.checkoutAsGuest,
                              subtitle: l10n.noAccountNeededJustEnter,
                              badgeLabel: l10n.fastestOption,
                              badgeColor: const Color(
                                0xFF059669,
                              ).withValues(alpha: 0.1),
                              badgeTextColor: const Color(0xFF059669),
                              onTap: () {
                                Navigator.of(context).pop();
                                context.push(
                                  returnTo,
                                  extra: {'isGuest': true},
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // ── "Why create an account?" divider ─────────
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    l10n.whyCreateAnAccount,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontFamily: AppTheme.fontFamily,
                                          color: theme.hintColor,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Benefits 2x2 Grid ─────────────────────────
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BenefitCard(
                                        icon: Icons.track_changes_rounded,
                                        label: l10n.trackOrders,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BenefitCard(
                                        icon: Icons.favorite_rounded,
                                        label: l10n.navWishlist,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BenefitCard(
                                        icon: Icons.local_offer_rounded,
                                        label: l10n.exclusiveDeals,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BenefitCard(
                                        icon: Icons.history_rounded,
                                        label: l10n.orderHistory,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _AuthOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeTextColor;
  final VoidCallback onTap;

  const _AuthOptionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon bubble (squircle style)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconBgColor, size: 24),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: badgeTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: AppTheme.fontFamily,
                          color: theme.hintColor,
                          height: 1.45,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.hintColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BenefitCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]!.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
