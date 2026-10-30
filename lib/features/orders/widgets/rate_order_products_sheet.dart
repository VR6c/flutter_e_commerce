import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../products/providers/product_provider.dart';
import '../../products/widgets/product_reviews_section.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../providers/orders_provider.dart';

/// Lists the products of an order so the customer can rate each one.
class RateOrderProductsSheet extends ConsumerStatefulWidget {
  final int orderId;
  final Order? initialOrder;

  const RateOrderProductsSheet({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  static Future<void> show(
    BuildContext context,
    int orderId, {
    Order? initialOrder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RateOrderProductsSheet(
        orderId: orderId,
        initialOrder: initialOrder,
      ),
    );
  }

  @override
  ConsumerState<RateOrderProductsSheet> createState() =>
      _RateOrderProductsSheetState();
}

class _RateOrderProductsSheetState
    extends ConsumerState<RateOrderProductsSheet> {
  late Future<Order?> _orderFuture;
  final Set<int> _reviewedProductIds = {};
  int? _resolvingItemId;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null && widget.initialOrder!.items.isNotEmpty) {
      _orderFuture = Future.value(widget.initialOrder);
    } else {
      _loadOrder();
    }
  }

  void _loadOrder() {
    setState(() {
      _orderFuture = ref
          .read(orderRepositoryProvider)
          .fetchOrderDetail(widget.orderId);
    });
  }

  Future<String?> _resolveSlug(OrderItem item) async {
    final repo = ref.read(orderRepositoryProvider);

    // 1. Check in-memory slug cache
    final direct = repo.getCachedSlug(item.productId);
    if (direct != null && direct.isNotEmpty) return direct;

    // 2. Check loaded products list
    final cached = ref.read(productsProvider).valueOrNull ?? const [];
    final hit = cached.where((p) => p.id == item.productId).firstOrNull;
    if (hit != null && hit.slug.isNotEmpty) {
      repo.cacheSlug(item.productId, hit.slug);
      return hit.slug;
    }

    // 3. Search catalog by product name
    final productRepo = ref.read(productRepositoryProvider);
    try {
      final res = await productRepo.fetchProductsPage(
        search: item.productName,
        perPage: 20,
      );
      final found = res.products
          .where((p) => p.id == item.productId)
          .firstOrNull;
      if (found != null && found.slug.isNotEmpty) {
        repo.cacheSlug(item.productId, found.slug);
        return found.slug;
      }
    } catch (_) {}

    // 4. Scan products catalog
    try {
      final res = await productRepo.fetchProductsPage(page: 1, perPage: 100);
      final found = res.products
          .where((p) => p.id == item.productId)
          .firstOrNull;
      if (found != null && found.slug.isNotEmpty) {
        repo.cacheSlug(item.productId, found.slug);
        return found.slug;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _rate(OrderItem item) async {
    if (_resolvingItemId != null) return;
    setState(() => _resolvingItemId = item.id);
    final slug = await _resolveSlug(item);
    if (!mounted) return;
    setState(() => _resolvingItemId = null);

    if (slug == null) {
      AppSnackBar.showError(context, context.l10n.productNotFoundToReview);
      return;
    }

    await WriteReviewSheet.show(context, slug);
    if (mounted) {
      setState(() {
        _reviewedProductIds.add(item.productId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rateYourProducts,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.isKhmer
                              ? 'ការបញ្ជាទិញ #${widget.orderId} • ចែករំលែកមតិរបស់អ្នក'
                              : 'Order #${widget.orderId} • Share your feedback',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Body (List, Loading or Error)
            Flexible(
              child: FutureBuilder<Order?>(
                future: _orderFuture,
                builder: (context, snap) {
                  // 1. Loading State
                  if (snap.connectionState != ConnectionState.done) {
                    return _buildLoadingState(isDark);
                  }

                  final order = snap.data;
                  final items = order?.items ?? const <OrderItem>[];

                  // 2. Empty / Error State
                  if (snap.hasError || items.isEmpty) {
                    return _buildEmptyErrorState(context, isDark, l10n);
                  }

                  // 3. Products List
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildProductCard(context, item, isDark, l10n);
                    },
                  );
                },
              ),
            ),

            // Helpful footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.isKhmer
                          ? 'មតិយោបល់របស់អ្នកជួយអ្នកទិញទំនិញដទៃទៀតធ្វើការសម្រេចចិត្តបានកាន់តែប្រសើរ'
                          : 'Your honest reviews help our community discover great products',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    OrderItem item,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isReviewed = _reviewedProductIds.contains(item.productId);
    final isResolving = _resolvingItemId == item.id;
    final thumb = item.productThumbnail;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReviewed
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isReviewed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: (thumb != null && thumb.isNotEmpty)
                  ? Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.shopping_bag_outlined,
                        size: 26,
                        color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8),
                      ),
                    )
                  : Icon(
                      Icons.shopping_bag_outlined,
                      size: 26,
                      color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8),
                    ),
            ),
          ),

          const SizedBox(width: 14),

          // Title & Quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.3,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Action Button / Reviewed Chip
          if (isReviewed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Reviewed',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            )
          else
            FilledButton.tonalIcon(
              onPressed: isResolving ? null : () => _rate(item),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                foregroundColor: const Color(0xFFB45309),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
              ),
              icon: isResolving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                      ),
                    )
                  : const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
              label: Text(
                l10n.rateProduct,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyErrorState(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 36,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.isKhmer
                  ? 'មិនអាចពិនិត្យឡើងវិញនៅពេលនេះបានទេ'
                  : 'Items Not Available For Review',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.isKhmer
                  ? 'ព័ត៌មានលម្អិតនៃការបញ្ជាទិញនេះកំពុងដំណើរការ។ អ្នកអាចចូលទៅវាយតម្លៃផលិតផលនៅពេលក្រោយតាមរយៈប្រវត្តិបញ្ជាទិញ។'
                  : 'Order details might still be finalizing. You can refresh now or review items anytime from your Order History screen.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.45,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadOrder,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                l10n.isKhmer ? 'ព្យាយាមម្តងទៀត' : 'Try Again',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
