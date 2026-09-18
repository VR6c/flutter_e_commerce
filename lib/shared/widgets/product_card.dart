import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/app_image_cache.dart';
import '../../core/utils/app_snackbar.dart';
import '../../features/products/models/product.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final String heroTagPrefix;
  final BoxFit imageFit;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTagPrefix = 'grid',
    this.imageFit = BoxFit.cover,
  });

  String get heroTag => '${heroTagPrefix}_product_${product.id}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    final effectiveOnTap = onTap ??
        () {
          context.push(
            AppRoutes.productDetail,
            extra: {
              'product': product,
              'heroTag': heroTag,
            },
          );
        };

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderSubtle, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: effectiveOnTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top edge-to-edge image container
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: heroTag,
                          transitionOnUserGestures: true,
                          placeholderBuilder: (context, heroSize, child) {
                            return Container(
                              width: heroSize.width,
                              height: heroSize.height,
                              decoration: BoxDecoration(
                                color: context.imageBg.withValues(alpha: 0.6),
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
                            width: double.infinity,
                            height: double.infinity,
                            color: context.imageBg,
                            child: AppCachedImage(
                              imageUrl: product.thumbnail,
                              fit: imageFit,
                              memCacheWidth: AppImageCache.cardWidth,
                              fallbackSlug: product.slug,
                              fallbackTitle: product.name,
                              fallbackCategory: product.category,
                            ),
                          ),
                        ),
                        // Wishlist heart button (repaint-isolated)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: RepaintBoundary(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final isWishlisted = ref.watch(
                                  isInWishlistProvider(product.id),
                                );
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    final isSignedIn =
                                        ref
                                            .read(authStateProvider)
                                            .valueOrNull !=
                                        null;
                                    if (!isSignedIn) {
                                      context.push(
                                        '/login',
                                        extra: {'returnTo': '/wishlist'},
                                      );
                                      return;
                                    }
                                    ref
                                        .read(wishlistProvider.notifier)
                                        .toggleItem(product);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white)
                                          .withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isWishlisted
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 16,
                                      color: isWishlisted
                                          ? const Color(0xFFEF4444)
                                          : (isDark
                                                ? Colors.grey[400]
                                                : const Color(0xFF94A3B8)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Rating & Discount Badges
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (product.rating != null && product.rating! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        product.rating!.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (product.rating != null &&
                                  product.rating! > 0 &&
                                  product.hasDiscount &&
                                  product.discountPercentage != null)
                                const SizedBox(width: 4),
                              if (product.hasDiscount &&
                                  product.discountPercentage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${product.discountPercentage}%',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
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
                  // Bottom content: title, category, price & add button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: context.l10n.isKhmer ? 0 : -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Unit / Category text
                        Text(
                          product.shortDescription.isNotEmpty
                              ? product.shortDescription
                              : context.l10n.translateCategory(product.category),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Optimized Price & Green Quick Add (+) button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    product.effectivePrice.toCurrency,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (product.hasDiscount &&
                                      product.originalPrice != null) ...[
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        product.originalPrice!.toCurrency,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[500]
                                              : const Color(0xFF94A3B8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            RepaintBoundary(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
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
                                  AppSnackBar.showSuccess(
                                    context,
                                    context.l10n.addedProductToCart(product.name),
                                  );
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF8FAFC);
    final placeholderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    color: placeholderColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, color: placeholderColor, width: 90),
                      const SizedBox(height: 6),
                      Container(height: 10, color: placeholderColor, width: 60),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(height: 16, color: placeholderColor, width: 45),
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: placeholderColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
