import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';
import 'package:flutter_e_commerce/core/api/api_endpoints.dart';
import 'package:flutter_e_commerce/features/categories/models/category.dart';
import 'package:flutter_e_commerce/features/products/data/product_repository.dart';
import 'package:flutter_e_commerce/features/products/models/product.dart';
import 'package:flutter_e_commerce/features/products/models/product_suggestion.dart';
import 'package:flutter_e_commerce/features/products/providers/product_suggestions_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProductRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    final dio = Dio(
      BaseOptions(baseUrl: 'https://e-commers-laravel.vercel.app/api'),
    );
    when(() => mockApiClient.dio).thenReturn(dio);
    repository = ProductRepository(mockApiClient);
  });

  group('ProductSuggestionsResult & SuggestionCategory Models', () {
    test('SuggestionCategory correctly parses json and serializes', () {
      final json = {'id': 4, 'name': 'Smartphones', 'slug': 'smartphones'};
      final cat = SuggestionCategory.fromJson(json);

      expect(cat.id, 4);
      expect(cat.name, 'Smartphones');
      expect(cat.slug, 'smartphones');

      final serialized = cat.toJson();
      expect(serialized['id'], 4);
      expect(serialized['name'], 'Smartphones');
      expect(serialized['slug'], 'smartphones');
    });

    test('ProductSuggestionsResult reports isEmpty and isNotEmpty correctly', () {
      const emptyResult = ProductSuggestionsResult();
      expect(emptyResult.isEmpty, isTrue);
      expect(emptyResult.isNotEmpty, isFalse);

      final withKeywords = ProductSuggestionsResult(keywords: ['iphone']);
      expect(withKeywords.isEmpty, isFalse);
      expect(withKeywords.isNotEmpty, isTrue);
    });
  });

  group('ProductRepository.fetchSuggestions', () {
    test('fetches live autocomplete suggestions with keywords and categories', () async {
      when(() => mockApiClient.get(
            ApiEndpoints.productSuggestions,
            queryParameters: {
              'limit': 10,
              'q': 'apple',
              'type': 'search',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.productSuggestions),
          data: {
            'status': true,
            'data': [
              {
                'id': 101,
                'slug': 'apple-iphone-15-pro',
                'name': 'Apple iPhone 15 Pro',
                'price': 999.0,
                'discount_price': 949.0,
                'thumbnail': 'https://example.com/iphone.jpg',
                'category': 'Smartphones',
                'category_id': 4,
                'brand': 'Apple',
                'brand_id': 2,
                'rating': 4.9,
                'reviews_count': 38,
              },
            ],
            'keywords': ['Apple iPhone 15 Pro', 'apple', 'Smartphones'],
            'categories': [
              {'id': 4, 'name': 'Smartphones', 'slug': 'smartphones'},
            ],
          },
          statusCode: 200,
        ),
      );

      final result = await repository.fetchSuggestions(
        query: 'apple',
        type: 'search',
        limit: 10,
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.keywords, contains('Apple iPhone 15 Pro'));
      expect(result.categories.length, 1);
      expect(result.categories.first.name, 'Smartphones');

      expect(result.products.length, 1);
      final product = result.products.first;
      expect(product.id, 101);
      expect(product.name, 'Apple iPhone 15 Pro');
      expect(product.slug, 'apple-iphone-15-pro');
      expect(product.rating, 4.9);
      expect(product.category, 'Smartphones');
      expect(product.brand, 'Apple');
      expect(product.variants.isNotEmpty, isTrue);
      expect(product.variants.first.discountPrice, 949.0);
    });

    test('handles empty results gracefully', () async {
      when(() => mockApiClient.get(
            ApiEndpoints.productSuggestions,
            queryParameters: {
              'limit': 10,
              'q': 'nonexistent',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.productSuggestions),
          data: {
            'status': true,
            'data': [],
            'keywords': [],
            'categories': [],
          },
          statusCode: 200,
        ),
      );

      final result = await repository.fetchSuggestions(
        query: 'nonexistent',
        limit: 10,
      );

      expect(result.isEmpty, isTrue);
      expect(result.products, isEmpty);
      expect(result.keywords, isEmpty);
      expect(result.categories, isEmpty);
    });

    test('supports page and perPage pagination for suggestions', () async {
      when(() => mockApiClient.get(
            ApiEndpoints.productSuggestions,
            queryParameters: {
              'limit': 10,
              'page': 2,
              'per_page': 10,
              'type': 'recommended',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.productSuggestions),
          data: {
            'status': true,
            'data': [],
            'keywords': [],
            'categories': [],
          },
          statusCode: 200,
        ),
      );

      final result = await repository.fetchSuggestions(
        type: 'recommended',
        page: 2,
        perPage: 10,
      );

      expect(result.isEmpty, isTrue);
    });
  });

  group('ProductRepository.fetchRelatedProducts', () {
    test('fetches related products by slug successfully', () async {
      const slug = 'apple-iphone-15-pro';
      when(() => mockApiClient.get(
            ApiEndpoints.productRelated(slug),
            queryParameters: {'limit': 8},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.productRelated(slug)),
          data: {
            'status': true,
            'product': {
              'id': 101,
              'name': 'Apple iPhone 15 Pro',
              'slug': slug,
            },
            'data': [
              {
                'id': 102,
                'slug': 'apple-iphone-15',
                'name': 'Apple iPhone 15',
                'price': 799.0,
                'thumbnail': 'https://example.com/iphone15.jpg',
                'category': 'Smartphones',
                'brand': 'Apple',
                'rating': 4.7,
              },
            ],
          },
          statusCode: 200,
        ),
      );

      final related = await repository.fetchRelatedProducts(slug, limit: 8);

      expect(related.length, 1);
      expect(related.first.id, 102);
      expect(related.first.name, 'Apple iPhone 15');
      expect(related.first.slug, 'apple-iphone-15');
      expect(related.first.price, 799.0);
    });

    test('returns empty list when related product response has no data', () async {
      const slug = 'unknown-item';
      when(() => mockApiClient.get(
            ApiEndpoints.productRelated(slug),
            queryParameters: {'limit': 8},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.productRelated(slug)),
          data: {
            'status': true,
            'data': [],
          },
          statusCode: 200,
        ),
      );

      final related = await repository.fetchRelatedProducts(slug, limit: 8);
      expect(related, isEmpty);
    });

    test('defaults to limit: 10 and supports page parameter', () async {
      const slug = 'apple-iphone-15-pro';
      when(() => mockApiClient.get(
            ApiEndpoints.productRelated(slug),
            queryParameters: {'limit': 10, 'page': 2},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.productRelated(slug)),
          data: {
            'status': true,
            'data': [],
          },
          statusCode: 200,
        ),
      );

      final related = await repository.fetchRelatedProducts(slug, page: 2);
      expect(related, isEmpty);
    });
  });

  group('generateLocalSuggestions (0ms instant matching)', () {
    final mockProducts = [
      const Product(
        id: 1,
        slug: 'apple-iphone',
        name: 'Apple iPhone 15',
        shortDescription: 'Latest phone',
        price: 999.0,
        thumbnail: 'https://example.com/p1.png',
        category: 'Smartphones',
        rating: 4.9,
      ),
      const Product(
        id: 2,
        slug: 'pineapple-fruit',
        name: 'Fresh Pineapple',
        shortDescription: 'Tropical fruit',
        price: 4.5,
        thumbnail: 'https://example.com/p2.png',
        category: 'Fruits',
        rating: 4.6,
      ),
      const Product(
        id: 3,
        slug: 'samsung-galaxy',
        name: 'Samsung Galaxy S24',
        shortDescription: 'Android phone',
        price: 899.0,
        thumbnail: 'https://example.com/p3.png',
        category: 'Smartphones',
        rating: 4.7,
      ),
    ];

    final mockCategories = [
      const Category(
        id: 10,
        name: 'Smartphones',
        slug: 'smartphones',
        children: [],
      ),
      const Category(
        id: 11,
        name: 'Fruits',
        slug: 'fruits',
        children: [],
      ),
    ];

    test('matches prefix first and extracts categories & keywords', () {
      final res = generateLocalSuggestions('apple', mockProducts, mockCategories);

      expect(res.isNotEmpty, isTrue);
      expect(res.products.length, 2);
      expect(res.products.first.name, 'Apple iPhone 15'); // Prefix match comes first
      expect(res.products.last.name, 'Fresh Pineapple'); // Substring match comes second
      expect(res.keywords, contains('Apple iPhone 15'));
    });

    test('returns trending categories & products on empty query', () {
      final res = generateLocalSuggestions('', mockProducts, mockCategories);

      expect(res.isNotEmpty, isTrue);
      expect(res.categories.length, 2);
      expect(res.products.first.name, 'Apple iPhone 15'); // Highest rated (4.9) first
      expect(res.keywords, contains('Smartphones'));
      expect(res.keywords, contains('Fruits'));
    });
  });
}
