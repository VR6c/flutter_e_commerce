import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/screens/auth_gate_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);
    final totalWeight = ref.watch(cartTotalWeightProvider);
    final couponState = ref.watch(couponProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final double discount = couponState.isApplied
        ? couponState.discountAmount
        : 0.0;
    final double finalTotal = (totalAmount - discount).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 6.0, bottom: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
        ),
        title: Text(
          l10n.cartTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              tooltip: l10n.clearCart,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Text(
                      l10n.clearCart,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    content: Text(
                      l10n.clearCartConfirm,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.grey[600],
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                          ref.read(couponProvider.notifier).removeCoupon();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.clear,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState(context, theme, isDark)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                // Cart Items List
                ...cartItems.map((item) {
                  return RepaintBoundary(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.02,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail with mint background
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF3F9F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item.product.thumbnail,
                                fit: BoxFit.contain,
                                memCacheWidth: 200,
                                memCacheHeight: 200,
                                errorWidget: (_, _, _) => Icon(
                                  Icons.eco_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.selectedSize != null ||
                                          item.selectedColor != null
                                      ? '${item.selectedColor != null ? l10n.translateColor(item.selectedColor!) : ''} ${item.selectedSize != null ? l10n.translateSize(item.selectedSize!) : ''}'
                                            .trim()
                                      : (item
                                                .product
                                                .shortDescription
                                                .isNotEmpty
                                            ? item.product.shortDescription
                                            : l10n.translateCategory(
                                                item.product.category,
                                              )),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : const Color(0xFF94A3B8),
                                    fontSize: 12,
                                    letterSpacing: 0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${item.effectivePrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stepper [- qty +]
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantityByKey(
                                          item.cartKey,
                                          item.quantity - 1,
                                        );
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantityByKey(
                                          item.cartKey,
                                          item.quantity + 1,
                                        );
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 14,
                                      color: Colors.white,
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
                }),

                const SizedBox(height: 16),

                // Promo Code Section (matching mockup)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addPromo,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.couponPlaceholder,
                                hintStyle: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                isDense: true,
                                suffixIcon: couponState.isApplied
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          size: 18,
                                          color: Color(0xFFEF4444),
                                        ),
                                        onPressed: () {
                                          _couponController.clear();
                                          ref
                                              .read(couponProvider.notifier)
                                              .removeCoupon();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: couponState.isLoading
                                  ? null
                                  : () {
                                      final code = _couponController.text
                                          .trim();
                                      if (code.isNotEmpty) {
                                        ref
                                            .read(couponProvider.notifier)
                                            .applyCoupon(code);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: couponState.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      couponState.isApplied
                                          ? l10n.applied
                                          : l10n.apply,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        letterSpacing: 0,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (couponState.errorMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          couponState.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (couponState.isApplied) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.isKhmer
                              ? 'បានបញ្ចុះតម្លៃ: -\$${couponState.discountAmount.toStringAsFixed(2)}'
                              : 'Coupon applied: \$${couponState.discountAmount.toStringAsFixed(2)} discount',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bill Summary Table matching mockup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(
                        l10n.subtotal,
                        '\$${totalAmount.toStringAsFixed(2)}',
                        theme,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        l10n.weightLabel,
                        l10n.isKhmer
                            ? '${totalWeight.toStringAsFixed(1)} គ.ក'
                            : '${totalWeight.toStringAsFixed(1)} kg',
                        theme,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(l10n.vatLabel, '\$0.00', theme, isDark),
                      if (couponState.isApplied) ...[
                        const SizedBox(height: 8),
                        _summaryRow(
                          l10n.discount,
                          '-\$${couponState.discountAmount.toStringAsFixed(2)}',
                          theme,
                          isDark,
                          valueColor: theme.colorScheme.primary,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _summaryRow(
                        l10n.deliveryFee,
                        l10n.isKhmer ? 'ឥតគិតថ្លៃ' : 'FREE',
                        theme,
                        isDark,
                        valueColor: theme.colorScheme.primary,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _summaryRow(
                        l10n.total,
                        '\$${finalTotal.toStringAsFixed(2)}',
                        theme,
                        isDark,
                        isBold: true,
                        fontSize: 18,
                        valueColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final isAuthenticated =
                          ref.read(authStateProvider).valueOrNull != null;
                      if (isAuthenticated) {
                        context.push('/checkout');
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const AuthGateScreen(returnTo: '/checkout'),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.proceedToCheckout,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(\$${finalTotal.toStringAsFixed(2)})',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool isBold = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color:
                valueColor ??
                (isBold
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular light mint illustration container with shopping basket icon
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEBF8EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_basket_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.emptyCart,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: l10n.isKhmer ? 0 : -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyCartSub,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.startShopping,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
