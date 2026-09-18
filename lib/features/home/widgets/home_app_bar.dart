import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cart_icon_badge.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/delivery_location_provider.dart';
import 'location_selection_sheet.dart';

/// Modular, performant App Bar for the Home Screen.
/// Isolates customer and delivery location rebuilding scopes.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16,
      toolbarHeight: 66,
      title: Consumer(
        builder: (context, ref, _) {
          final customer = ref.watch(authStateProvider).valueOrNull;

          return Row(
            children: [
              UserAvatar(
                radius: 19,
                name: customer?.name,
                showBorder: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.profile);
                },
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer != null
                          ? l10n.greetingUser(customer.name.split(' ').first)
                          : l10n.welcomeToTvr,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        LocationSelectionSheet.show(context);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final locState = ref.watch(deliveryLocationProvider);
                                final selected = locState.selectedLocation;

                                final String displayText;
                                if (selected != null) {
                                  final streetPart = selected.street.split(',').first.trim();
                                  String labelText = selected.label;
                                  if (l10n.isKhmer) {
                                    final lower = labelText.toLowerCase().trim();
                                    if (lower == 'home') labelText = 'ផ្ទះ';
                                    if (lower == 'work') labelText = 'កន្លែងធ្វើការ';
                                    if (lower == 'office') labelText = 'ការិយាល័យ';
                                  }
                                  displayText = streetPart.isNotEmpty
                                      ? '$labelText · $streetPart'
                                      : labelText;
                                } else if (customer != null) {
                                  displayText = l10n.homeUserName(customer.name);
                                } else {
                                  displayText = l10n.selectLocation;
                                }

                                return Text(
                                  displayText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wishlist Shortcut Button
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.favorite_border_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  tooltip: 'Wishlist',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.wishlist);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Cart Button with Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const CartIconBadge(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
