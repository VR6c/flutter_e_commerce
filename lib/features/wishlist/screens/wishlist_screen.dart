import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/wishlist_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../products/models/product.dart';
import '../../../shared/providers/bottom_nav_scroll_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BottomNavScrollEvent>(bottomNavScrollProvider, (previous, next) {
      if (next.tabIndex == 2 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final authAsync = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (authAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final customer = authAsync.valueOrNull;

    if (customer == null) {
      return _GuestWishlist(isDark: isDark, theme: theme);
    }

    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.wishlistTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (wishlist.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Color(0xFFEF4444),
              ),
              tooltip: 'Clear all',
              onPressed: () {
                final l10n = context.l10n;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      l10n.clearWishlist,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0,
                      ),
                    ),
                    content: Text(
                      l10n.doYouWantToRemove,
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
                            color: Colors.grey[600],
                            fontFamily: AppTheme.fontFamily,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(wishlistProvider.notifier).clear();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                        child: Text(
                          l10n.clear,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
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
      body: wishlist.isEmpty
          ? _EmptyWishlist(isDark: isDark, theme: theme)
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: wishlist.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = wishlist[index];
                return _WishlistItem(product: product);
              },
            ),
    );
  }
}

class _WishlistItem extends ConsumerWidget {
  final Product product;

  const _WishlistItem({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(
            AppRoutes.productDetail,
            extra: {
              'product': product,
              'heroTag': 'wishlist_product_${product.id}',
            },
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Mint rounded thumbnail container
                Hero(
                  tag: 'wishlist_product_${product.id}',
                  transitionOnUserGestures: true,
                  placeholderBuilder: (context, heroSize, child) {
                    return Container(
                      width: heroSize.width,
                      height: heroSize.height,
                      decoration: BoxDecoration(
                        color: context.imageBg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                  flightShuttleBuilder: (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    return Material(
                      type: MaterialType.transparency,
                      child: toHeroContext.widget,
                    );
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: context.imageBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppCachedImage(
                        imageUrl: product.thumbnail,
                        fit: BoxFit.contain,
                        memCacheWidth: AppImageCache.thumbnailWidth,
                        fallbackSlug: product.slug,
                        fallbackTitle: product.name,
                        fallbackCategory: product.category,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.shortDescription.isNotEmpty
                            ? product.shortDescription
                            : context.l10n.translateCategory(product.category),
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
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            '\$${product.effectivePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (product.hasDiscount &&
                              product.originalPrice != null)
                            Text(
                              '\$${product.originalPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons: Delete & Quick Add to Cart
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(wishlistProvider.notifier)
                            .removeItem(product.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: const Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final pv = product.primaryVariant;
                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              product,
                              quantity: 1,
                              variantId: pv?.id,
                              variantName: pv?.name,
                              unitPrice: product.effectivePrice,
                            );
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Added ${product.name} to cart'),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _EmptyWishlist({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEBF8EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.emptyWishlist,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.saveYourFavoriteItemsAnd,
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
                ),
                child: Text(
                  context.l10n.exploreProducts,
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

class _GuestWishlist extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _GuestWishlist({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n.wishlistTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: AppTheme.fontFamily,
            letterSpacing: 0,
          ),
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
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEBF8EE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.signInToViewWishlist,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.signInToSyncYour,
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
                  onPressed: () =>
                      context.push('/login', extra: {'returnTo': '/wishlist'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.l10n.logIn,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0,
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
}
