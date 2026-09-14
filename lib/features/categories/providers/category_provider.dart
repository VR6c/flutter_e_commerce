import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../../../core/storage/local_cache_service.dart';
import '../data/category_repository.dart';
import '../models/category.dart';

part 'category_provider.g.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryRepository(apiClient);
});

@Riverpod(keepAlive: true)
class Categories extends _$Categories {
  @override
  FutureOr<List<Category>> build() async {
    final cacheService = ref.watch(localCacheServiceProvider);
    final repository = ref.watch(categoryRepositoryProvider);

    // 1. Instant Cache: Load from local disk in < 15ms
    final cached = await cacheService.getCachedCategories();
    if (cached != null && cached.isNotEmpty) {
      _backgroundSync(repository, cacheService);
      return cached;
    }

    // 2. Fetch from API and persist
    final categories = await repository.fetchCategories();
    await cacheService.saveCachedCategories(categories);
    return categories;
  }

  void _backgroundSync(
    CategoryRepository repository,
    LocalCacheService cacheService,
  ) {
    Future.microtask(() async {
      try {
        final fresh = await repository.fetchCategories();
        state = AsyncData(fresh);
        await cacheService.saveCachedCategories(fresh);
      } catch (e) {
        debugPrint('Background categories sync error (cached data preserved): $e');
      }
    });
  }

  Future<void> refresh() async {
    final repository = ref.read(categoryRepositoryProvider);
    final cacheService = ref.read(localCacheServiceProvider);
    try {
      final fresh = await repository.fetchCategories();
      state = AsyncData(fresh);
      await cacheService.saveCachedCategories(fresh);
    } catch (e) {
      debugPrint('Error refreshing categories: $e');
    }
  }
}
