import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_e_commerce/core/storage/local_cache_service.dart';
import 'package:flutter_e_commerce/features/products/models/product.dart';
import 'package:flutter_e_commerce/features/categories/models/category.dart';
import 'package:flutter_e_commerce/features/home/models/banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalCacheService cacheService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cacheService = LocalCacheService();
  });

  group('LocalCacheService', () {
    final mockProduct = Product(
      id: 1,
      slug: 'test-product',
      name: 'Test Product',
      shortDescription: 'Short desc',
      price: 19.99,
      thumbnail: 'https://example.com/image.jpg',
      category: 'Produce',
    );

    final mockCategory = Category(
      id: 1,
      slug: 'produce',
      name: 'Fresh Produce',
      children: [],
    );

    final mockBanner = BannerModel(
      id: 1,
      title: 'Summer Sale',
      imageUrl: 'https://example.com/banner.jpg',
    );

    test('getCachedProducts returns null when cache is empty', () async {
      final result = await cacheService.getCachedProducts();
      expect(result, isNull);
    });

    test('saveCachedProducts and getCachedProducts round trip correctly', () async {
      await cacheService.saveCachedProducts([mockProduct]);
      final result = await cacheService.getCachedProducts();

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.id, 1);
      expect(result.first.name, 'Test Product');
      expect(result.first.price, 19.99);
    });

    test('saveCachedCategories and getCachedCategories round trip correctly', () async {
      await cacheService.saveCachedCategories([mockCategory]);
      final result = await cacheService.getCachedCategories();

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.name, 'Fresh Produce');
      expect(result.first.slug, 'produce');
    });

    test('saveCachedBanners and getCachedBanners round trip correctly', () async {
      await cacheService.saveCachedBanners([mockBanner]);
      final result = await cacheService.getCachedBanners();

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.title, 'Summer Sale');
    });

    test('clearAll wipes cached products, categories, and banners', () async {
      await cacheService.saveCachedProducts([mockProduct]);
      await cacheService.saveCachedCategories([mockCategory]);
      await cacheService.saveCachedBanners([mockBanner]);

      await cacheService.clearAll();

      expect(await cacheService.getCachedProducts(), isNull);
      expect(await cacheService.getCachedCategories(), isNull);
      expect(await cacheService.getCachedBanners(), isNull);
    });
  });
}
