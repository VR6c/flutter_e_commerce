import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../categories/providers/category_provider.dart';
import '../models/product.dart';
import '../models/product_suggestion.dart';
import '../providers/product_provider.dart';
import '../providers/product_suggestions_provider.dart';

final _editionCleanRegex = RegExp(r'\s*[-–—]\s*Edition\s*\d+', caseSensitive: false);
final _editionMatchRegex = RegExp(r'[-–—]\s*(Edition\s*\d+)', caseSensitive: false);

class SearchSuggestionOverlay extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onKeywordSelected;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<Product> onProductSelected;
  final VoidCallback? onClose;

  const SearchSuggestionOverlay({
    super.key,
    required this.query,
    required this.onKeywordSelected,
    required this.onCategorySelected,
    required this.onProductSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));

    final localProducts = ref.watch(productsProvider).valueOrNull ?? [];
    final localCategories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final localResult =
        generateLocalSuggestions(query, localProducts, localCategories);

    final result = suggestionsAsync.valueOrNull ??
        (localResult.isNotEmpty ? localResult : null);

    Widget body;
    if (result != null && result.isNotEmpty) {
      body = _buildContent(context, result, theme, isDark);
    } else if (suggestionsAsync.isLoading && localResult.isEmpty) {
      body = _buildShimmerLoading(isDark, theme);
    } else if (suggestionsAsync.hasError && localResult.isEmpty) {
      body = _buildErrorState(context, theme, isDark);
    } else {
      body = _buildEmptyState(context, theme, isDark);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D38) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: body,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductSuggestionsResult result,
    ThemeData theme,
    bool isDark,
  ) {
    final cleanKeywords = _deduplicateKeywords(result.keywords);
    final uniqueProducts = _deduplicateProducts(result.products);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    query.trim().isEmpty
                        ? context.l10n.trendingSearches
                        : context.l10n.instantSuggestions,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              if (onClose != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onClose?.call();
                  },
                ),
            ],
          ),
        ),

        // Keyword completions chips
        if (cleanKeywords.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cleanKeywords.map((keyword) {
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onKeywordSelected(keyword);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
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
                        Icon(
                          Icons.search_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            keyword,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[200]
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.north_west_rounded,
                          size: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Category pills
        if (result.categories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 14,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.inCategories,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: result.categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.category_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(cat.name),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onCategorySelected(cat.slug);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Product suggestions list
        if (uniqueProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.matchingItems,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
            itemCount: uniqueProducts.take(4).length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final product = uniqueProducts[index];
              return _buildProductTile(context, product, theme, isDark);
            },
          ),
        ],
      ],
    );
  }

  List<String> _deduplicateKeywords(List<String> rawKeywords) {
    final seen = <String>{};
    final unique = <String>[];
    for (final raw in rawKeywords) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final cleaned = trimmed.replaceAll(_editionCleanRegex, '').trim();
      final candidate = cleaned.isNotEmpty ? cleaned : trimmed;
      if (seen.add(candidate.toLowerCase())) {
        unique.add(candidate);
      }
    }
    return unique.take(6).toList();
  }

  List<Product> _deduplicateProducts(List<Product> rawProducts) {
    final seenIds = <int>{};
    final seenBaseNames = <String>{};
    final unique = <Product>[];

    for (final p in rawProducts) {
      if (!seenIds.add(p.id)) continue;
      final baseName = p.name.replaceAll(_editionCleanRegex, '').trim().toLowerCase();
      if (seenBaseNames.add(baseName)) {
        unique.add(p);
      }
    }

    if (unique.length < 4 && rawProducts.length > unique.length) {
      for (final p in rawProducts) {
        if (!unique.any((item) => item.id == p.id)) {
          unique.add(p);
          if (unique.length >= 4) break;
        }
      }
    }

    return unique.take(4).toList();
  }

  Widget _buildProductTile(
    BuildContext context,
    Product product,
    ThemeData theme,
    bool isDark,
  ) {
    final editionMatch = _editionMatchRegex.firstMatch(product.name);
    final cleanName = product.name.replaceAll(_editionCleanRegex, '').trim();
    final displayName = cleanName.isNotEmpty ? cleanName : product.name;
    final editionTag = editionMatch?.group(1);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onProductSelected(product);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.thumbnail.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: product.thumbnail,
                        fit: BoxFit.contain,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                        fallbackSlug: product.slug,
                        fallbackTitle: product.name,
                        fallbackCategory: product.category,
                        errorWidget: Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      if (editionTag != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            editionTag,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      if (product.rating != null && product.rating! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price & arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${product.effectivePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (product.hasDiscount && product.originalPrice != null)
                  Text(
                    '\$${product.originalPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const SizedBox(height: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        highlightColor:
            isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 20,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.noInstantSuggestions,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.couldNotLoadSuggestions,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
