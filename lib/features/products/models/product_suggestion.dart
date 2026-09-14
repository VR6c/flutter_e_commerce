import '../models/product.dart';

/// Lightweight category pill returned alongside live search suggestions.
class SuggestionCategory {
  final int id;
  final String name;
  final String slug;

  const SuggestionCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory SuggestionCategory.fromJson(Map<String, dynamic> json) {
    return SuggestionCategory(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };
}

/// Comprehensive suggestion response object containing matching products,
/// query completion keywords, and quick category pills.
class ProductSuggestionsResult {
  final List<Product> products;
  final List<String> keywords;
  final List<SuggestionCategory> categories;

  const ProductSuggestionsResult({
    this.products = const [],
    this.keywords = const [],
    this.categories = const [],
  });

  bool get isEmpty =>
      products.isEmpty && keywords.isEmpty && categories.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
