import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/image_url_formatter.dart';
import '../../features/products/models/product.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final String heroTagPrefix;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTagPrefix = 'grid',
  });

  String get heroTag => '${heroTagPrefix}_product_${product.id}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF131D38) : Colors.white;
    final imageBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F9F5);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

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
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top rounded pastel image container
                    Expanded(
                      child: Stack(
                        children: [
                          Hero(
                            tag: heroTag,
                            transitionOnUserGestures: true,
                            placeholderBuilder: (context, heroSize, child) {
                              return Container(
                                width: heroSize.width,
                                height: heroSize.height,
                                decoration: BoxDecoration(
                                  color: imageBg.withValues(alpha: 0.6),
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
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: imageBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: product.thumbnail,
                                  fit: BoxFit.contain,
                                  memCacheWidth: 350,
                                  memCacheHeight: 350,
                                  fadeInDuration: const Duration(
                                    milliseconds: 120,
                                  ),
                                  placeholder: (context, url) => Center(
                                    child: Shimmer.fromColors(
                                      baseColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE2E8F0),
                                      highlightColor: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFF8FAFC),
                                      child: Container(
                                        color: Colors.white,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    final fallback = getFallbackImageUrl(
                                      slug: product.slug,
                                      title: product.name,
                                      category: product.category,
                                    );
                                    if (fallback.isNotEmpty &&
                                        url != fallback) {
                                      return CachedNetworkImage(
                                        imageUrl: fallback,
                                        fit: BoxFit.contain,
                                        memCacheWidth: 350,
                                        memCacheHeight: 350,
                                        errorWidget: (ctx, _, _) => Center(
                                          child: Icon(
                                            Icons.eco_rounded,
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.5),
                                            size: 32,
                                          ),
                                        ),
                                      );
                                    }
                                    return Center(
                                      child: Icon(
                                        Icons.eco_rounded,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                        size: 32,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Wishlist heart button
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Consumer(
                              builder: (context, ref, _) {
                                final isWishlisted = ref.watch(
                                  isInWishlistProvider(product.id),
                                );
                                return GestureDetector(
                                  onTap: () {
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
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
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
                          // Rating & Discount Badges
                          Positioned(
                            top: 6,
                            left: 6,
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
                    const SizedBox(height: 10),
                    // Product Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
                    const SizedBox(height: 8),
                    // Price & Green Quick Add (+) button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Text(
                                '\$${product.effectivePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
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
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
                                       child: Text(
                                         context.l10n.isKhmer
                                             ? 'បានបន្ថែម ${product.name} ទៅកន្ត្រក'
                                             : 'Added ${product.name} to cart',
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                         style: const TextStyle(
                                           fontWeight: FontWeight.w600,
                                         ),
                                       ),
                                     ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
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
                              size: 20,
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
    final isDark = theme.brightness == Brightness.dark;
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: placeholderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
          ),
        ),
      ),
    );
  }
}
