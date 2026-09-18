import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/sort_option.dart';
import '../../../shared/providers/bottom_nav_scroll_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/banner_carousel.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/product_card.dart';

import '../../categories/providers/category_provider.dart';
import '../../categories/providers/category_products_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/providers/product_suggestions_provider.dart';
import '../../products/widgets/search_suggestion_overlay.dart';
import '../models/banner.dart';
import '../providers/banner_provider.dart';
import '../providers/filtered_products_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_category_selector.dart';
import '../widgets/home_filter_chips_bar.dart';
import '../widgets/home_filter_sheet.dart';
import '../widgets/home_perks_bar.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/suggested_for_you_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      ref.read(categoryProductsProvider.notifier).warmCache(categories);
    });
  }

  void _onSearchFocusChanged() {
    if (mounted) {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus &&
            _searchController.text.trim().isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isNotEmpty && !_showSuggestions) {
      setState(() => _showSuggestions = true);
    } else if (trimmed.isEmpty && _showSuggestions) {
      setState(() => _showSuggestions = false);
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(homeFilterCriteriaProvider.notifier).setSearchQuery(trimmed);
      }
    });
  }

  void _onCategorySelected(String? slug) {
    ref.read(homeFilterCriteriaProvider.notifier).setSelectedCategorySlug(slug);
    if (slug == null) return;

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final cat = CategoryProductsNotifier.findCategory(slug, categories);
    if (cat == null) return;

    ref.read(categoryProductsProvider.notifier).selectCategory(cat);
  }

  Future<void> _showFilterSheet() async {
    HapticFeedback.selectionClick();
    final criteria = ref.read(homeFilterCriteriaProvider);
    final products = ref.read(productsProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull;

    final result = await HomeFilterSheet.show(
      context: context,
      initialState: HomeFilterState(
        sortBy: criteria.sortBy,
        categorySlug: criteria.selectedCategorySlug,
        priceRange: criteria.priceRange,
        minRating: criteria.minRating,
      ),
      allProducts: products,
      initialCategories: categories,
    );

    if (result != null && mounted) {
      ref.read(homeFilterCriteriaProvider.notifier).updateAll(
            sortBy: result.sortBy,
            categorySlug: result.categorySlug,
            priceRange: result.priceRange,
            minRating: result.minRating,
          );
      if (result.categorySlug != criteria.selectedCategorySlug) {
        _onCategorySelected(result.categorySlug);
      }
    }
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() => _showSuggestions = false);
    ref.read(homeFilterCriteriaProvider.notifier).clearAllFilters();
  }

  void _handleBannerTap(BannerModel banner) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final text = '${banner.title} ${banner.description ?? ''} ${banner.type ?? ''}'.toLowerCase();

    for (final cat in categories) {
      if (text.contains(cat.name.toLowerCase()) || text.contains(cat.slug.toLowerCase())) {
        context.push(
          AppRoutes.categoryProducts,
          extra: {
            'categoryName': cat.name,
            'categorySlugs': [cat.slug],
          },
        );
        return;
      }
    }

    context.go(AppRoutes.categories);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BottomNavScrollEvent>(bottomNavScrollProvider, (previous, next) {
      if (next.tabIndex == 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final criteria = ref.watch(homeFilterCriteriaProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final selectedCat = CategoryProductsNotifier.findCategory(criteria.selectedCategorySlug, categories);

    return Scaffold(
      appBar: const HomeAppBar(),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          if (selectedCat != null) {
            await ref.read(categoryProductsProvider.notifier).fetchCategoryProducts(selectedCat.id, page: 1);
          }
          await Future.wait([
            ref.read(bannersProvider.notifier).refresh(),
            ref.read(productsProvider.notifier).refresh(),
            ref.read(categoriesProvider.notifier).refresh(),
            ref.read(suggestedForYouProvider.notifier).refresh(),
          ]);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.extentAfter < 300) {
              if (selectedCat != null) {
                ref.read(categoryProductsProvider.notifier).loadMore(selectedCat.id);
              } else {
                ref.read(productsProvider.notifier).loadMore();
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search & Filter Bar
              SliverToBoxAdapter(
                child: HomeSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() => _showSuggestions = false);
                    _searchFocusNode.unfocus();
                  },
                  onFilterTap: _showFilterSheet,
                  activeFiltersCount: criteria.activeFiltersCount,
                  isFilterActive: criteria.isFilterActive,
                ),
              ),

              // Live Autocomplete Suggestions Overlay
              if (_showSuggestions && _searchController.text.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: SearchSuggestionOverlay(
                    query: criteria.searchQuery.isNotEmpty
                        ? criteria.searchQuery
                        : _searchController.text.trim(),
                    onKeywordSelected: (keyword) {
                      _searchController.text = keyword;
                      _onSearchChanged(keyword);
                      setState(() => _showSuggestions = false);
                      _searchFocusNode.unfocus();
                    },
                    onCategorySelected: (catSlug) {
                      _onCategorySelected(catSlug);
                      setState(() => _showSuggestions = false);
                      _searchFocusNode.unfocus();
                    },
                    onProductSelected: (product) {
                      setState(() => _showSuggestions = false);
                      _searchFocusNode.unfocus();
                      context.push(AppRoutes.productDetail, extra: product);
                    },
                    onClose: () {
                      setState(() => _showSuggestions = false);
                      _searchFocusNode.unfocus();
                    },
                  ),
                ),

              // Active filter chips bar
              if (criteria.activeFiltersCount > 0)
                SliverToBoxAdapter(
                  child: HomeFilterChipsBar(
                    sortBy: criteria.sortBy,
                    selectedCategoryName: selectedCat?.name ?? criteria.selectedCategorySlug,
                    priceRange: criteria.priceRange,
                    minRating: criteria.minRating,
                    onClearSort: () => ref.read(homeFilterCriteriaProvider.notifier).setSortBy(SortOption.none),
                    onClearCategory: () => _onCategorySelected(null),
                    onClearPriceRange: () => ref.read(homeFilterCriteriaProvider.notifier).setPriceRange(null),
                    onClearMinRating: () => ref.read(homeFilterCriteriaProvider.notifier).setMinRating(null),
                    onClearAll: _clearAllFilters,
                  ),
                ),

              // Banner Carousel
              if (criteria.searchQuery.isEmpty && criteria.selectedCategorySlug == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: RepaintBoundary(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final bannersState = ref.watch(bannersProvider);
                          return AsyncValueWidget(
                            value: bannersState,
                            loading: const BannerCarouselShimmer(),
                            onRetry: () => ref.invalidate(bannersProvider),
                            data: (banners) => banners.isEmpty
                                ? const SizedBox.shrink()
                                : BannerCarousel(
                                    banners: banners,
                                    onBannerTap: _handleBannerTap,
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Store Highlights Perks Strip
              if (criteria.searchQuery.isEmpty && criteria.selectedCategorySlug == null)
                const SliverToBoxAdapter(child: HomePerksBar()),

              // Horizontal Category Story Badges
              if (criteria.searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: HomeCategorySelector(
                    selectedCategorySlug: criteria.selectedCategorySlug,
                    onCategorySelected: _onCategorySelected,
                  ),
                ),

              // Personalized Recommendations: Suggested For You Carousel
              if (criteria.searchQuery.isEmpty && criteria.selectedCategorySlug == null)
                const SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: SuggestedForYouSection(),
                  ),
                ),

              // Section Title & Sorting Indicator
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            criteria.searchQuery.isNotEmpty
                                ? l10n.searchResults
                                : (criteria.selectedCategorySlug != null
                                    ? l10n.categoryItems
                                    : l10n.ourBestItems),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: l10n.isKhmer ? 0 : -0.2,
                            ),
                          ),
                          if (criteria.searchQuery.isNotEmpty)
                            Text(
                              l10n.showingMatchesFor(criteria.searchQuery),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      if (criteria.sortBy != SortOption.none)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 13,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                criteria.sortBy.label,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: theme.colorScheme.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Grid
              Consumer(
                builder: (context, ref, _) {
                  final productsState = ref.watch(productsProvider);
                  return productsState.when(
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const ProductCardShimmer(),
                          childCount: 4,
                        ),
                      ),
                    ),
                    error: (err, _) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.unableToLoadProducts,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => ref.invalidate(productsProvider),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    data: (_) {
                      final isCategoryLoading = ref.watch(homeCategoryLoadingProvider);
                      if (isCategoryLoading) {
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const ProductCardShimmer(),
                              childCount: 4,
                            ),
                          ),
                        );
                      }

                      final filtered = ref.watch(homeFilteredProductsProvider);

                      if (filtered.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Column(
                              children: [
                                EmptyStateWidget(
                                  icon: Icons.search_off_rounded,
                                  title: criteria.searchQuery.isEmpty
                                      ? (selectedCat != null
                                          ? l10n.noProductsInCategory(l10n.translateCategory(selectedCat.name))
                                          : l10n.noProductsAvailable)
                                      : l10n.noResultsForQuery(criteria.searchQuery),
                                  message: criteria.searchQuery.isEmpty
                                      ? l10n.checkBackLaterStock
                                      : l10n.tryAdjustingSearch,
                                ),
                                if (criteria.isFilterActive) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _clearAllFilters,
                                    icon: const Icon(Icons.clear_all_rounded),
                                    label: Text(l10n.clearAllFilters),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.colorScheme.primary,
                                      side: BorderSide(color: theme.colorScheme.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.68,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = filtered[index];
                              return ProductCard(
                                key: ValueKey('home_prod_${product.id}'),
                                heroTagPrefix: 'home',
                                product: product,
                                onTap: () => context.push(
                                  AppRoutes.productDetail,
                                  extra: {
                                    'product': product,
                                    'heroTag': 'home_product_${product.id}',
                                  },
                                ),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Loading more indicator
              Consumer(
                builder: (context, ref, _) {
                  final catState = ref.watch(categoryProductsProvider);
                  final isCategoryLoadingMore = selectedCat != null &&
                      catState.isLoadingMore(selectedCat.id);
                  final isLoadingMore = isCategoryLoadingMore ||
                      ref.watch(isProductsLoadingMoreProvider);

                  if (!isLoadingMore) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Bottom padding for floating navigation bar
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}
