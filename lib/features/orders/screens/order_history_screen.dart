import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../utils/order_date_formatter.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/rate_order_products_sheet.dart';
import 'order_detail_bottom_sheet.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const OrderHistoryScreen({super.key, this.initialStatus});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = _normalizeStatus(widget.initialStatus) ?? 'all';
  }

  String? _normalizeStatus(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase().trim();
    if (lower == 'all') return 'all';
    if (lower == 'pending' || lower == 'to_pay') return 'pending';
    if (lower == 'processing') return 'processing';
    if (lower == 'completed' || lower == 'delivered') return 'completed';
    if (lower == 'cancelled' || lower == 'canceled') return 'cancelled';
    return lower;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final customer = ref.watch(authStateProvider).valueOrNull;

    // Handle guest state gracefully without triggering 401 API errors
    if (customer == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            l10n.ordersTitle,
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
                  l10n.signInToViewOrders,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signInToTrackLive,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n.logIn,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
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
          l10n.ordersTitle,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
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
        error: (error, _) => _buildError(context, ref, error, theme, l10n),
        data: (allOrders) {
          if (allOrders.isEmpty) {
            return _buildEmptyState(context, theme, isDark, l10n);
          }

          // Calculate counts
          final pendingCount = allOrders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length;
          final processingCount = allOrders
              .where((o) => o.status.toLowerCase() == 'processing')
              .length;
          final completedCount = allOrders.where((o) {
            final s = o.status.toLowerCase();
            return s == 'completed' || s == 'delivered';
          }).length;
          final cancelledCount = allOrders.where((o) {
            final s = o.status.toLowerCase();
            return s == 'cancelled' || s == 'canceled';
          }).length;

          // Filter orders according to selected tab
          final filteredOrders = allOrders.where((o) {
            if (_selectedFilter == 'all') return true;
            final s = o.status.toLowerCase();
            if (_selectedFilter == 'pending') return s == 'pending';
            if (_selectedFilter == 'processing') return s == 'processing';
            if (_selectedFilter == 'completed') {
              return s == 'completed' || s == 'delivered';
            }
            if (_selectedFilter == 'cancelled') {
              return s == 'cancelled' || s == 'canceled';
            }
            return s == _selectedFilter;
          }).toList();

          return Column(
            children: [
              // Filter Chips Tab Row
              _buildFilterTabs(
                theme: theme,
                isDark: isDark,
                l10n: l10n,
                totalCount: allOrders.length,
                pendingCount: pendingCount,
                processingCount: processingCount,
                completedCount: completedCount,
                cancelledCount: cancelledCount,
              ),

              // Orders List or Filtered Empty State
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
                  color: theme.colorScheme.primary,
                  child: filteredOrders.isEmpty
                      ? _buildFilteredEmptyState(theme, isDark, l10n)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) => _OrderCard(
                            order: filteredOrders[index],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs({
    required ThemeData theme,
    required bool isDark,
    required AppLocalizations l10n,
    required int totalCount,
    required int pendingCount,
    required int processingCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    final filters = [
      _FilterOption(key: 'all', label: l10n.allOrders, count: totalCount),
      _FilterOption(key: 'pending', label: l10n.statusPending, count: pendingCount),
      _FilterOption(
        key: 'processing',
        label: l10n.processingStatus,
        count: processingCount,
      ),
      _FilterOption(
        key: 'completed',
        label: l10n.statusCompleted,
        count: completedCount,
      ),
      if (cancelledCount > 0)
        _FilterOption(
          key: 'cancelled',
          label: l10n.statusCancelled,
          count: cancelledCount,
        ),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter.key;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() => _selectedFilter = filter.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.grey[300]
                              : const Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filter.count}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilteredEmptyState(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProductsFound,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.trySearchingOther,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () => setState(() => _selectedFilter = 'all'),
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: Text(
                l10n.allOrders,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_rounded,
      title: l10n.noOrders,
      message: l10n.noOrdersSub,
      actionLabel: l10n.startShopping,
      onActionPressed: () => context.go('/home'),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    ThemeData theme,
    AppLocalizations l10n,
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
              l10n.couldNotLoadOrders,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.retry),
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
        height: 160,
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
                        width: 130,
                        height: 18,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        width: 70,
                        height: 20,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
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

class _FilterOption {
  final String key;
  final String label;
  final int count;

  const _FilterOption({
    required this.key,
    required this.label,
    required this.count,
  });
}

class _OrderCard extends ConsumerWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final formattedDate = OrderDateFormatter.format(order.createdAt, l10n);

    final isAba =
        order.gateway.toLowerCase().contains('aba') ||
        order.gateway.toLowerCase().contains('payway');

    final isCompleted = order.status.toLowerCase() == 'completed' ||
        order.status.toLowerCase() == 'delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          OrderDetailBottomSheet.show(context, order);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Order Number & Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.orderNumber(order.id),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${order.id}'));
                      AppSnackBar.showSuccess(context, l10n.copiedOrderId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Order Date & Time
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13.5,
                    color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Products Horizontal Preview Strip
              if (order.items.isNotEmpty)
                _buildProductsPreviewStrip(context, theme, isDark, l10n),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 0.8),
              ),

              // 4. Payment Method & Total Row
              Row(
                children: [
                  // Payment method pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isAba
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAba
                              ? Icons.account_balance_wallet_rounded
                              : Icons.payments_rounded,
                          size: 12.5,
                          color: isAba
                              ? const Color(0xFF3B82F6)
                              : (isDark ? Colors.grey[300] : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAba ? l10n.abaPayWay : l10n.cashOnDelivery,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: isAba
                                ? const Color(0xFF3B82F6)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${l10n.total}: ',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. Actions Footer (View Details, Rate / Receipt)
              Row(
                children: [
                  if (isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        height: 34,
                        child: FilledButton.tonalIcon(
                          onPressed: () => RateOrderProductsSheet.show(
                            context,
                            order.id,
                            initialOrder: order,
                          ),
                          icon: const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFD97706),
                          ),
                          label: Text(
                            l10n.rateProduct,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF3C7),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // View Details Button with chevron
                  SizedBox(
                    height: 34,
                    child: TextButton.icon(
                      onPressed: () => OrderDetailBottomSheet.show(context, order),
                      icon: Text(
                        l10n.viewDetails,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      label: Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: theme.colorScheme.primary,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
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

  Widget _buildProductsPreviewStrip(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final items = order.items;
    final maxThumbnails = 3;
    final displayItems = items.take(maxThumbnails).toList();
    final remaining = items.length - maxThumbnails;

    return Row(
      children: [
        for (final item in displayItems)
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.imageBg,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: item.productThumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppCachedImage(
                      imageUrl: item.productThumbnail!,
                      fit: BoxFit.cover,
                      memCacheWidth: AppImageCache.thumbnailWidth,
                      fallbackTitle: item.productName,
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
          ),
        if (remaining > 0)
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                '+$remaining',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                items.first.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.itemCountLabel(items.length),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
