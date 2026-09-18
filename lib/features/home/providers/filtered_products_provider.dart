import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/sort_option.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/providers/category_products_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';

final _alphanumericRegex = RegExp(r'[^a-z0-9]');

/// Immutable criteria for home product filtering and sorting.
@immutable
class HomeFilterCriteria {
  final String searchQuery;
  final String? selectedCategorySlug;
  final RangeValues? priceRange;
  final double? minRating;
  final SortOption sortBy;

  const HomeFilterCriteria({
    this.searchQuery = '',
    this.selectedCategorySlug,
    this.priceRange,
    this.minRating,
    this.sortBy = SortOption.none,
  });

  HomeFilterCriteria copyWith({
    String? searchQuery,
    String? Function()? selectedCategorySlug,
    RangeValues? Function()? priceRange,
    double? Function()? minRating,
    SortOption? sortBy,
  }) {
    return HomeFilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategorySlug: selectedCategorySlug != null
          ? selectedCategorySlug()
          : this.selectedCategorySlug,
      priceRange: priceRange != null ? priceRange() : this.priceRange,
      minRating: minRating != null ? minRating() : this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  int get activeFiltersCount =>
      (sortBy != SortOption.none ? 1 : 0) +
      (selectedCategorySlug != null ? 1 : 0) +
      (priceRange != null ? 1 : 0) +
      ((minRating != null && minRating! > 0) ? 1 : 0);

  bool get isFilterActive => activeFiltersCount > 0 || searchQuery.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeFilterCriteria &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          selectedCategorySlug == other.selectedCategorySlug &&
          priceRange == other.priceRange &&
          minRating == other.minRating &&
          sortBy == other.sortBy;

  @override
  int get hashCode => Object.hash(
        searchQuery,
        selectedCategorySlug,
        priceRange,
        minRating,
        sortBy,
      );
}

/// StateNotifier to manage filter criteria.
class HomeFilterCriteriaNotifier extends StateNotifier<HomeFilterCriteria> {
  HomeFilterCriteriaNotifier() : super(const HomeFilterCriteria());

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedCategorySlug(String? slug) {
    if (state.selectedCategorySlug == slug) return;
    state = state.copyWith(selectedCategorySlug: () => slug);
  }

  void setSortBy(SortOption sort) {
    if (state.sortBy == sort) return;
    state = state.copyWith(sortBy: sort);
  }

  void setPriceRange(RangeValues? range) {
    if (state.priceRange == range) return;
    state = state.copyWith(priceRange: () => range);
  }

  void setMinRating(double? rating) {
    if (state.minRating == rating) return;
    state = state.copyWith(minRating: () => rating);
  }

  void updateAll({
    required SortOption sortBy,
    required String? categorySlug,
    required RangeValues? priceRange,
    required double? minRating,
  }) {
    state = HomeFilterCriteria(
      searchQuery: state.searchQuery,
      sortBy: sortBy,
      selectedCategorySlug: categorySlug,
      priceRange: priceRange,
      minRating: minRating,
    );
  }

