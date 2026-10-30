import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../core/utils/app_snackbar.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/receipt_service.dart';
import '../utils/order_date_formatter.dart';
import '../widgets/order_delivery_timeline.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/rate_order_products_sheet.dart';
import 'receipt_viewer_screen.dart';

class OrderDetailBottomSheet extends StatelessWidget {
  final Order order;

  const OrderDetailBottomSheet({super.key, required this.order});

  static void show(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDetailBottomSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: OrderDetailContentView(
                  order: order,
                  scrollController: scrollController,
                  isBottomSheet: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Standalone or embedded order detail view matching Order Success & Order History
class OrderDetailContentView extends StatelessWidget {
  final Order order;
  final ScrollController? scrollController;
  final bool isBottomSheet;

  const OrderDetailContentView({
    super.key,
    required this.order,
    this.scrollController,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        // 1. Order Header Card (ID, Date, Status, Copy)
        _buildHeaderCard(context, theme, isDark, l10n),
        const SizedBox(height: 16),

        // 2. Delivery Progress Timeline Stepper
        OrderDeliveryTimeline(status: order.status),
        const SizedBox(height: 18),

        // 3. Ordered Items Section
        _SectionHeader(
          icon: Icons.shopping_bag_outlined,
          label: l10n.itemsCount(order.items.length),
        ),
        const SizedBox(height: 10),
        if (order.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Text(
              l10n.noItemDetailsAvailable,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          )
        else
          ...order.items.map(
            (item) => _OrderItemTile(item: item, theme: theme, isDark: isDark),
          ),
        const SizedBox(height: 16),

        // 4. Price Breakdown Summary
        _PriceSummaryCard(order: order, theme: theme, isDark: isDark),
        const SizedBox(height: 20),

        // 5. Payment Method
        _SectionHeader(
          icon: Icons.payment_rounded,
          label: l10n.paymentMethod,
        ),
        const SizedBox(height: 10),
        _PaymentMethodTile(order: order, theme: theme, isDark: isDark),
        const SizedBox(height: 20),

        // 6. Shipping Address
        _SectionHeader(
          icon: Icons.location_on_outlined,
          label: l10n.shippingAddress,
        ),
        const SizedBox(height: 10),
        _AddressTile(order: order, theme: theme, isDark: isDark),
        const SizedBox(height: 20),

        // 7. Order Receipt Action Card
        _SectionHeader(
          icon: Icons.receipt_long_rounded,
          label: l10n.orderReceipt,
        ),
        const SizedBox(height: 10),
        _ReceiptActionCard(order: order, theme: theme, isDark: isDark),
        const SizedBox(height: 16),

        // 8. Rate Products Card (Rate experience)
        _buildRateProductsCard(context, theme, isDark, l10n),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final formattedDate = OrderDateFormatter.format(order.createdAt, l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tag_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderNumber(order.id),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Clipboard.setData(ClipboardData(text: '${order.id}'));
              AppSnackBar.showSuccess(
                context,
                l10n.copiedOrderId,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.orderId}: #${order.id}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateProductsCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => RateOrderProductsSheet.show(
        context,
        order.id,
        initialOrder: order,
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF2C2214),
                    const Color(0xFF1E1A14),
                  ]
                : [
                    const Color(0xFFFFFBEB),
                    const Color(0xFFFEF3C7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rateYourProducts,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.rateYourProductsDesc,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5,
                      color: isDark
                          ? Colors.grey[300]
                          : const Color(0xFF78350F).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final ThemeData theme;
  final bool isDark;

  const _OrderItemTile({
    required this.item,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 56,
            height: 56,
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
                    size: 24,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(width: 14),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.qtyCount(item.quantity),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${item.price.toStringAsFixed(2)} / ea',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  final Order order;
  final ThemeData theme;
  final bool isDark;

  const _PriceSummaryCard({
    required this.order,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: isDark ? 0.08 : 0.04,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.2 : 0.15,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PriceRow(
            label: l10n.subtotal,
            value: '\$${(order.total + order.discountAmount).toStringAsFixed(2)}',
            theme: theme,
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: l10n.deliveryFee,
            value: l10n.freeLabel,
            isAccent: true,
            theme: theme,
          ),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: order.couponCode != null
                  ? '${l10n.discount} (${order.couponCode})'
                  : l10n.discount,
              value: '-\$${order.discountAmount.toStringAsFixed(2)}',
              isAccent: true,
              theme: theme,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _PriceRow(
            label: l10n.total,
            value: '\$${order.total.toStringAsFixed(2)}',
            isBold: true,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isAccent;
  final ThemeData theme;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isAccent = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold
                ? theme.colorScheme.onSurface
                : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            fontSize: isBold ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isAccent
                ? const Color(0xFF059669)
                : (isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            fontSize: isBold ? 17 : 13.5,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final Order order;
  final ThemeData theme;
  final bool isDark;

  const _PaymentMethodTile({
    required this.order,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAba =
        order.gateway.toLowerCase().contains('aba') ||
        order.gateway.toLowerCase().contains('payway');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isAba
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                  : const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAba
                  ? Icons.account_balance_wallet_rounded
                  : Icons.payments_rounded,
              color: isAba ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAba ? l10n.abaPayWay : l10n.cashOnDelivery,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAba ? 'Secured Instant Payment' : 'Pay when you receive items',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAba
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAba ? 'PAID' : 'COD',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: isAba
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Order order;
  final ThemeData theme;
  final bool isDark;

  const _AddressTile({
    required this.order,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = '${order.firstName} ${order.lastName}'.trim();
    final addressLine = order.address ?? '';
    final cityCountry = [
      order.city,
      order.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 20,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fullName.isNotEmpty)
                  Text(
                    fullName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                if (order.phone != null && order.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.phone!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
                if (addressLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    addressLine,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
                if (cityCountry.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cityCountry,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptActionCard extends ConsumerStatefulWidget {
  final Order order;
  final ThemeData theme;
  final bool isDark;

  const _ReceiptActionCard({
    required this.order,
    required this.theme,
    required this.isDark,
  });

  @override
  ConsumerState<_ReceiptActionCard> createState() => _ReceiptActionCardState();
}

class _ReceiptActionCardState extends ConsumerState<_ReceiptActionCard> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final file = await ReceiptService.downloadReceipt(
        context: context,
        ref: ref,
        orderId: widget.order.id,
      );
      if (file != null && mounted) {
        ReceiptService.showFileDetailsBottomSheet(
          context,
          orderId: widget.order.id,
          file: file,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isDark ? 0.2 : 0.025,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 21,
                  color: widget.theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderReceipt,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: widget.theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.officialInvoiceForThisOrder,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: widget.isDark
                            ? Colors.grey[400]
                            : const Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // View Receipt
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ReceiptViewerScreen.show(
                        context,
                        orderId: widget.order.id,
                        receiptUrl: widget.order.receiptUrl,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      l10n.viewReceipt,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.theme.colorScheme.primary,
                      side: BorderSide(
                        color: widget.theme.colorScheme.primary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Download Receipt
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.tonalIcon(
                    onPressed: _isDownloading ? null : _handleDownload,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(
                      _isDownloading
                          ? l10n.downloading1
                          : l10n.downloadReceipt,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      foregroundColor: widget.isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      elevation: 0,
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
    );
  }
}
