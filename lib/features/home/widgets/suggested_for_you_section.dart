import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/product_card.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../../products/providers/product_suggestions_provider.dart';

/// Memoized fallback provider that only re-computes sorted top-rated items when productsProvider updates
final topRatedFallbackProvider = Provider<List<Product>>((ref) {
  final allProducts = ref.watch(productsProvider).valueOrNull ?? [];
  if (allProducts.isEmpty) return const [];
  final sorted = List<Product>.from(allProducts)
    ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  return sorted.take(8).toList();
});

class SuggestedForYouSection extends ConsumerWidget {
  const SuggestedForYouSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestedAsync = ref.watch(suggestedForYouProvider);
    final localTopRated = ref.watch(topRatedFallbackProvider);

    final products = suggestedAsync.valueOrNull ??
        (localTopRated.isNotEmpty ? localTopRated : null);

    if (products != null) {
      if (products.isEmpty) return const SizedBox.shrink();
      return _buildContent(context, theme, isDark, products);
    }

    if (suggestedAsync.isLoading) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.suggestedForYou,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            context.l10n.suggestedForYouSub,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.5,
                              letterSpacing: 0,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      context.l10n.aiPicked,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Carousel
            SizedBox(
              height: 255,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 170,
                    child: ProductCard(
                      product: product,
                      heroTagPrefix: 'suggested',
                      onTap: () {
                        context.push(
                          AppRoutes.productDetail,
                          extra: {
                            'product': product,
                            'heroTag': 'suggested_product_${product.id}',
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
  }

  Widget _buildLoading(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
              const SizedBox(width: 10),
              Container(
                width: 130,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 255,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const SizedBox(
              width: 170,
              child: ProductCardShimmer(),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
