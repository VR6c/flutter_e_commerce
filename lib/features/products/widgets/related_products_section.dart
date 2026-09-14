import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/product_card.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/product_suggestions_provider.dart';

/// Memoized fallback provider that finds related category products from cache
final relatedFallbackProvider =
    Provider.family<List<Product>, String>((ref, productSlug) {
  final allProducts = ref.watch(productsProvider).valueOrNull ?? [];
  if (allProducts.isEmpty) return const [];
  final current = allProducts.where((p) => p.slug == productSlug).firstOrNull;
  if (current == null) return const [];
  return allProducts
      .where((p) => p.id != current.id && p.category == current.category)
      .take(8)
      .toList();
});

class RelatedProductsSection extends ConsumerWidget {
  final String productSlug;

  const RelatedProductsSection({
    super.key,
    required this.productSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final relatedAsync = ref.watch(relatedProductsProvider(productSlug));
    final localFallback = ref.watch(relatedFallbackProvider(productSlug));

    final products = relatedAsync.valueOrNull ??
        (localFallback.isNotEmpty ? localFallback : null);

    if (products != null) {
      if (products.isEmpty) return const SizedBox.shrink();
      return _buildContent(context, theme, isDark, products);
    }

    if (relatedAsync.isLoading) {
      return _buildLoading(isDark);
    }

    return const SizedBox.shrink();
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<Product> products,
  ) {
    return Column(
          children: [
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.recommend_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You May Also Like',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Similar Items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal scrolling carousel
            SizedBox(
              height: 255,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 170,
                    child: ProductCard(
                      product: product,
                      heroTagPrefix: 'related_$productSlug',
                      onTap: () {
                        context.push(
                          AppRoutes.productDetail,
                          extra: {
                            'product': product,
                            'heroTag':
                                'related_${productSlug}_product_${product.id}',
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
  }

  Widget _buildLoading(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 255,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const SizedBox(
              width: 170,
              child: ProductCardShimmer(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