  void clearAllFilters() {
    state = const HomeFilterCriteria();
  }
}

final homeFilterCriteriaProvider =
    StateNotifierProvider<HomeFilterCriteriaNotifier, HomeFilterCriteria>(
  (ref) => HomeFilterCriteriaNotifier(),
);

/// Memoized provider that derives filtered & sorted home products.
/// Decouples complex string sanitization, category tree checking, and sorting
/// completely from the UI build loop.
final homeFilteredProductsProvider = Provider<List<Product>>((ref) {
  final criteria = ref.watch(homeFilterCriteriaProvider);
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
  final selectedCat = CategoryProductsNotifier.findCategory(
    criteria.selectedCategorySlug,
    categories,
  );

  final List<Product> baseProducts;
  final bool filterCategory;

  if (selectedCat != null) {
    final catState = ref.watch(categoryProductsProvider);
    baseProducts = catState.productsFor(selectedCat.id);
    filterCategory = false;
  } else {
    baseProducts = products;
    filterCategory = true;
  }

  return applyProductFilters(
    products: baseProducts,
    criteria: criteria,
    categories: categories,
    filterCategory: filterCategory,
  );
});

/// Indicates whether category-specific products are currently loading for the selected category.
final homeCategoryLoadingProvider = Provider<bool>((ref) {
  final criteria = ref.watch(homeFilterCriteriaProvider);
  final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
  final selectedCat = CategoryProductsNotifier.findCategory(
    criteria.selectedCategorySlug,
    categories,
  );
  if (selectedCat == null) return false;
  final catState = ref.watch(categoryProductsProvider);
  return catState.isLoading(selectedCat.id) && catState.productsFor(selectedCat.id).isEmpty;
});

/// Pure function to filter and sort products efficiently outside the UI build loop.
List<Product> applyProductFilters({
  required List<Product> products,
  required HomeFilterCriteria criteria,
  required List<dynamic> categories,
  bool filterCategory = true,
}) {
  if (products.isEmpty) return const [];

  final selClean = criteria.selectedCategorySlug?.toLowerCase().replaceAll(_alphanumericRegex, '');
  final hasCategory = filterCategory && selClean != null && selClean.isNotEmpty;
  final minRating = criteria.minRating;
  final hasRating = minRating != null && minRating > 0;
  final priceRange = criteria.priceRange;
  final query = criteria.searchQuery.trim().toLowerCase();
  final hasQuery = query.isNotEmpty;

  var filtered = products.where((p) {
    // 1. Category filter
    if (hasCategory) {
      final catClean = p.category.toLowerCase().replaceAll(_alphanumericRegex, '');
      bool matches = catClean == selClean ||
          catClean.contains(selClean) ||
          selClean.contains(catClean);

      if (!matches) {
        for (final cat in categories) {
          final catSlugClean =
              cat.slug.toLowerCase().replaceAll(_alphanumericRegex, '');
          if (catSlugClean == selClean) {
            final catNameClean =
                cat.name.toLowerCase().replaceAll(_alphanumericRegex, '');
            if (catClean == catNameClean ||
                catClean.contains(catNameClean) ||
                catNameClean.contains(catClean)) {
              matches = true;
              break;
            }
            for (final child in cat.children) {
              final childSlugClean = child.slug
                  .toLowerCase()
                  .replaceAll(_alphanumericRegex, '');
              final childNameClean = child.name
                  .toLowerCase()
                  .replaceAll(_alphanumericRegex, '');
              if (catClean == childSlugClean ||
                  catClean == childNameClean ||
                  catClean.contains(childSlugClean) ||
                  catClean.contains(childNameClean)) {
                matches = true;
                break;
              }
            }
          }
        }
      }

      if (!matches) return false;
    }

    // 2. Rating filter
    if (hasRating && (p.rating ?? 0) < minRating) {
      return false;
    }

    // 3. Price range filter
    if (priceRange != null) {
      if (p.effectivePrice < priceRange.start ||
          p.effectivePrice > priceRange.end) {
        return false;
      }
    }

    // 4. Text query
    if (hasQuery) {
      final nameLower = p.name.toLowerCase();
      final catLower = p.category.toLowerCase();
      final brandLower = p.brand?.toLowerCase();
      return nameLower.contains(query) ||
          catLower.contains(query) ||
          (brandLower != null && brandLower.contains(query));
    }

    return true;
  }).toList();

  // 5. Sorting
  switch (criteria.sortBy) {
    case SortOption.priceAsc:
      filtered.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
      break;
    case SortOption.priceDesc:
      filtered.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
      break;
    case SortOption.nameAsc:
      filtered.sort((a, b) => a.name.compareTo(b.name));
      break;
    case SortOption.rating:
      filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      break;
    case SortOption.none:
      break;
  }

  return filtered;
}
