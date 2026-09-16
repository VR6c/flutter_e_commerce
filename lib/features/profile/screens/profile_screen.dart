import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/models/customer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../models/social_media_link.dart';
import '../providers/social_media_link_provider.dart';
import '../widgets/account_details_sheet.dart';
import '../widgets/address_info_sheet.dart';
import '../widgets/avatar_options_sheet.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/help_support_sheet.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/logout_confirmation_sheet.dart';
import '../widgets/payment_methods_sheet.dart';
import '../widgets/privacy_terms_sheet.dart';
import '../../../shared/providers/bottom_nav_scroll_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $urlString'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid link: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.isKhmer ? 'បានចម្លង $label' : '$label copied to clipboard',
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getPlatformIcon(String platform) {
    final clean = platform.toLowerCase();
    if (clean.contains('facebook')) return Icons.facebook;
    if (clean.contains('twitter') || clean.contains('x')) {
      return Icons.alternate_email;
    }
    if (clean.contains('instagram')) return Icons.camera_alt;
    if (clean.contains('linkedin')) return Icons.work;
    if (clean.contains('youtube')) return Icons.play_arrow;
    return Icons.link;
  }

  Color _getPlatformColor(String platform) {
    final clean = platform.toLowerCase();
    if (clean.contains('facebook')) return const Color(0xFF1877F2);
    if (clean.contains('twitter') || clean.contains('x')) {
      return const Color(0xFF0F1419);
    }
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
          if (customerState.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                tooltip: 'Account Details',
                onPressed: () => _showAccountDetailsSheet(
                  context,
                  customerState.valueOrNull!,
                  theme,
                ),
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
                if (customerState.valueOrNull != null) {
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
                    if (customerState.valueOrNull == null)
                      _buildGuestHero(context, theme, isDark)
                    else
                      _buildUserHero(
                        context,
                        customerState.valueOrNull!,
                        theme,
                        isDark,
                      ),
                    const SizedBox(height: 16),

                    // Shopping Metrics (Orders, Wishlist, Cart)
                    if (customerState.valueOrNull != null) ...[
                      _buildShoppingMetrics(context, theme, isDark),
                      const SizedBox(height: 16),
                      _buildOrderStatusCard(context, theme, isDark),
                      const SizedBox(height: 16),
                    ],

                    // Group 1: Shopping & Account (when authenticated)
                    if (customerState.valueOrNull != null) ...[
                      _buildSectionHeader(l10n.shoppingAndAccount, theme),
                      _buildGroupContainer(
                        theme: theme,
                        isDark: isDark,
                        children: [
                          _buildMenuTile(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF4F46E5),
                            title: l10n.myOrders,
                            subtitle: l10n.trackOrdersSub,
                            theme: theme,
                            onTap: () => context.push(AppRoutes.orders),
                          ),
                          _buildTileDivider(theme),
                          _buildMenuTile(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFFD97706),
                            title: l10n.deliveryAddresses,
                            subtitle: l10n.deliveryAddressesSub,
                            theme: theme,
                            onTap: () => _showAddressInfoSheet(context, theme),
                          ),
                          _buildTileDivider(theme),
                          _buildMenuTile(
                            icon: Icons.credit_card_rounded,
                            iconColor: const Color(0xFF059669),
                            title: l10n.paymentMethods,
                            subtitle: l10n.paymentMethodsSub,
                            theme: theme,
                            onTap: () =>
                                _showPaymentMethodsSheet(context, theme),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Group 2: App Preferences
                    _buildSectionHeader(l10n.settingsPref, theme),
                    _buildGroupContainer(
                      theme: theme,
                      isDark: isDark,
                      children: [
                        _buildThemeToggleTile(theme, isDark),
                        _buildTileDivider(theme),
                        _buildNotificationToggleTile(theme, isDark),
                        _buildTileDivider(theme),
                        _buildMenuTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: l10n.languageAndCurrency,
                          subtitle: currentLocale.languageCode == 'km'
                              ? l10n.langKhmerSub
                              : l10n.langEnglishSub,
                          theme: theme,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentLocale.languageCode == 'km'
                                  ? 'KM / ៛'
                                  : 'EN / \$',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          onTap: () => _showLanguageSelectorSheet(
                            context,
                            theme,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Group 3: Support & About
                    _buildSectionHeader(l10n.supportLegal, theme),
                    _buildGroupContainer(
                      theme: theme,
                      isDark: isDark,
                      children: [
                        _buildMenuTile(
                          icon: Icons.headset_mic_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          title: l10n.helpCenterSupport,
                          subtitle: l10n.helpCenterSupportSub,
                          theme: theme,
                          onTap: () => _showHelpSupportSheet(context, theme),
                        ),
                        _buildTileDivider(theme),
                        _buildMenuTile(
                          icon: Icons.security_rounded,
                          iconColor: const Color(0xFF475569),
                          title: l10n.privacyTerms,
                          subtitle: l10n.privacyTermsSub,
                          theme: theme,
                          onTap: () => _showPrivacyTermsSheet(context, theme),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Group 4: Connect With Us
                    _buildSectionHeader(l10n.connectWithUs, theme),
                    _buildSocialCard(socialLinksState, theme, isDark),
                    const SizedBox(height: 24),

                    // Log Out / Session Action
                    if (customerState.valueOrNull != null) ...[
                      _buildLogoutButton(context, theme, isDark),
                      const SizedBox(height: 20),
                    ],

                    // Version Footer
                    _buildAppVersionFooter(theme),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
    );
  }

  // ── USER HERO CARD ─────────────────────────────────────────────────────────

  Widget _buildUserHero(
    BuildContext context,
    Customer customer,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient soft gradient background tint
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                            Colors.transparent,
                          ]
                        : [
                            theme.colorScheme.primary.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Interactive User Avatar with camera edit badge & tap action
                    UserAvatar(
                      radius: 36,
                      name: customer.name,
                      showEditBadge: true,
                      onTap: () => AvatarOptionsSheet.show(
                        context,
                        customerName: customer.name,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: context.l10n.isKhmer
                                        ? 0
                                        : -0.3,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showEditProfileSheet(
                                  context,
                                  customer,
                                  theme,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          GestureDetector(
                            onTap: () => _copyToClipboard(
                              customer.email,
                              context.l10n.isKhmer
                                  ? 'អាសយដ្ឋានអ៊ីមែល'
                                  : 'Email address',
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    customer.email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color:
                                      (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B))
                                          .withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Badges Row
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF23AA49,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF23AA49),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.l10n.verifiedMember,
                                      style: const TextStyle(
                                        color: Color(0xFF23AA49),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ID #${customer.id}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 12),

                // Quick Action Bar
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            _showAccountDetailsSheet(context, customer, theme),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.accountProfile,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 18,
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showAddressInfoSheet(context, theme),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.defaultAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GUEST HERO CARD ────────────────────────────────────────────────────────

  Widget _buildGuestHero(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  const Color(0xFF10B981).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.welcomeToApp,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: context.l10n.isKhmer ? 0 : -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.guestHeroSub,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Benefits Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBenefitItem(
                  Icons.local_shipping_outlined,
                  context.l10n.liveTracking,
                  theme,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _buildBenefitItem(
                  Icons.favorite_outline_rounded,
                  context.l10n.syncedWishlist,
                  theme,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _buildBenefitItem(
                  Icons.percent_rounded,
                  context.l10n.exclusiveDeals,
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      AppRoutes.login,
                      extra: {'returnTo': AppRoutes.profile},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.logIn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      AppRoutes.register,
                      extra: {'returnTo': AppRoutes.profile},
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.createAccount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ── SHOPPING METRICS ───────────────────────────────────────────────────────

  Widget _buildShoppingMetrics(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final ordersCount = ref.watch(
          ordersProvider.select((s) => s.valueOrNull?.length ?? 0),
        );
        final wishlistCount = ref.watch(wishlistCountProvider);
        final cartTotalQty = ref.watch(cartItemsCountProvider);

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                count: ordersCount.toString(),
                label: context.l10n.ordersMetric,
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF4F46E5),
                theme: theme,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                count: wishlistCount.toString(),
                label: context.l10n.wishlistMetric,
                icon: Icons.favorite_outline_rounded,
                iconColor: const Color(0xFFE11D48),
                theme: theme,
                isDark: isDark,
                onTap: () => context.go(AppRoutes.wishlist),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                count: cartTotalQty.toString(),
                label: context.l10n.inCartMetric,
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFF059669),
                theme: theme,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.cart),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ORDER STATUS SHORTCUT CARD ─────────────────────────────────────────────

  Widget _buildOrderStatusCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.recentOrders,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.orders),
                child: Row(
                  children: [
                    Text(
                      context.l10n.viewAll,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStatusItem(
                Icons.credit_card_outlined,
                context.l10n.toPay,
                theme,
                isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _buildOrderStatusItem(
                Icons.inventory_2_outlined,
                context.l10n.processingStatus,
                theme,
                isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _buildOrderStatusItem(
                Icons.local_shipping_outlined,
                context.l10n.shippedStatus,
                theme,
                isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _buildOrderStatusItem(
                Icons.assignment_turned_in_outlined,
                context.l10n.deliveredStatus,
                theme,
                isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusItem(
    IconData icon,
    String label,
    ThemeData theme,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GROUPED MENU COMPONENTS ────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTileDivider(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 58,
      endIndent: 16,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 20,
              color: const Color(0xFF0D9488),
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
                    fontSize: 14,
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
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              ref.read(themeModeProvider.notifier).toggleTheme(val);
            },
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggleTile(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: Color(0xFFE11D48),
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
                    fontSize: 14,
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
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() {
                _notificationsEnabled = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val
                        ? context.l10n.notificationsEnabledMsg
                        : context.l10n.notificationsDisabledMsg,
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // ── SOCIAL MEDIA CARD ──────────────────────────────────────────────────────

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
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
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
                  onTap: () => _launchUrl(link.link),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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

  // ── LOGOUT BUTTON & CONFIRMATION ───────────────────────────────────────────

  Widget _buildLogoutButton(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final customerState = ref.watch(authStateProvider);
    final isLoggingOut = customerState.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoggingOut
            ? null
            : () => _showLogoutConfirmationSheet(context, ref, theme),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
          backgroundColor: isDark
              ? const Color(0xFF2C1616).withValues(alpha: 0.6)
              : const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  void _showLogoutConfirmationSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    LogoutConfirmationSheet.show(context);
  }

  // ── BOTTOM SHEETS: ACCOUNT DETAILS, ADDRESS, SUPPORT, PRIVACY ─────────────

  void _showAccountDetailsSheet(
    BuildContext context,
    Customer customer,
    ThemeData theme,
  ) {
    AccountDetailsSheet.show(context, customer: customer);
  }

  void _showEditProfileSheet(
    BuildContext context,
    Customer customer,
    ThemeData theme,
  ) {
    EditProfileSheet.show(context, customer: customer);
  }

  void _showAddressInfoSheet(BuildContext context, ThemeData theme) {
    AddressInfoSheet.show(context);
  }

  void _showPaymentMethodsSheet(BuildContext context, ThemeData theme) {
    PaymentMethodsSheet.show(context);
  }

  void _showLanguageSelectorSheet(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    LanguageSelectorSheet.show(context);
  }

  void _showHelpSupportSheet(BuildContext context, ThemeData theme) {
    HelpSupportSheet.show(context);
  }

  void _showPrivacyTermsSheet(BuildContext context, ThemeData theme) {
    PrivacyTermsSheet.show(context);
  }

  // ── FOOTER ─────────────────────────────────────────────────────────────────

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
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
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
