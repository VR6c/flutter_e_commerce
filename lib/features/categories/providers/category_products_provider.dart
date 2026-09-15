import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../products/data/product_repository.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../models/category.dart';

final categoryProductsProvider =
    StateNotifierProvider<CategoryProductsNotifier, CategoryProductsState>((
  ref,
) {
  final repository = ref.watch(productRepositoryProvider);
  final cacheService = ref.watch(localCacheServiceProvider);
  return CategoryProductsNotifier(ref, repository, cacheService);
});

class CategoryProductsState {
  final Map<int, List<Product>> categoryProducts;
  final Map<int, int> categoryCurrentPage;
  final Map<int, int> categoryLastPage;
  final int? loadingCategoryId;
  final int? loadingMoreCategoryId;

  const CategoryProductsState({
    this.categoryProducts = const {},
    this.categoryCurrentPage = const {},
    this.categoryLastPage = const {},
    this.loadingCategoryId,
    this.loadingMoreCategoryId,
  });

  bool isLoading(int categoryId) => loadingCategoryId == categoryId;
  bool isLoadingMore(int categoryId) => loadingMoreCategoryId == categoryId;
  List<Product> productsFor(int categoryId) =>
      categoryProducts[categoryId] ?? const [];
  int currentPage(int categoryId) => categoryCurrentPage[categoryId] ?? 1;
  int lastPage(int categoryId) => categoryLastPage[categoryId] ?? 1;
  bool hasMore(int categoryId) => currentPage(categoryId) < lastPage(categoryId);

  CategoryProductsState copyWith({
    Map<int, List<Product>>? categoryProducts,
    Map<int, int>? categoryCurrentPage,
    Map<int, int>? categoryLastPage,
    int? loadingCategoryId,
    int? loadingMoreCategoryId,
    bool clearLoading = false,
    bool clearLoadingMore = false,
  }) {
    return CategoryProductsState(
      categoryProducts: categoryProducts ?? this.categoryProducts,
      categoryCurrentPage: categoryCurrentPage ?? this.categoryCurrentPage,
      categoryLastPage: categoryLastPage ?? this.categoryLastPage,
      loadingCategoryId:
          clearLoading ? null : (loadingCategoryId ?? this.loadingCategoryId),
      loadingMoreCategoryId: clearLoadingMore
          ? null
          : (loadingMoreCategoryId ?? this.loadingMoreCategoryId),
    );
  }
}

class CategoryProductsNotifier extends StateNotifier<CategoryProductsState> {
  final Ref _ref;
  final ProductRepository _repository;
  final LocalCacheService _cacheService;

  static final _alphanumericRegex = RegExp(r'[^a-z0-9]');

  CategoryProductsNotifier(this._ref, this._repository, this._cacheService)
      : super(const CategoryProductsState());

  /// Helper to find a matching category by slug or name
  static Category? findCategory(String? slug, List<Category> categories) {
    if (slug == null) return null;
    final s = slug.toLowerCase().trim();
    final sClean = s.replaceAll(_alphanumericRegex, '');
    for (final c in categories) {
      final cSlug = c.slug.toLowerCase().trim();
      final cName = c.name.toLowerCase().trim();
      if (cSlug == s ||
          cName == s ||
          cSlug.replaceAll(_alphanumericRegex, '') == sClean ||
          cName.replaceAll(_alphanumericRegex, '') == sClean) {
        return c;
      }
      for (final child in c.children) {
        final childSlug = child.slug.toLowerCase().trim();
        final childName = child.name.toLowerCase().trim();
        if (childSlug == s ||
            childName == s ||
            childSlug.replaceAll(_alphanumericRegex, '') == sClean ||
            childName.replaceAll(_alphanumericRegex, '') == sClean) {
          return Category(
            id: child.id,
            slug: child.slug,
            name: child.name,
            description: child.description,
            imageUrl: child.imageUrl,
            children: const [],
          );
        }
      }
    }
    return null;
  }

  /// Extracts local matches from all products list for instant fallback
  static List<Product> extractLocalMatches(
    Category category,
    List<Product> allProducts,
  ) {
    final target = category.slug.toLowerCase().trim();
    final targetName = category.name.toLowerCase().trim();
    final targetClean = target.replaceAll(_alphanumericRegex, '');
    final targetNameClean = targetName.replaceAll(_alphanumericRegex, '');

    final matchingSlugs = <String>{
      target,
      targetName,
      targetClean,
      targetNameClean,
    };

    for (final child in category.children) {
      final cSlug = child.slug.toLowerCase().trim();
      final cName = child.name.toLowerCase().trim();
      matchingSlugs.addAll([
        cSlug,
        cName,
        cSlug.replaceAll(_alphanumericRegex, ''),
        cName.replaceAll(_alphanumericRegex, ''),
      ]);
    }

    return allProducts.where((p) {
      final cat = p.category.toLowerCase().trim();
      final catClean = cat.replaceAll(_alphanumericRegex, '');
      return matchingSlugs.contains(cat) ||
          matchingSlugs.contains(catClean) ||
          matchingSlugs.any(
            (slug) =>
                (slug.length >= 3 &&
                    (cat.contains(slug) || slug.contains(cat))) ||
                (slug.length >= 3 &&
                    (catClean.contains(slug) || slug.contains(catClean))),
          );
    }).toList();
  }

