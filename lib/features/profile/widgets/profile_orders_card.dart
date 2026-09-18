import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';

/// Isolated Shopping Metrics Card (Orders, Wishlist, Cart counts).
class ProfileShoppingMetricsCard extends ConsumerWidget {
  const ProfileShoppingMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final ordersCount = ref.watch(ordersProvider.select((o) => o.valueOrNull?.length ?? 0));
    final wishlistCount = ref.watch(wishlistProvider.select((w) => w.length));
    final cartCount = ref.watch(cartProvider.select((c) => c.length));

    return RepaintBoundary(
      child: Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _metricItem(
            count: '$ordersCount',
            label: l10n.ordersMetric,
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF4F46E5),
            onTap: () => context.push(AppRoutes.orders),
            theme: theme,
            isDark: isDark,
          ),
          _divider(isDark),
          _metricItem(
            count: '$wishlistCount',
            label: l10n.wishlistMetric,
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEF4444),
            onTap: () => context.go(AppRoutes.wishlist),
            theme: theme,
            isDark: isDark,
          ),
          _divider(isDark),
          _metricItem(
            count: '$cartCount',
            label: l10n.inCartMetric,
            icon: Icons.shopping_bag_rounded,
            iconColor: theme.colorScheme.primary,
            onTap: () => context.push(AppRoutes.cart),
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      height: 36,
      width: 1,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
    );
  }

  Widget _metricItem({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  count,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Order Pipeline Status Tracker Card.
class ProfileOrderStatusCard extends ConsumerWidget {
  const ProfileOrderStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final orders = ref.watch(ordersProvider).valueOrNull ?? [];

    final statusCounts = <String, int>{
      'pending': 0,
      'processing': 0,
      'shipped': 0,
      'delivered': 0,
    };
    for (final order in orders) {
      final s = order.status.toLowerCase();
      if (s == 'completed') {
        statusCounts['delivered'] = (statusCounts['delivered'] ?? 0) + 1;
      } else if (statusCounts.containsKey(s)) {
        statusCounts[s] = statusCounts[s]! + 1;
      }
    }

    return RepaintBoundary(
      child: Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentOrders,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.orders);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        l10n.viewAll,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusItem(
                icon: Icons.hourglass_top_rounded,
                label: l10n.toPay,
                count: statusCounts['pending'] ?? 0,
                theme: theme,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _statusItem(
                icon: Icons.inventory_2_outlined,
                label: l10n.processingStatus,
                count: statusCounts['processing'] ?? 0,
                theme: theme,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _statusItem(
                icon: Icons.local_shipping_outlined,
                label: l10n.shippedStatus,
                count: statusCounts['shipped'] ?? 0,
                theme: theme,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _statusItem(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.deliveredStatus,
                count: statusCounts['delivered'] ?? 0,
                theme: theme,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.orders),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _statusItem({
    required IconData icon,
    required String label,
    required int count,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.cardColor,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
