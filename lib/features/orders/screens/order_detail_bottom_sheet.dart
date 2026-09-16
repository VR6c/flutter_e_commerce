import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order.dart';
import '../services/receipt_service.dart';
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
    final l10n = context.l10n;
    final statusInfo = _statusInfo(order.status, l10n);

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
                            l10n.isKhmer ? 'ការបញ្ជាទិញ #${order.id}' : 'Order #${order.id}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt, l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontFamily: AppTheme.fontFamily,
                              letterSpacing: 0,
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
                      label: l10n.isKhmer
                          ? 'ទំនិញ (${order.items.length})'
                          : 'Items (${order.items.length})',
                    ),
                    const SizedBox(height: 12),
                    if (order.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.isKhmer ? 'មិនមានព័ត៌មានលម្អិតទំនិញទេ' : 'No item details available.',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 13,
                            fontFamily: AppTheme.fontFamily,
                            letterSpacing: 0,
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
                            label: l10n.subtotal,
                            value:
                                '\$${(order.total + order.discountAmount).toStringAsFixed(2)}',
                            theme: theme,
                          ),
                          const SizedBox(height: 6),
                          _PriceRow(
                            label: l10n.deliveryFee,
                            value: l10n.freeLabel,
                            isAccent: true,
                            theme: theme,
                          ),
                          if (order.discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            _PriceRow(
                              label: order.couponCode != null
                                  ? '${l10n.discount} (${order.couponCode})'
                                  : l10n.discount,
                              value:
                                  '-\$${order.discountAmount.toStringAsFixed(2)}',
                              isAccent: true,
                              theme: theme,
                            ),
                          ],
                          const Divider(height: 20),
                          _PriceRow(
                            label: l10n.total,
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
                      label: l10n.paymentMethod,
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodTile(gateway: order.gateway, theme: theme),
                    const SizedBox(height: 24),

                    // Shipping Address
                    _SectionHeader(
                      icon: Icons.location_on_outlined,
                      label: l10n.shippingAddress,
                    ),
                    const SizedBox(height: 12),
                    _AddressTile(order: order, theme: theme),
                    const SizedBox(height: 24),

                    // Order Receipt
                    _SectionHeader(
                      icon: Icons.receipt_long_outlined,
                      label: l10n.orderReceipt,
                    ),
                    const SizedBox(height: 12),
                    _ReceiptActionCard(order: order, theme: theme),
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

  Map<String, dynamic> _statusInfo(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return {
          'color': const Color(0xFF059669),
          'icon': Icons.check_circle_rounded,
          'label': l10n.isKhmer ? 'បានដឹកដល់' : 'Completed',
        };
      case 'processing':
        return {
          'color': const Color(0xFF4F46E5),
          'icon': Icons.sync_rounded,
          'label': l10n.isKhmer ? 'កំពុងរៀបចំ' : 'Processing',
        };
      case 'cancelled':
      case 'canceled':
        return {
          'color': const Color(0xFFDC2626),
          'icon': Icons.cancel_rounded,
          'label': l10n.isKhmer ? 'បានបោះបង់' : 'Cancelled',
        };
      case 'pending':
      default:
        return {
          'color': const Color(0xFFF59E0B),
          'icon': Icons.hourglass_top_rounded,
          'label': l10n.isKhmer ? 'រង់ចាំ' : 'Pending',
        };
    }
  }

  String _formatDate(String isoDate, AppLocalizations l10n) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final monthsEn = [
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
      final monthsKm = [
        'មករា',
        'កុម្ភៈ',
        'មីនា',
        'មេសា',
        'ឧសភា',
        'មិថុនា',
        'កក្កដា',
        'សីហា',
        'កញ្ញា',
        'តុលា',
        'វិច្ឆិកា',
        'ធ្នូ',
      ];
      final monthName = l10n.isKhmer ? monthsKm[dt.month - 1] : monthsEn[dt.month - 1];
      return '${dt.day} $monthName ${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0,
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
              fontFamily: AppTheme.fontFamily,
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0,
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
    final l10n = context.l10n;
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
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.isKhmer ? 'ចំនួន: ${item.quantity}' : 'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF0F172A),
              letterSpacing: 0,
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
            fontFamily: AppTheme.fontFamily,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? null : theme.hintColor,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: AppTheme.fontFamily,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isAccent
                ? const Color(0xFF059669)
                : isBold
                ? theme.colorScheme.primary
                : null,
            fontSize: isBold ? 16 : null,
            letterSpacing: 0,
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
    final l10n = context.l10n;
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
            isAba ? l10n.abaPayWay : l10n.cashOnDelivery,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              letterSpacing: 0,
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
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReceiptActionCard extends ConsumerStatefulWidget {
  final Order order;
  final ThemeData theme;

  const _ReceiptActionCard({required this.order, required this.theme});

  @override
  ConsumerState<_ReceiptActionCard> createState() => _ReceiptActionCardState();
}

class _ReceiptActionCardState extends ConsumerState<_ReceiptActionCard> {
  bool _isDownloading = false;

  Future<void> _handleDownload(BuildContext context, AppLocalizations l10n) async {
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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: widget.theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.isKhmer
                          ? 'វិក្កយបត្រផ្លូវការ #${widget.order.id}'
                          : 'Official Receipt #${widget.order.id}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.isKhmer
                          ? 'មើលវិក្កយបត្រលើអេក្រង់ ឬទាញយកជាឯកសារ'
                          : 'Preview on screen or download as file',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: Colors.grey[500],
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // View Receipt Button
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
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.theme.colorScheme.primary,
                      side: BorderSide(
                        color: widget.theme.colorScheme.primary.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Download Receipt Button
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading
                        ? null
                        : () => _handleDownload(context, l10n),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.file_download_outlined,
                            size: 18,
                          ),
                    label: Text(
                      _isDownloading
                          ? (l10n.isKhmer ? 'កំពុងទាញ...' : 'Downloading...')
                          : l10n.downloadReceipt,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
