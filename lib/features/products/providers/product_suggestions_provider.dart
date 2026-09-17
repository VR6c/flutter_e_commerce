import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../models/product_suggestion.dart';
import 'product_provider.dart';

// In-memory query cache for instant (0ms) autocomplete lookups
final Map<String, ProductSuggestionsResult> _searchQueryCache = {};

// In-memory cache for related products per slug
final Map<String, List<Product>> _relatedProductsCache = {};

/// Fast in-memory suggestion generator using catalog and categories already on device.
ProductSuggestionsResult generateLocalSuggestions(
  String query,
  List<Product> products,
  List<Category> categories,
) {
  final q = query.trim().toLowerCase();

  if (q.isEmpty) {
    // Trending: top categories and top-rated products
    final trendingKeywords = categories.map((c) => c.name).take(4).toList();
    final topProducts = List<Product>.from(products)
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final trendingCategories = categories
        .take(4)
        .map((c) => SuggestionCategory(id: c.id, name: c.name, slug: c.slug))
        .toList();

    return ProductSuggestionsResult(
      products: topProducts.take(4).toList(),
      keywords: trendingKeywords,
      categories: trendingCategories,
    );
  }

  // Matching categories
  final matchingCategories = categories
      .where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            c.slug.toLowerCase().contains(q),
      )
      .take(4)
      .map((c) => SuggestionCategory(id: c.id, name: c.name, slug: c.slug))
      .toList();

  // Matching products: prioritize startsWith, then contains
  final prefixMatches = <Product>[];
  final containsMatches = <Product>[];

  for (final p in products) {
    final nameLower = p.name.toLowerCase();
    final catLower = p.category.toLowerCase();
    final brandLower = p.brand?.toLowerCase() ?? '';

    if (nameLower.startsWith(q)) {
      prefixMatches.add(p);
    } else if (nameLower.contains(q) ||
        catLower.contains(q) ||
        brandLower.contains(q)) {
      containsMatches.add(p);
    }
  }

  final matchingProducts = [
    ...prefixMatches,
    ...containsMatches,
  ].take(6).toList();

  // Extract keywords
  final keywordSet = <String>{};
  for (final p in matchingProducts) {
    keywordSet.add(p.name);
  }
  for (final c in matchingCategories) {
    keywordSet.add(c.name);
  }

  return ProductSuggestionsResult(
    products: matchingProducts,
    keywords: keywordSet.take(6).toList(),
    categories: matchingCategories,
  );
}

/// Provider for personalized & trending "Suggested For You" feed on the Home Screen.
/// Keeps alive and leverages local cache + instant fallback from products catalog for 0ms render.
final suggestedForYouProvider =
    AsyncNotifierProvider<SuggestedForYouNotifier, List<Product>>(
      SuggestedForYouNotifier.new,
    );

class SuggestedForYouNotifier extends AsyncNotifier<List<Product>> {
  @override
  FutureOr<List<Product>> build() async {
    final cacheService = ref.watch(localCacheServiceProvider);
    final repository = ref.watch(productRepositoryProvider);

    // 1. Instant Cache: Load from dedicated suggestions cache in < 15ms
    final cached = await cacheService.getCachedSuggestions();
    if (cached != null && cached.isNotEmpty) {
      _backgroundSync(repository, cacheService);
      return cached;
    }

    // 2. Instant Fallback: If no suggestion cache yet, derive from cached products
    final cachedProducts = await cacheService.getCachedProducts();
    if (cachedProducts != null && cachedProducts.isNotEmpty) {
      final fallback = _deriveRecommendedFromProducts(cachedProducts);
      _backgroundSync(repository, cacheService);
      return fallback;
    }

    // 3. First launch: fetch from API and save
    try {
      final result = await repository.fetchSuggestions(
        type: 'recommended',
        limit: 10,
      );
      if (result.products.isNotEmpty) {
        await cacheService.saveCachedSuggestions(result.products);
        return result.products;
      }
    } catch (e) {
      debugPrint('Error fetching suggestions on initial launch: $e');
    }

    return const [];
  }

