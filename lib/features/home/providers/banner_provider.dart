import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../../../core/storage/local_cache_service.dart';
import '../data/banner_repository.dart';
import '../models/banner.dart';

part 'banner_provider.g.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BannerRepository(apiClient);
});

@Riverpod(keepAlive: true)
class Banners extends _$Banners {
  @override
  FutureOr<List<BannerModel>> build() async {
    final cacheService = ref.watch(localCacheServiceProvider);
    final repository = ref.watch(bannerRepositoryProvider);

    // 1. Instant Cache: Load from local disk in < 15ms
    final cached = await cacheService.getCachedBanners();
    if (cached != null && cached.isNotEmpty) {
      _backgroundSync(repository, cacheService);
      return cached;
    }

    // 2. Fetch from API and persist
    final banners = await repository.fetchBanners();
    await cacheService.saveCachedBanners(banners);
    return banners;
  }

  void _backgroundSync(
    BannerRepository repository,
    LocalCacheService cacheService,
  ) {
    Future.microtask(() async {
      try {
        final fresh = await repository.fetchBanners();
        state = AsyncData(fresh);
        await cacheService.saveCachedBanners(fresh);
      } catch (e) {
        debugPrint('Background banners sync error (cached data preserved): $e');
      }
    });
  }

  Future<void> refresh() async {
    final repository = ref.read(bannerRepositoryProvider);
    final cacheService = ref.read(localCacheServiceProvider);
    try {
      final fresh = await repository.fetchBanners();
      state = AsyncData(fresh);
      await cacheService.saveCachedBanners(fresh);
    } catch (e) {
      debugPrint('Error refreshing banners: $e');
    }
  }
}
