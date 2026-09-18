import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_status_badge.dart';
import 'order_detail_bottom_sheet.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customer = ref.watch(authStateProvider).valueOrNull;

    // Handle guest state gracefully without triggering 401 API errors
    if (customer == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            context.l10n.ordersTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEBF8EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.signInToViewOrders,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.signInToTrackLive,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/login', extra: {'returnTo': '/orders'}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      context.l10n.logIn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          context.l10n.ordersTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ordersState.when(
        loading: () => _buildSkeletonList(theme, isDark),
        error: (error, _) => _buildError(context, ref, error, theme),
        data: (orders) {
          if (orders.isEmpty) return _buildEmptyState(context, theme, isDark);
          return RefreshIndicator(
            onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
            color: theme.colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_rounded,
      title: context.l10n.noOrders,
      message: context.l10n.noOrdersSub,
      actionLabel: context.l10n.startShopping,
      onActionPressed: () => context.go('/home'),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.l10n.couldNotLoadOrders,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.grey[600],
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(ordersProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList(ThemeData theme, bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 110,
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 20,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => OrderDetailBottomSheet(order: order),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.orderNumber(order.id),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 0,
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.itemCountLabel(order.items.length),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF64748B),
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