  void _backgroundSync(
    ProductRepository repository,
    LocalCacheService cacheService,
  ) {
    Future.microtask(() async {
      try {
        final result = await repository.fetchSuggestions(
          type: 'recommended',
          limit: 10,
        );
        if (result.products.isNotEmpty) {
          state = AsyncData(result.products);
          await cacheService.saveCachedSuggestions(result.products);
        }
      } catch (e) {
        debugPrint(
          'Background suggestions sync error (cached data preserved): $e',
        );
      }
    });
  }

  List<Product> _deriveRecommendedFromProducts(List<Product> products) {
    final sorted = List<Product>.from(products)
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sorted.take(10).toList();
  }

  Future<void> refresh() async {
    final repository = ref.read(productRepositoryProvider);
    final cacheService = ref.read(localCacheServiceProvider);
    try {
      final result = await repository.fetchSuggestions(
        type: 'recommended',
        limit: 10,
      );
      if (result.products.isNotEmpty) {
        state = AsyncData(result.products);
        await cacheService.saveCachedSuggestions(result.products);
      }
    } catch (e) {
      debugPrint('Error refreshing suggestions: $e');
    }
  }
}

/// Live Search Autocomplete / Typeahead provider with query cache and 0ms fallback.
final searchSuggestionsProvider =
    FutureProvider.family<ProductSuggestionsResult, String>((ref, query) async {
      final trimmed = query.trim().toLowerCase();

      // 1. Instant hit from in-memory cache
      if (_searchQueryCache.containsKey(trimmed)) {
        return _searchQueryCache[trimmed]!;
      }

      // 2. Immediate local fallback from memory or disk cache
      final products =
          ref.read(productsProvider).valueOrNull ??
          await ref.read(localCacheServiceProvider).getCachedProducts() ??
          [];
      final categories =
          ref.read(categoriesProvider).valueOrNull ??
          await ref.read(localCacheServiceProvider).getCachedCategories() ??
          [];
      final local = generateLocalSuggestions(trimmed, products, categories);
      if (local.isNotEmpty && !_searchQueryCache.containsKey(trimmed)) {
        _searchQueryCache[trimmed] = local;
      }

      final repository = ref.watch(productRepositoryProvider);

      try {
        final result = await repository.fetchSuggestions(
          query: trimmed.isNotEmpty ? trimmed : null,
          type: trimmed.isNotEmpty ? 'search' : 'trending',
          limit: 10,
        );

        if (result.isNotEmpty) {
          _searchQueryCache[trimmed] = result;
          return result;
        }
      } catch (e) {
        debugPrint('Search suggestions network notice: $e');
      }

      return _searchQueryCache[trimmed] ?? local;
    });

/// Contextual related product suggestions with in-memory caching and 0ms category fallback.
final relatedProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  slug,
) async {
  if (slug.isEmpty) return const [];

  if (_relatedProductsCache.containsKey(slug)) {
    return _relatedProductsCache[slug]!;
  }

  // 1. Compute instant local same-category fallback from loaded or cached products
  final allProducts =
      ref.read(productsProvider).valueOrNull ??
      await ref.read(localCacheServiceProvider).getCachedProducts() ??
      [];
  final current = allProducts.where((p) => p.slug == slug).firstOrNull;
  final localFallback = current != null
      ? allProducts
            .where((p) => p.id != current.id && p.category == current.category)
            .take(10)
            .toList()
      : <Product>[];

  if (localFallback.isNotEmpty && !_relatedProductsCache.containsKey(slug)) {
    _relatedProductsCache[slug] = localFallback;
  }

  final repository = ref.watch(productRepositoryProvider);
  try {
    final related = await repository.fetchRelatedProducts(slug, limit: 10);
    if (related.isNotEmpty) {
      _relatedProductsCache[slug] = related;
      return related;
    }
  } catch (e) {
    debugPrint('Related products network notice: $e');
  }

  return _relatedProductsCache[slug] ?? localFallback;
});
