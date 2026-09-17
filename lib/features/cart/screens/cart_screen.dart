import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/screens/auth_gate_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary_card.dart';

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

  void _showClearCartDialog() {
    final l10n = context.l10n;
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
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = ref.watch(cartProvider.select((items) => items.isNotEmpty));
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

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
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () {
                HapticFeedback.lightImpact();
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
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasItems)
            IconButton(
              tooltip: l10n.clearCart,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showClearCartDialog();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !hasItems
          ? _buildEmptyState(context, theme, isDark)
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Virtualized lazy list of cart items
                Consumer(
                  builder: (context, ref, _) {
                    final items = ref.watch(cartProvider);
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return CartItemTile(
                              key: ValueKey(item.cartKey),
                              item: item,
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    );
                  },
                ),

                // Promo code and checkout summary
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPromoSection(theme, l10n, isDark),
                        const SizedBox(height: 16),
                        const CartSummaryCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !hasItems ? null : _buildCheckoutBottomBar(theme, l10n, isDark),
    );
  }

  Widget _buildPromoSection(ThemeData theme, AppLocalizations l10n, bool isDark) {
    return Consumer(
      builder: (context, ref, _) {
        final couponState = ref.watch(couponProvider);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                                  ref.read(couponProvider.notifier).removeCoupon();
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
                              final code = _couponController.text.trim();
                              if (code.isNotEmpty) {
                                ref.read(couponProvider.notifier).applyCoupon(code);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
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
                              couponState.isApplied ? l10n.applied : l10n.apply,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0,
                                color: Colors.white,
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
        );
      },
    );
  }

  Widget _buildCheckoutBottomBar(ThemeData theme, AppLocalizations l10n, bool isDark) {
    return Consumer(
      builder: (context, ref, _) {
        final totalAmount = ref.watch(cartTotalAmountProvider);
        final couponState = ref.watch(couponProvider);
        final discount = couponState.isApplied ? couponState.discountAmount : 0.0;
        final finalTotal = (totalAmount - discount).clamp(0.0, double.infinity);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                  HapticFeedback.mediumImpact();
                  final isAuthenticated = ref.read(authStateProvider).valueOrNull != null;
                  if (isAuthenticated) {
                    context.push('/checkout');
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AuthGateScreen(returnTo: '/checkout'),
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
        );
      },
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
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF8EE),
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/home');
                },
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
