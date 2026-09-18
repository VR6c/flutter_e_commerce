import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/models/customer.dart';
import 'account_details_sheet.dart';
import 'address_info_sheet.dart';
import 'avatar_options_sheet.dart';
import 'edit_profile_sheet.dart';

/// User or Guest hero profile card.
class ProfileHeaderCard extends StatelessWidget {
  final Customer? customer;

  const ProfileHeaderCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (customer == null) {
      return _buildGuestHero(context, theme, isDark);
    }
    return _buildUserHero(context, customer!, theme, isDark);
  }

  Widget _buildUserHero(
    BuildContext context,
    Customer customer,
    ThemeData theme,
    bool isDark,
  ) {
    final l10n = context.l10n;

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
                                    letterSpacing: l10n.isKhmer ? 0 : -0.3,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => EditProfileSheet.show(
                                  context,
                                  customer: customer,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: customer.email));
                              AppSnackBar.showSuccess(
                                context,
                                l10n.emailCopiedToClipboard,
                              );
                            },
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    customer.email,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF23AA49).withValues(alpha: 0.12),
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
                                      l10n.verifiedMember,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        color: Color(0xFF23AA49),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ID #${customer.id}',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          AccountDetailsSheet.show(context, customer: customer);
                        },
                        icon: const Icon(Icons.badge_outlined, size: 16),
                        label: Text(l10n.accountProfile),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          AddressInfoSheet.show(context);
                        },
                        icon: const Icon(Icons.location_on_outlined, size: 16),
                        label: Text(l10n.defaultAddress),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildGuestHero(BuildContext context, ThemeData theme, bool isDark) {
    final l10n = context.l10n;

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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
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
            l10n.welcomeToApp,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: l10n.isKhmer ? 0 : -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.guestHeroSub,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
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
                  l10n.liveTracking,
                  theme,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                _buildBenefitItem(
                  Icons.favorite_outline_rounded,
                  l10n.syncedWishlist,
                  theme,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                _buildBenefitItem(
                  Icons.percent_rounded,
                  l10n.exclusiveDeals,
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
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(
                        AppRoutes.login,
                        extra: {'returnTo': AppRoutes.profile},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.logIn,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
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
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.register);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.createAccount,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
