import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../models/category.dart';

class CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepository(this._apiClient);

  Future<List<Category>> fetchCategories() async {
    final response = await _apiClient.get(ApiEndpoints.categories);
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      final baseUrl = _apiClient.dio.options.baseUrl;
      final seenSlugs = <String>{};
      final seenImages = <String>{};
      final categories = <Category>[];

      for (final item in (data['data'] as List)) {
        final json = Map<String, dynamic>.from(item as Map);

        // Filter: Display only category that has items
        final prodCount = json['products_count'];
        if (prodCount != null && (prodCount as num) <= 0) {
          continue;
        }

        final slug = (json['slug']?.toString() ?? '').toLowerCase().trim();
        if (slug.isNotEmpty && !seenSlugs.add(slug)) {
          // Skip duplicate category slugs
          continue;
        }

        String formattedImg = formatImageUrl(
          json['image_url']?.toString(),
          baseUrl,
          title: json['name']?.toString(),
          slug: json['slug']?.toString(),
          isCategory: true,
        );

        // Ensure non-duplicate images across categories
        if (formattedImg.isNotEmpty && !seenImages.add(formattedImg)) {
          formattedImg = getFallbackImageUrl(
            slug: '${slug}_alt_${seenImages.length}',
            title: json['name']?.toString(),
            isCategory: true,
          );
          seenImages.add(formattedImg);
        }
        json['image_url'] = formattedImg;

        if (json['children'] is List) {
          final childList = <Map<String, dynamic>>[];
          for (final c in (json['children'] as List)) {
            final childMap = Map<String, dynamic>.from(c as Map);
            final childCount = childMap['products_count'];
            if (childCount != null && (childCount as num) <= 0) {
              continue;
            }

            String childImg = formatImageUrl(
              childMap['image_url']?.toString(),
              baseUrl,
              title: childMap['name']?.toString(),
              slug: childMap['slug']?.toString(),
              isCategory: true,
            );
            if (childImg.isNotEmpty && !seenImages.add(childImg)) {
              childImg = getFallbackImageUrl(
                slug: '${childMap['slug']}_child_${seenImages.length}',
                title: childMap['name']?.toString(),
                isCategory: true,
              );
              seenImages.add(childImg);
            }
            childMap['image_url'] = childImg;
            childList.add(childMap);
          }
          json['children'] = childList;
        }

        categories.add(Category.fromJson(json));
      }

      return categories;
    }
    throw Exception('Invalid categories response structure');
  }
}
