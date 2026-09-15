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
import '../widgets/avatar_options_sheet.dart';
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
                        _buildMenuTile(
                          icon: Icons.auto_awesome_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: l10n.aiAssistant,
                          subtitle: l10n.aiAssistantSub,
                          theme: theme,
                          onTap: () => context.push(AppRoutes.aiAssistant),
                        ),
                        _buildTileDivider(theme),
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
                    onPressed: () => context.push(AppRoutes.login),
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
                    onPressed: () => context.push(AppRoutes.register),
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
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  context.l10n.signOut,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.signOutConfirmMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.l10n.cancel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(authStateProvider.notifier).logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.l10n.yesSignOut,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── BOTTOM SHEETS: ACCOUNT DETAILS, ADDRESS, SUPPORT, PRIVACY ─────────────

  void _showAccountDetailsSheet(
    BuildContext context,
    Customer customer,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isKhmer ? 'ព័ត៌មានលម្អិតគណនី' : 'Account Details',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        radius: 28,
                        name: customer.name,
                        showEditBadge: true,
                        onTap: () {
                          Navigator.pop(ctx);
                          AvatarOptionsSheet.show(
                            context,
                            customerName: customer.name,
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          AvatarOptionsSheet.show(
                            context,
                            customerName: customer.name,
                          );
                        },
                        child: Text(
                          l10n.isKhmer
                              ? 'ប្ដូររូបតំណាង / រូបថត'
                              : 'Change Avatar / Photo',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoDetailRow(
                  l10n.isKhmer ? 'ឈ្មោះពេញ' : 'Full Name',
                  customer.name,
                  theme,
                ),
                _buildInfoDetailRow(
                  l10n.isKhmer ? 'អាសយដ្ឋានអ៊ីមែល' : 'Email Address',
                  customer.email,
                  theme,
                  canCopy: true,
                ),
                _buildInfoDetailRow(
                  l10n.isKhmer ? 'លេខសម្គាល់អតិថិជន' : 'Customer ID',
                  '#${customer.id}',
                  theme,
                  canCopy: true,
                ),
                _buildInfoDetailRow(
                  l10n.isKhmer ? 'ស្ថានភាព' : 'Status',
                  l10n.isKhmer
                      ? (customer.status.toLowerCase() == 'active'
                            ? 'សកម្ម'
                            : customer.status)
                      : customer.status.toUpperCase(),
                  theme,
                  statusBadge: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.isKhmer ? 'បិទ' : 'Close',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditProfileSheet(context, customer, theme);
                          },
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            l10n.isKhmer ? 'កែសម្រួលព័ត៌មាន' : 'Edit Info',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    Customer customer,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final nameController = TextEditingController(text: customer.name);
    final emailController = TextEditingController(text: customer.email);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool changePassword = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.isKhmer
                                  ? 'កែសម្រួលព័ត៌មានគណនី'
                                  : 'Edit Profile',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFDC2626,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      color: const Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              UserAvatar(
                                radius: 36,
                                name: customer.name,
                                showEditBadge: true,
                                onTap: () => AvatarOptionsSheet.show(
                                  context,
                                  customerName: customer.name,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => AvatarOptionsSheet.show(
                                  context,
                                  customerName: customer.name,
                                ),
                                child: Text(
                                  l10n.isKhmer
                                      ? 'ចុចដើម្បីប្ដូររូបថត ឬរូបតំណាង'
                                      : 'Tap to change photo or avatar',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.isKhmer ? 'ឈ្មោះពេញ' : 'Full Name',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            letterSpacing: 0,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                            ),
                            hintText: l10n.isKhmer
                                ? 'បញ្ចូលឈ្មោះពេញរបស់អ្នក'
                                : 'Enter your full name',
                            hintStyle: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.isKhmer
                                  ? 'សូមបញ្ចូលឈ្មោះពេញ'
                                  : 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.isKhmer ? 'អាសយដ្ឋានអ៊ីមែល' : 'Email Address',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            letterSpacing: 0,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            hintText: l10n.isKhmer
                                ? 'បញ្ចូលអាសយដ្ឋានអ៊ីមែលរបស់អ្នក'
                                : 'Enter your email address',
                            hintStyle: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.isKhmer
                                  ? 'សូមបញ្ចូលអ៊ីមែល'
                                  : 'Email is required';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return l10n.isKhmer
                                  ? 'សូមបញ្ចូលអ៊ីមែលឱ្យបានត្រឹមត្រូវ'
                                  : 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Change Password toggle
                        InkWell(
                          onTap: () {
                            setSheetState(() {
                              changePassword = !changePassword;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  changePassword
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.isKhmer
                                      ? 'ប្តូរពាក្យសម្ងាត់'
                                      : 'Change Password',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (changePassword) ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrent,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              hintText: l10n.isKhmer
                                  ? 'ពាក្យសម្ងាត់បច្ចុប្បន្ន'
                                  : 'Current Password',
                              hintStyle: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                letterSpacing: 0,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureCurrent
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setSheetState(() {
                                    obscureCurrent = !obscureCurrent;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (changePassword &&
                                  (val == null || val.isEmpty)) {
                                return l10n.isKhmer
                                    ? 'សូមបញ្ចូលពាក្យសម្ងាត់បច្ចុប្បន្ន'
                                    : 'Current password is required to change password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNew,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_reset_rounded,
                                size: 20,
                              ),
                              hintText: l10n.isKhmer
                                  ? 'ពាក្យសម្ងាត់ថ្មី (យ៉ាងតិច ៦ តួអក្សរ)'
                                  : 'New Password (min 6 characters)',
                              hintStyle: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                letterSpacing: 0,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setSheetState(() {
                                    obscureNew = !obscureNew;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (changePassword) {
                                if (val == null || val.length < 6) {
                                  return l10n.isKhmer
                                      ? 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ'
                                      : 'New password must be at least 6 characters';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirm,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_reset_rounded,
                                size: 20,
                              ),
                              hintText: l10n.isKhmer
                                  ? 'ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់ថ្មី'
                                  : 'Confirm New Password',
                              hintStyle: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                letterSpacing: 0,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setSheetState(() {
                                    obscureConfirm = !obscureConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (changePassword &&
                                  val != newPasswordController.text) {
                                return l10n.isKhmer
                                    ? 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ'
                                    : 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.isKhmer ? 'បោះបង់' : 'Cancel',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          setSheetState(() {
                                            isSaving = true;
                                            errorMessage = null;
                                          });
                                          try {
                                            await ref
                                                .read(
                                                  authStateProvider.notifier,
                                                )
                                                .updateProfile(
                                                  name: nameController.text
                                                      .trim(),
                                                  email: emailController.text
                                                      .trim(),
                                                  currentPassword:
                                                      changePassword
                                                      ? currentPasswordController
                                                            .text
                                                      : null,
                                                  newPassword: changePassword
                                                      ? newPasswordController
                                                            .text
                                                      : null,
                                                  newPasswordConfirmation:
                                                      changePassword
                                                      ? confirmPasswordController
                                                            .text
                                                      : null,
                                                );
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                            }
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        l10n.isKhmer
                                                            ? 'បានកែសម្រួលព័ត៌មានគណនីជោគជ័យ!'
                                                            : 'Profile updated successfully!',
                                                        style: const TextStyle(
                                                          fontFamily: AppTheme
                                                              .fontFamily,
                                                          letterSpacing: 0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFF23AA49,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setSheetState(() {
                                              isSaving = false;
                                              errorMessage = e
                                                  .toString()
                                                  .replaceAll('Exception:', '')
                                                  .trim();
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          l10n.isKhmer
                                              ? 'រក្សាទុកការផ្លាស់ប្តូរ'
                                              : 'Save Changes',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoDetailRow(
    String label,
    String value,
    ThemeData theme, {
    bool canCopy = false,
    bool statusBadge = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              letterSpacing: 0,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (statusBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF23AA49).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: Color(0xFF23AA49),
                ),
              ),
            )
          else
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _copyToClipboard(value, label),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showAddressInfoSheet(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isKhmer ? 'អាសយដ្ឋានដឹកជញ្ជូន' : 'Delivery Address',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: Color(0xFF23AA49),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.isKhmer
                                ? 'ផ្ទះ (អាសយដ្ឋានលំនាំដើម)'
                                : 'Home (Default Delivery)',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.isKhmer
                            ? 'រាជធានីភ្នំពេញ, កម្ពុជា\nផ្លូវ ២៧១, សង្កាត់បឹងទំពន់'
                            : 'Phnom Penh City, Cambodia\nStreet 271, Sangkat Boeung Tumpun',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          letterSpacing: 0,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.isKhmer ? 'រួចរាល់' : 'Done',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentMethodsSheet(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isKhmer ? 'ជម្រើសទូទាត់' : 'Payment Options',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPaymentOptionTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'ABA PayWay / KHQR',
                  subtitle: l10n.isKhmer
                      ? 'ការទូទាត់រហ័ស និងមានសុវត្ថិភាពខ្ពស់'
                      : 'Fast and secure contactless checkout',
                  theme: theme,
                  isDark: isDark,
                  isDefault: true,
                ),
                const SizedBox(height: 10),
                _buildPaymentOptionTile(
                  icon: Icons.money_rounded,
                  title: l10n.isKhmer
                      ? 'ទូទាត់ពេលទទួលទំនិញ (COD)'
                      : 'Cash on Delivery (COD)',
                  subtitle: l10n.isKhmer
                      ? 'បង់ប្រាក់សុទ្ធនៅពេលទំនិញត្រូវបានដឹកជញ្ជូនដល់'
                      : 'Pay cash when items are delivered',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.isKhmer ? 'រួចរាល់' : 'Done',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required bool isDark,
    bool isDefault = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF23AA49,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF23AA49),
                          ),
                        ),
                      ),
                    ],
                  ],
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
        ],
      ),
    );
  }

  void _showLanguageSelectorSheet(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final currentLocale = ref.read(localeProvider);
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.selectLanguage,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLanguageOptionItem(
                  theme: theme,
                  isDark: isDark,
                  title: 'ភាសាខ្មែរ (Khmer)',
                  subtitle: 'ភាសាខ្មែរ · USD (\$)',
                  flagEmoji: '🇰🇭',
                  isSelected: currentLocale.languageCode == 'km',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('km'));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.languageChanged),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildLanguageOptionItem(
                  theme: theme,
                  isDark: isDark,
                  title: 'English (US)',
                  subtitle: 'English · USD (\$)',
                  flagEmoji: '🇺🇸',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en'));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.languageChanged),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOptionItem({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String subtitle,
    required String flagEmoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
        : (isDark ? const Color(0xFF131D38) : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(flagEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
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
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportSheet(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isKm = context.l10n.isKhmer;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.headset_mic_outlined,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isKm ? 'ផ្នែកបម្រើអតិថិជន' : 'Customer Support',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildContactRow(
                  Icons.phone_in_talk_rounded,
                  isKm ? 'ខ្សែទូរស័ព្ទទាន់ហេតុការណ៍' : 'Hotline Support',
                  '+855 (0) 23 999 888',
                  () => _launchUrl('tel:+85523999888'),
                  theme,
                  isDark,
                ),
                const SizedBox(height: 10),
                _buildContactRow(
                  Icons.email_outlined,
                  isKm ? 'អ៊ីមែលជំនួយ' : 'Support Email',
                  'support@freshcart.store',
                  () => _launchUrl('mailto:support@freshcart.store'),
                  theme,
                  isDark,
                ),
                const SizedBox(height: 10),
                _buildContactRow(
                  Icons.chat_bubble_outline_rounded,
                  isKm ? 'ឆាតផ្ទាល់តាម Telegram' : 'Live Chat Telegram',
                  '@TVRSupport',
                  () => _launchUrl('https://t.me/reak6c'),
                  theme,
                  isDark,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isKm ? 'បិទ' : 'Close',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String title,
    String detail,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      letterSpacing: 0,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyTermsSheet(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isKm = context.l10n.isKhmer;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF475569).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isKm ? 'ឯកជនភាព & លក្ខខណ្ឌ' : 'Privacy & Terms',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isKm
                      ? 'ឯកជនភាព និងសុវត្ថិភាពទិន្នន័យរបស់អ្នក គឺជាអាទិភាពចម្បងរបស់យើង។ រាល់ប្រតិបត្តិការទូទាត់ទាំងអស់ត្រូវបានការពារ និងអ៊ិនគ្រីបតាមប្រព័ន្ធសុវត្ថិភាពធនាគារកម្រិតខ្ពស់។ យើងមិនរក្សាទុកលេខសម្ងាត់កាតធនាគារផ្ទាល់ខ្លួនរបស់អ្នកឡើយ។'
                      : 'Your privacy and data security are our top priorities. All payment transactions are encrypted end-to-end via secure banking gateways. We do not store your raw credit card credentials.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isKm
                      ? 'តាមរយៈការប្រើប្រាស់កម្មវិធី TVR អ្នកយល់ព្រមតាមលក្ខខណ្ឌប្រើប្រាស់ជាមូលដ្ឋាន គោលការណ៍នៃការប្រើប្រាស់សមរម្យ និងសិទ្ធិការពារអ្នកប្រើប្រាស់របស់យើង។'
                      : 'By using the TVR app, you agree to our standard terms of service, fair usage policies, and consumer return guidelines.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isKm ? 'ខ្ញុំយល់ព្រម' : 'I Understand',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