  /// Warm disk cache into memory
  Future<void> warmCache(List<Category> categories) async {
    for (final cat in categories) {
      if (!state.categoryProducts.containsKey(cat.id)) {
        final cached = await _cacheService.getCachedCategoryProducts(cat.id);
        if (cached != null && cached.isNotEmpty) {
          final updated = Map<int, List<Product>>.from(state.categoryProducts);
          updated[cat.id] = cached;
          state = state.copyWith(categoryProducts: updated);
        }
      }
    }
  }

  /// Select category with fast 3-tier cache strategy (Memory -> Disk -> Fallback -> Network)
  Future<void> selectCategory(Category category) async {
    final categoryId = category.id;

    // 1. In-memory cache hit: instant display, silent sync in background
    if (state.categoryProducts.containsKey(categoryId) &&
        state.categoryProducts[categoryId]!.isNotEmpty) {
      fetchCategoryProducts(categoryId, page: 1, isSilent: true);
      return;
    }

    // 2. Persistent disk cache hit: instant display, silent sync in background
    final diskCached = await _cacheService.getCachedCategoryProducts(categoryId);
    if (diskCached != null && diskCached.isNotEmpty) {
      final updated = Map<int, List<Product>>.from(state.categoryProducts);
      updated[categoryId] = diskCached;
      state = state.copyWith(
        categoryProducts: updated,
        clearLoading: true,
      );
      fetchCategoryProducts(categoryId, page: 1, isSilent: true);
      return;
    }

    // 3. Fallback: extract matches from all-products cache
    final allProducts = _ref.read(productsProvider).valueOrNull ??
        await _cacheService.getCachedProducts() ??
        [];
    final localMatches = extractLocalMatches(category, allProducts);
    if (localMatches.isNotEmpty) {
      final updated = Map<int, List<Product>>.from(state.categoryProducts);
      updated[categoryId] = localMatches;
      state = state.copyWith(
        categoryProducts: updated,
        clearLoading: true,
      );
      fetchCategoryProducts(categoryId, page: 1, isSilent: true);
      return;
    }

    // 4. Cold start: fetch page 1 with loading spinner
    fetchCategoryProducts(categoryId, page: 1, isSilent: false);
  }

  /// Fetches products for a category with pagination support
  Future<void> fetchCategoryProducts(
    int categoryId, {
    int page = 1,
    bool isSilent = false,
  }) async {
    if (page == 1) {
      if (!isSilent) {
        state = state.copyWith(loadingCategoryId: categoryId);
      }
    } else {
      if (state.isLoadingMore(categoryId)) return;
      state = state.copyWith(loadingMoreCategoryId: categoryId);
    }

    try {
      final response = await _repository.fetchProductsPage(
        page: page,
        perPage: 20,
        categoryId: categoryId,
      );

      final current = state.categoryProducts[categoryId] ?? [];
      final existingIds = current.map((p) => p.id).toSet();
      final newItems =
          response.products.where((p) => !existingIds.contains(p.id)).toList();

      final updatedProducts =
          Map<int, List<Product>>.from(state.categoryProducts);
      updatedProducts[categoryId] =
          page == 1 ? response.products : [...current, ...newItems];

      final updatedCurrentPages = Map<int, int>.from(state.categoryCurrentPage);
      updatedCurrentPages[categoryId] = response.currentPage;

      final updatedLastPages = Map<int, int>.from(state.categoryLastPage);
      updatedLastPages[categoryId] = response.lastPage;

      state = state.copyWith(
        categoryProducts: updatedProducts,
        categoryCurrentPage: updatedCurrentPages,
        categoryLastPage: updatedLastPages,
        clearLoading: true,
        clearLoadingMore: true,
      );

      if (page == 1 && response.products.isNotEmpty) {
        await _cacheService.saveCachedCategoryProducts(
          categoryId,
          response.products,
        );
      }
    } catch (e) {
      debugPrint('Error fetching products for category $categoryId: $e');
      state = state.copyWith(clearLoading: true, clearLoadingMore: true);
    }
  }

  /// Load more items for category
  Future<void> loadMore(int categoryId) async {
    if (!state.hasMore(categoryId) || state.isLoadingMore(categoryId)) return;
    await fetchCategoryProducts(
      categoryId,
      page: state.currentPage(categoryId) + 1,
    );
  }
}
