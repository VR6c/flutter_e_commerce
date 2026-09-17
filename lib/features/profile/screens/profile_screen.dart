import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../models/social_media_link.dart';
import '../providers/social_media_link_provider.dart';
import '../widgets/account_details_sheet.dart';
import '../widgets/address_info_sheet.dart';
import '../widgets/help_support_sheet.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/logout_confirmation_sheet.dart';
import '../widgets/payment_methods_sheet.dart';
import '../widgets/privacy_terms_sheet.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_orders_card.dart';
import '../widgets/profile_settings_group.dart';
import '../../../shared/providers/bottom_nav_scroll_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not open link: $urlString');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Invalid link: $urlString');
      }
    }
  }

  IconData _getPlatformIcon(String platform) {
    final clean = platform.toLowerCase();
    if (clean.contains('facebook')) return Icons.facebook;
    if (clean.contains('twitter') || clean.contains('x')) return Icons.alternate_email;
    if (clean.contains('instagram')) return Icons.camera_alt;
    if (clean.contains('linkedin')) return Icons.work;
    if (clean.contains('youtube')) return Icons.play_arrow;
    return Icons.link;
  }

  Color _getPlatformColor(String platform) {
    final clean = platform.toLowerCase();
    if (clean.contains('facebook')) return const Color(0xFF1877F2);
    if (clean.contains('twitter') || clean.contains('x')) return const Color(0xFF0F1419);
    if (clean.contains('instagram')) return const Color(0xFFE4405F);
    if (clean.contains('linkedin')) return const Color(0xFF0A66C2);
    if (clean.contains('youtube')) return const Color(0xFFFF0000);
    return const Color(0xFF23AA49);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BottomNavScrollEvent>(bottomNavScrollProvider, (previous, next) {
      if (next.tabIndex == 3 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final customerState = ref.watch(authStateProvider);
    final socialLinksState = ref.watch(socialMediaLinksProvider);
    final currentLocale = ref.watch(localeProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customer = customerState.valueOrNull;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            l10n.profileTitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: l10n.isKhmer ? 0 : -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          if (customer != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                tooltip: 'Account Details',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  AccountDetailsSheet.show(context, customer: customer);
                },
              ),
            ),
        ],
      ),
      body: customerState.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: () async {
                ref.invalidate(socialMediaLinksProvider);
                if (customer != null) {
                  ref.invalidate(ordersProvider);
                }
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Header card (User or Guest hero)
                    ProfileHeaderCard(customer: customer),
                    const SizedBox(height: 16),

                    // Shopping Metrics & Order Pipeline (for authenticated user)
                    if (customer != null) ...[
                      const ProfileShoppingMetricsCard(),
                      const SizedBox(height: 16),
                      const ProfileOrderStatusCard(),
                      const SizedBox(height: 16),
                    ],

                    // Group 1: Shopping & Account (when authenticated)
                    if (customer != null) ...[
                      ProfileSectionHeader(title: l10n.shoppingAndAccount),
                      ProfileGroupContainer(
                        children: [
                          ProfileMenuTile(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF4F46E5),
                            title: l10n.myOrders,
                            subtitle: l10n.trackOrdersSub,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push(AppRoutes.orders);
                            },
                          ),
                          const ProfileTileDivider(),
                          ProfileMenuTile(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFFD97706),
                            title: l10n.deliveryAddresses,
                            subtitle: l10n.deliveryAddressesSub,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              AddressInfoSheet.show(context);
                            },
                          ),
                          const ProfileTileDivider(),
                          ProfileMenuTile(
                            icon: Icons.credit_card_rounded,
                            iconColor: const Color(0xFF059669),
                            title: l10n.paymentMethods,
                            subtitle: l10n.paymentMethodsSub,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              PaymentMethodsSheet.show(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Group 2: App Preferences
                    ProfileSectionHeader(title: l10n.settingsPref),
                    ProfileGroupContainer(
                      children: [
                        _buildThemeToggleTile(theme, isDark),
                        const ProfileTileDivider(),
                        _buildNotificationToggleTile(theme, isDark),
                        const ProfileTileDivider(),
                        ProfileMenuTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: l10n.languageAndCurrency,
                          subtitle: currentLocale.languageCode == 'km'
                              ? l10n.langKhmerSub
                              : l10n.langEnglishSub,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentLocale.languageCode == 'km' ? 'KM / ៛' : 'EN / \$',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            LanguageSelectorSheet.show(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Group 3: Support & Legal
                    ProfileSectionHeader(title: l10n.supportLegal),
                    ProfileGroupContainer(
                      children: [
                        ProfileMenuTile(
                          icon: Icons.headset_mic_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          title: l10n.helpCenterSupport,
                          subtitle: l10n.helpCenterSupportSub,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            HelpSupportSheet.show(context);
                          },
                        ),
                        const ProfileTileDivider(),
                        ProfileMenuTile(
                          icon: Icons.security_rounded,
                          iconColor: const Color(0xFF475569),
                          title: l10n.privacyTerms,
                          subtitle: l10n.privacyTermsSub,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            PrivacyTermsSheet.show(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Group 4: Connect With Us
                    ProfileSectionHeader(title: l10n.connectWithUs),
                    _buildSocialCard(socialLinksState, theme, isDark),
                    const SizedBox(height: 24),

                    // Logout Button (for authenticated user)
                    if (customer != null) ...[
                      _buildLogoutButton(context, theme, isDark),
                      const SizedBox(height: 20),
                    ],

                    // App Version Footer
                    _buildAppVersionFooter(theme),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildThemeToggleTile(ThemeData theme, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);
    final isSystem = themeMode == ThemeMode.system;
    final isCurrentlyDark = themeMode == ThemeMode.dark ||
        (isSystem && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCurrentlyDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: const Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.darkMode,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark
                      ? context.l10n.darkModeActive
                      : context.l10n.switchToDark,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isCurrentlyDark,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              ref.read(themeModeProvider.notifier).toggleTheme(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggleTile(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.pushNotifications,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _notificationsEnabled
                      ? context.l10n.notificationsEnabledSub
                      : context.l10n.notificationsPausedSub,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _notificationsEnabled,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _notificationsEnabled = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard(
    AsyncValue<List<SocialMediaLink>> socialLinksState,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: AsyncValueWidget(
        value: socialLinksState,
        loading: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        onRetry: () => ref.invalidate(socialMediaLinksProvider),
        data: (links) {
          if (links.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.l10n.noSocialLinks,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: links.map((link) {
              final color = _getPlatformColor(link.platform);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _launchUrl(link.link);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPlatformIcon(link.platform),
                          color: color,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          link.platform,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme, bool isDark) {
    final isLoggingOut = ref.watch(authStateProvider).isLoading;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoggingOut
            ? null
            : () {
                HapticFeedback.lightImpact();
                LogoutConfirmationSheet.show(context);
              },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
          backgroundColor: isDark
              ? const Color(0xFF2C1616).withValues(alpha: 0.6)
              : const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoggingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.signOut,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppVersionFooter(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isKm = context.l10n.isKhmer;

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_bag_rounded,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'TVR Mobile',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isKm
                ? 'ជំនាន់ 1.0.0 (Build 2026.1) • រក្សាសិទ្ធិគ្រប់យ៉ាង'
                : 'Version 1.0.0 (Build 2026.1) • All rights reserved',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              letterSpacing: 0,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFA1A1AA),
            ),
          ),
        ],
      ),
    );
  }
}
