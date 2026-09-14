import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../../../core/storage/local_cache_service.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

part 'product_provider.g.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepository(apiClient);
});

/// Indicates whether subsequent pages are actively being fetched during infinite scroll
final isProductsLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// Provides whether there are more product pages to load
final hasMoreProductsProvider = Provider<bool>((ref) {
  ref.watch(productsProvider);
  return ref.read(productsProvider.notifier).hasMore;
});

@Riverpod(keepAlive: true)
class Products extends _$Products {
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isFetchingMore = false;

  bool get hasMore => _currentPage < _lastPage;
  bool get isFetchingMore => _isFetchingMore;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;

  @override
  FutureOr<List<Product>> build() async {
    final cacheService = ref.watch(localCacheServiceProvider);
    final repository = ref.watch(productRepositoryProvider);

    // 1. Instant Cache: Load from local disk in < 15ms
    final cached = await cacheService.getCachedProducts();
    if (cached != null && cached.isNotEmpty) {
      _backgroundSync(repository, cacheService);
      return cached;
    }

    // 2. Fetch Page 1 (fast, 20 items)
    final response = await repository.fetchProductsPage(page: 1, perPage: 20);
    _currentPage = response.currentPage;
    _lastPage = response.lastPage;
    await cacheService.saveCachedProducts(response.products);
    return response.products;
  }

  void _backgroundSync(
    ProductRepository repository,
    LocalCacheService cacheService,
  ) {
    Future.microtask(() async {
      try {
        final response = await repository.fetchProductsPage(page: 1, perPage: 20);
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        state = AsyncData(response.products);
        await cacheService.saveCachedProducts(response.products);
      } catch (e) {
        debugPrint('Background products sync error (cached data preserved): $e');
      }
    });
  }

  /// Fetches the next page of products on-demand when the user scrolls near the bottom.
  Future<void> loadMore() async {
    if (_isFetchingMore || !hasMore) return;
    _isFetchingMore = true;
    ref.read(isProductsLoadingMoreProvider.notifier).state = true;

    try {
      final repository = ref.read(productRepositoryProvider);
      final cacheService = ref.read(localCacheServiceProvider);
      final nextPage = _currentPage + 1;
      final response = await repository.fetchProductsPage(page: nextPage, perPage: 20);

      _currentPage = response.currentPage;
      _lastPage = response.lastPage;

      final currentList = state.valueOrNull ?? [];
      final existingIds = currentList.map((p) => p.id).toSet();
      final newItems = response.products.where((p) => !existingIds.contains(p.id)).toList();
      final updatedList = [...currentList, ...newItems];

      state = AsyncData(updatedList);
      await cacheService.saveCachedProducts(updatedList);
    } catch (e) {
      debugPrint('Error loading more products: $e');
    } finally {
      _isFetchingMore = false;
      ref.read(isProductsLoadingMoreProvider.notifier).state = false;
    }
  }

  /// Explicit pull-to-refresh: resets pagination back to Page 1
  Future<void> refresh() async {
    final repository = ref.read(productRepositoryProvider);
    final cacheService = ref.read(localCacheServiceProvider);
    try {
      final response = await repository.fetchProductsPage(page: 1, perPage: 20);
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      state = AsyncData(response.products);
      await cacheService.saveCachedProducts(response.products);
    } catch (e) {
      debugPrint('Error refreshing products: $e');
    }
  }
}
