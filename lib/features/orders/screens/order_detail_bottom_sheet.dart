import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order.dart';

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
    final statusInfo = _statusInfo(order.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: order.status, info: statusInfo),
                  ],
                ),
              ),
              const Divider(height: 20),
              // Scrollable body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Items
                    _SectionHeader(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Items (${order.items.length})',
                    ),
                    const SizedBox(height: 12),
                    if (order.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'No item details available.',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      ...order.items.map(
                        (item) => _OrderItemTile(item: item, theme: theme),
                      ),
                    const SizedBox(height: 8),

                    // Price Summary
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _PriceRow(
                            label: 'Subtotal',
                            value:
                                '\$${(order.total + order.discountAmount).toStringAsFixed(2)}',
                            theme: theme,
                          ),
                          const SizedBox(height: 6),
                          _PriceRow(
                            label: 'Shipping',
                            value: 'FREE',
                            isAccent: true,
                            theme: theme,
                          ),
                          if (order.discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            _PriceRow(
                              label: order.couponCode != null
                                  ? 'Discount (${order.couponCode})'
                                  : 'Discount',
                              value:
                                  '-\$${order.discountAmount.toStringAsFixed(2)}',
                              isAccent: true,
                              theme: theme,
                            ),
                          ],
                          const Divider(height: 20),
                          _PriceRow(
                            label: 'Total',
                            value: '\$${order.total.toStringAsFixed(2)}',
                            isBold: true,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    _SectionHeader(
                      icon: Icons.payment_outlined,
                      label: 'Payment Method',
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodTile(gateway: order.gateway, theme: theme),
                    const SizedBox(height: 24),

                    // Shipping Address
                    _SectionHeader(
                      icon: Icons.location_on_outlined,
                      label: 'Shipping Address',
                    ),
                    const SizedBox(height: 12),
                    _AddressTile(order: order, theme: theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return {
          'color': const Color(0xFF059669),
          'icon': Icons.check_circle_rounded,
          'label': 'Completed',
        };
      case 'processing':
        return {
          'color': const Color(0xFF4F46E5),
          'icon': Icons.sync_rounded,
          'label': 'Processing',
        };
      case 'cancelled':
      case 'canceled':
        return {
          'color': const Color(0xFFDC2626),
          'icon': Icons.cancel_rounded,
          'label': 'Cancelled',
        };
      case 'pending':
      default:
        return {
          'color': const Color(0xFFF59E0B),
          'icon': Icons.hourglass_top_rounded,
          'label': 'Pending',
        };
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
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
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Map<String, dynamic> info;
  const _StatusBadge({required this.status, required this.info});

  @override
  Widget build(BuildContext context) {
    final color = info['color'] as Color;
    final icon = info['icon'] as IconData;
    final label = info['label'] as String;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final dynamic item;
  final ThemeData theme;
  const _OrderItemTile({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              color: const Color(0xFFF1F5F9),
            ),
            child: item.productThumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.productThumbnail!,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      memCacheHeight: 150,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_outlined,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    size: 24,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? null : theme.hintColor,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isAccent
                ? const Color(0xFF059669)
                : isBold
                ? theme.colorScheme.primary
                : null,
            fontSize: isBold ? 16 : null,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String gateway;
  final ThemeData theme;
  const _PaymentMethodTile({required this.gateway, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isAba =
        gateway.toLowerCase().contains('aba') ||
        gateway.toLowerCase().contains('payway');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
              color: isAba
                  ? const Color(0xFF005C8A).withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAba
                  ? Icons.account_balance_wallet_outlined
                  : Icons.local_shipping_outlined,
              color: isAba ? const Color(0xFF005C8A) : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isAba ? 'ABA PayWay' : 'Cash on Delivery',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
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
  const _AddressTile({required this.order, required this.theme});

  @override
  Widget build(BuildContext context) {
    final lines = [
      '${order.firstName} ${order.lastName}',
      if (order.phone != null && order.phone!.isNotEmpty) order.phone!,
      if (order.address != null && order.address!.isNotEmpty) order.address!,
      [
        order.city,
        order.country,
      ].where((e) => e != null && e.isNotEmpty).join(', '),
    ].where((s) => s.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
