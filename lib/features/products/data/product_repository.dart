import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../models/product.dart';
import '../models/product_review.dart';
import '../models/product_suggestion.dart';

class PaginatedProductsResponse {
  final List<Product> products;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedProductsResponse({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  /// Fetches a single page of products on demand with optional filtering.
  Future<PaginatedProductsResponse> fetchProductsPage({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    int? brandId,
    String? search,
    String? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (categoryId != null) queryParameters['category_id'] = categoryId;
    if (brandId != null) queryParameters['brand_id'] = brandId;
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }
    if (sort != null && sort.isNotEmpty) queryParameters['sort'] = sort;

    final response = await _apiClient.get(
      '/products',
      queryParameters: queryParameters,
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      final baseUrl = _apiClient.dio.options.baseUrl;
      final products = (data['data'] as List)
          .map((item) => _parseProduct(item, baseUrl))
          .toList();

      final meta = data['meta'];
      final lastPage = meta is Map<String, dynamic> ? (meta['last_page'] as int? ?? 1) : 1;
      final currentPage = meta is Map<String, dynamic> ? (meta['current_page'] as int? ?? page) : page;
      final total = meta is Map<String, dynamic> ? (meta['total'] as int? ?? products.length) : products.length;

      return PaginatedProductsResponse(
        products: products,
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
      );
    }
    throw Exception('Invalid products response structure');
  }

  Future<List<Product>> fetchProducts() async {
    final res = await fetchProductsPage(page: 1, perPage: 20);
    return res.products;
  }

  /// Fetches products progressively: emits Page 1 as soon as received,
  /// then streams remaining pages in the background without blocking the UI.
  Future<List<Product>> fetchProductsProgressive({
    void Function(List<Product> partialList)? onPageLoaded,
  }) async {
    final firstPage = await fetchProductsPage(page: 1, perPage: 20);
    final allProducts = List<Product>.from(firstPage.products);

    // Immediately notify caller with Page 1 so UI renders without waiting
    onPageLoaded?.call(List<Product>.from(allProducts));

    if (firstPage.lastPage > 1) {
      final remainingFutures = <Future<PaginatedProductsResponse>>[];
      for (int p = 2; p <= firstPage.lastPage; p++) {
        remainingFutures.add(fetchProductsPage(page: p, perPage: 20));
      }
      try {
        final responses = await Future.wait(remainingFutures);
        for (final resp in responses) {
          allProducts.addAll(resp.products);
        }
        onPageLoaded?.call(List<Product>.from(allProducts));
      } catch (e) {
        debugPrint('Error fetching remaining product pages: $e');
      }
    }

    return allProducts;
  }

  /// Fetches suggestions for live search autocomplete, recommended items, or trending items.
  Future<ProductSuggestionsResult> fetchSuggestions({
    String? query,
    int? categoryId,
    int? brandId,
    String? type,
    int limit = 10,
    int? excludeId,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (brandId != null) queryParams['brand_id'] = brandId;
    if (type != null) queryParams['type'] = type;
    if (excludeId != null) queryParams['exclude_id'] = excludeId;

    final response = await _apiClient.get(
      ApiEndpoints.productSuggestions,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final baseUrl = _apiClient.dio.options.baseUrl;
      final productsList = data['data'];
      final List<Product> rawProducts = productsList is List
          ? productsList.map((item) => _parseProduct(item, baseUrl)).toList()
          : <Product>[];

      // Deduplicate products by id and diversify suggestions by base name
      final seenProductIds = <int>{};
      final seenBaseNames = <String>{};
      final List<Product> products = [];
      for (final p in rawProducts) {
        if (!seenProductIds.add(p.id)) continue;
        final baseName = p.name
            .replaceAll(
              RegExp(r'\s*[-–—]\s*Edition\s*\d+', caseSensitive: false),
              '',
            )
            .trim()
            .toLowerCase();
        if (seenBaseNames.add(baseName)) {
          products.add(p);
        }
      }
      // If diversity filter leaves fewer than 4 items, backfill with remaining distinct products
      if (products.length < 4 && rawProducts.length > products.length) {
        for (final p in rawProducts) {
          if (!products.any((existing) => existing.id == p.id)) {
            products.add(p);
            if (products.length >= 8) break;
          }
        }
      }

      final keywordsList = data['keywords'];
      final seenKeywords = <String>{};
      final List<String> keywords = [];
      if (keywordsList is List) {
        for (final k in keywordsList) {
          final raw = k.toString().trim();
          if (raw.isEmpty) continue;
          final cleaned = raw
              .replaceAll(
                RegExp(r'\s*[-–—]\s*Edition\s*\d+', caseSensitive: false),
                '',
              )
              .trim();
          final candidate = cleaned.isNotEmpty ? cleaned : raw;
          if (seenKeywords.add(candidate.toLowerCase())) {
            keywords.add(candidate);
          }
        }
      }

      final categoriesList = data['categories'];
      final seenCategorySlugs = <String>{};
      final List<SuggestionCategory> categories = [];
      if (categoriesList is List) {
        for (final c in categoriesList) {
          if (c is Map) {
            final cat = SuggestionCategory.fromJson(
              Map<String, dynamic>.from(c),
            );
            if (seenCategorySlugs.add(cat.slug.toLowerCase())) {
              categories.add(cat);
            }
          }
        }
      }

      return ProductSuggestionsResult(
        products: products,
        keywords: keywords,
        categories: categories,
      );
    }
    return const ProductSuggestionsResult();
  }

  /// Fetches related product suggestions for a specific product by slug.
  Future<List<Product>> fetchRelatedProducts(
    String slug, {
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.productRelated(slug),
      queryParameters: {'limit': limit},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      final baseUrl = _apiClient.dio.options.baseUrl;
      return (data['data'] as List)
          .map((item) => _parseProduct(item, baseUrl))
          .toList();
    }
    return <Product>[];
  }

  /// Fetches a single product by slug from GET /api/products/{slug}.
  Future<Product?> fetchProductDetail(String slug) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.productDetail(slug));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final rawItem = data['data'] ?? data['product'] ?? data;
        if (rawItem is Map) {
          final baseUrl = _apiClient.dio.options.baseUrl;
          return _parseProduct(rawItem, baseUrl);
        }
      }
    } catch (_) {
      // Fallback or network error
    }
    return null;
  }

  /// Fetches approved customer reviews for a product by slug.
  Future<ProductReviewsResult> fetchProductReviews(String slug) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.productReviews(slug));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ProductReviewsResult.fromJson(data);
      }
    } catch (_) {}
    return const ProductReviewsResult();
  }

  /// Submits a customer review for a product by slug. Requires authentication.
  Future<bool> submitProductReview(
    String slug, {
    required int rating,
    String? review,
  }) async {
    final payload = <String, dynamic>{
      'rating': rating,
      if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
    };
    final response = await _apiClient.post(
      ApiEndpoints.productReviews(slug),
      data: payload,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['status'] == true;
    }
    return false;
  }

  Product _parseProduct(dynamic item, String baseUrl) {
    final json = Map<String, dynamic>.from(item as Map);
    try {
      json['id'] = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
      json['slug'] ??= '';
      json['name'] ??= 'Unnamed Product';
      json['short_description'] ??= '';

      // Price — use primary variant price as fallback
      json['price'] = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;

      // Thumbnail URL normalization
      json['thumbnail'] = formatImageUrl(
        json['thumbnail']?.toString(),
        baseUrl,
        slug: json['slug']?.toString(),
        category: json['category']?.toString(),
        title: json['name']?.toString(),
      );

      json['category'] ??= 'Uncategorized';
      if (json['rating'] != null) {
        json['rating'] = double.tryParse(json['rating'].toString());
      }

      // Parse variants into raw maps — Product.fromJson will deserialize them
      if (json['variants'] is List) {
        json['variants'] = (json['variants'] as List).map((item) {
          final v = Map<String, dynamic>.from(item as Map);
          v['price'] = double.tryParse(v['price']?.toString() ?? '0') ?? 0.0;
          if (v['discount_price'] != null) {
            v['discount_price'] =
                double.tryParse(v['discount_price'].toString());
          }
          v['stock'] = int.tryParse(v['stock']?.toString() ?? '0') ?? 0;
          v['is_primary'] = v['is_primary'] == true || v['is_primary'] == 1;
          v['name'] ??= '';
          // Deep-normalize each attribute map
          if (v['attributes'] is List) {
            v['attributes'] = (v['attributes'] as List).map((a) {
              final attr = Map<String, dynamic>.from(a as Map);
              attr['id'] = int.tryParse(attr['id']?.toString() ?? '0') ?? 0;
              attr['name'] ??= '';
              attr['value'] ??= '';
              return attr;
            }).toList();
          } else {
            v['attributes'] = <Map<String, dynamic>>[];
          }
          return v;
        }).toList();
      } else {
        json['variants'] = <Map<String, dynamic>>[];
      }

      // If variants are empty but item has price/discount_price (such as suggestion card items),
      // synthesize a primary variant so card widgets and detail screens operate smoothly
      if ((json['variants'] as List).isEmpty) {
        final double fallbackPrice = json['price'] as double;
        final double? discountPrice = json['discount_price'] != null
            ? double.tryParse(json['discount_price'].toString())
            : null;

        json['variants'] = [
          {
            'id': json['id'] ?? 0,
            'product_id': json['id'] ?? 0,
            'price': fallbackPrice,
            'discount_price': discountPrice,
            'stock': 99,
            'is_primary': true,
            'name': 'Standard',
            'attributes': <Map<String, dynamic>>[],
          }
        ];
      }

      // Derive display selling price from primary variant or discount price
      final variantsList = (json['variants'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];
      if (variantsList.isNotEmpty) {
        Map<String, dynamic>? primary;
        for (final v in variantsList) {
          if (v['is_primary'] == true) {
            primary = v;
            break;
          }
        }
        primary ??= variantsList.first;
        final effectiveVariantPrice = (primary['discount_price'] as double?) ??
            (primary['price'] as double? ?? 0.0);
        if (effectiveVariantPrice > 0) {
          json['price'] = effectiveVariantPrice;
        }
      } else if (json['discount_price'] != null) {
        final dPrice = double.tryParse(json['discount_price'].toString());
        if (dPrice != null && dPrice > 0) {
          json['price'] = dPrice;
        }
      }

      return Product.fromJson(json);
    } catch (e, stackTrace) {
      debugPrint('--- PRODUCT PARSING ERROR ---');
      debugPrint('JSON: $json');
      debugPrint('Error: $e\n$stackTrace');
      rethrow;
    }
  }
}
