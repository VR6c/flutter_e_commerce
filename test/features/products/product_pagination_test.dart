import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';
import 'package:flutter_e_commerce/core/storage/local_cache_service.dart';
import 'package:flutter_e_commerce/features/products/data/product_repository.dart';
import 'package:flutter_e_commerce/features/products/providers/product_provider.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockLocalCacheService extends Mock implements LocalCacheService {}

void main() {
  late MockApiClient mockApiClient;
  late MockLocalCacheService mockCacheService;
  late ProductRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    mockCacheService = MockLocalCacheService();
    final dio = Dio(BaseOptions(baseUrl: 'https://e-commers-laravel.vercel.app/api'));
    when(() => mockApiClient.dio).thenReturn(dio);
    repository = ProductRepository(mockApiClient);

    when(() => mockCacheService.getCachedProducts()).thenAnswer((_) async => null);
    when(() => mockCacheService.saveCachedProducts(any())).thenAnswer((_) async {});
  });

  Map<String, dynamic> makePagePayload({required int page, required int lastPage, required List<int> ids}) {
    return {
      'data': ids.map((id) => {
        'id': id,
        'slug': 'product-$id',
        'name': 'Product $id',
        'short_description': 'Description $id',
        'price': 100.0,
        'thumbnail': '/uploads/p$id.png',
        'category': 'Shoes',
      }).toList(),
      'meta': {
        'current_page': page,
        'last_page': lastPage,
        'total': lastPage * ids.length,
      },
    };
  }

  group('ProductRepository Pagination', () {
    test('fetchProductsPage parses page 1 with hasMore = true when last_page > 1', () async {
      when(() => mockApiClient.get('/products', queryParameters: {'page': 1, 'per_page': 20})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/products'),
          data: makePagePayload(page: 1, lastPage: 3, ids: [1, 2]),
          statusCode: 200,
        ),
      );

      final res = await repository.fetchProductsPage(page: 1);

      expect(res.currentPage, 1);
      expect(res.lastPage, 3);
      expect(res.hasMore, isTrue);
      expect(res.products.length, 2);
      expect(res.products.first.name, 'Product 1');
    });

    test('fetchProductsPage reports hasMore = false on the final page', () async {
      when(() => mockApiClient.get('/products', queryParameters: {'page': 3, 'per_page': 20})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/products'),
          data: makePagePayload(page: 3, lastPage: 3, ids: [5, 6]),
          statusCode: 200,
        ),
      );

      final res = await repository.fetchProductsPage(page: 3);

      expect(res.currentPage, 3);
      expect(res.lastPage, 3);
      expect(res.hasMore, isFalse);
    });
  });

  group('Products Notifier Infinite Scroll', () {
    test('build loads page 1 and loadMore appends page 2', () async {
      when(() => mockApiClient.get('/products', queryParameters: {'page': 1, 'per_page': 20})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/products'),
          data: makePagePayload(page: 1, lastPage: 2, ids: [1, 2]),
          statusCode: 200,
        ),
      );

      when(() => mockApiClient.get('/products', queryParameters: {'page': 2, 'per_page': 20})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/products'),
          data: makePagePayload(page: 2, lastPage: 2, ids: [3, 4]),
          statusCode: 200,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          localCacheServiceProvider.overrideWithValue(mockCacheService),
        ],
      );
      addTearDown(container.dispose);

      // 1. Initial build: Page 1 items
      final initial = await container.read(productsProvider.future);
      expect(initial.map((p) => p.id).toList(), [1, 2]);
      expect(container.read(productsProvider.notifier).hasMore, isTrue);
      expect(container.read(isProductsLoadingMoreProvider), isFalse);

      // 2. Trigger loadMore for page 2
      await container.read(productsProvider.notifier).loadMore();

      final updated = container.read(productsProvider).valueOrNull ?? [];
      expect(updated.map((p) => p.id).toList(), [1, 2, 3, 4]);
      expect(container.read(productsProvider.notifier).hasMore, isFalse);
      expect(container.read(isProductsLoadingMoreProvider), isFalse);

      verify(() => mockCacheService.saveCachedProducts(any())).called(greaterThanOrEqualTo(2));
    });

    test('fetchProductsPage normalizes string and numeric id safely', () async {
      when(() => mockApiClient.get('/products', queryParameters: {'page': 1, 'per_page': 20})).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/products'),
          data: {
            'data': [
              {
                'id': '99',
                'slug': 'product-99',
                'name': 'String ID Product',
                'short_description': 'Description',
                'price': 49.99,
                'thumbnail': '/uploads/p99.png',
                'category': 'Shoes',
              }
            ],
            'meta': {
              'current_page': 1,
              'last_page': 1,
              'total': 1,
            },
          },
          statusCode: 200,
        ),
      );

      final res = await repository.fetchProductsPage(page: 1);
      expect(res.products.length, 1);
      expect(res.products.first.id, 99);
    });
  });
}
