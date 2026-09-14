import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/models/sort_option.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/product_card.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../../../shared/providers/bottom_nav_scroll_provider.dart';
import '../../../core/storage/local_cache_service.dart';

/// All Products screen listing all store items with category filtering, search, and sorting.
class AllProductsScreen extends ConsumerStatefulWidget {
  final String? initialCategorySlug;

  const AllProductsScreen({super.key, this.initialCategorySlug});

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

/// Backwards-compatibility alias for the route definition
typedef CategoryListScreen = AllProductsScreen;

class _AllProductsScreenState extends ConsumerState<AllProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  Timer? _debounceTimer;
  String _searchQuery = '';
  String? _selectedCategorySlug;
  SortOption _sortBy = SortOption.none;

  // Per-category products state fetched on-demand from server
  final Map<int, List<Product>> _categoryProducts = {};
  final Map<int, int> _categoryCurrentPage = {};
  final Map<int, int> _categoryLastPage = {};
  bool _isLoadingCategory = false;
  bool _isLoadingMoreCategory = false;

  // Memoization cache
  List<Product>? _cachedOriginal;
  List<Product> _cachedFiltered = [];
  String _lastQuery = '';
  String? _lastCategory;
  SortOption _lastSort = SortOption.none;

  static final _alphanumericRegex = RegExp(r'[^a-z0-9]');

  Category? _findCategory(String? slug, List<Category> categories) {
    if (slug == null) return null;
    final s = slug.toLowerCase().trim();
    final sClean = s.replaceAll(_alphanumericRegex, '');
    for (final c in categories) {
      final cSlug = c.slug.toLowerCase().trim();
      final cName = c.name.toLowerCase().trim();
      if (cSlug == s ||
          cName == s ||
          cSlug.replaceAll(_alphanumericRegex, '') == sClean ||
          cName.replaceAll(_alphanumericRegex, '') == sClean) {
        return c;
      }
    }
    return null;
  }

  Future<void> _fetchCategoryProducts(
    int categoryId, {
    int page = 1,
    bool isSilent = false,
  }) async {
    if (page == 1) {
      if (!isSilent) {
        setState(() => _isLoadingCategory = true);
      }
    } else {
      if (_isLoadingMoreCategory) return;
      setState(() => _isLoadingMoreCategory = true);
    }

    try {
      final repository = ref.read(productRepositoryProvider);
      final cacheService = ref.read(localCacheServiceProvider);
      final response = await repository.fetchProductsPage(
        page: page,
        perPage: 20,
        categoryId: categoryId,
      );

      if (!mounted) return;
      final current = _categoryProducts[categoryId] ?? [];
      final existingIds = current.map((p) => p.id).toSet();
      final newItems = response.products.where((p) => !existingIds.contains(p.id)).toList();

      setState(() {
        _categoryProducts[categoryId] = page == 1 ? response.products : [...current, ...newItems];
        _categoryCurrentPage[categoryId] = response.currentPage;
        _categoryLastPage[categoryId] = response.lastPage;
        _isLoadingCategory = false;
        _isLoadingMoreCategory = false;
      });

      if (page == 1 && response.products.isNotEmpty) {
        await cacheService.saveCachedCategoryProducts(categoryId, response.products);
      }
    } catch (e) {
      debugPrint('Error fetching products for category $categoryId: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategory = false;
          _isLoadingMoreCategory = false;
        });
      }
    }
  }

  List<Product> _extractLocalMatchesForCategory(
    Category category,
    List<Product> allProducts,
  ) {
    final target = category.slug.toLowerCase().trim();
    final targetName = category.name.toLowerCase().trim();
    final targetClean = target.replaceAll(_alphanumericRegex, '');
    final targetNameClean = targetName.replaceAll(_alphanumericRegex, '');

    final matchingSlugs = <String>{
      target,
      targetName,
      targetClean,
      targetNameClean,
    };

    for (final child in category.children) {
      final cSlug = child.slug.toLowerCase().trim();
      final cName = child.name.toLowerCase().trim();
      matchingSlugs.addAll([
        cSlug,
        cName,
        cSlug.replaceAll(_alphanumericRegex, ''),
        cName.replaceAll(_alphanumericRegex, ''),
      ]);
    }

    return allProducts.where((p) {
      final cat = p.category.toLowerCase().trim();
      final catClean = cat.replaceAll(_alphanumericRegex, '');
      return matchingSlugs.contains(cat) ||
          matchingSlugs.contains(catClean) ||
          matchingSlugs.any(
            (slug) =>
                (slug.length >= 3 &&
                    (cat.contains(slug) || slug.contains(cat))) ||
                (slug.length >= 3 &&
                    (catClean.contains(slug) || slug.contains(catClean))),
          );
    }).toList();
  }

  Future<void> _warmCategoryCache() async {
    final cacheService = ref.read(localCacheServiceProvider);
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    for (final cat in categories) {
      if (!_categoryProducts.containsKey(cat.id)) {
        final cached = await cacheService.getCachedCategoryProducts(cat.id);
        if (cached != null && cached.isNotEmpty && mounted) {
          setState(() {
            _categoryProducts[cat.id] = cached;
          });
        }
      }
    }
  }

  Future<void> _selectCategoryWithCache(Category category) async {
    final isSelected = _selectedCategorySlug == category.slug ||
        _selectedCategorySlug == category.name;
    final newSlug = isSelected ? null : category.slug;

    setState(() {
      _selectedCategorySlug = newSlug;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    if (newSlug == null) {
      if (_categoryScrollController.hasClients) {
        _categoryScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    final categoryId = category.id;
    final cacheService = ref.read(localCacheServiceProvider);

    // 1. In-memory cache hit: 0ms instant display!
    if (_categoryProducts.containsKey(categoryId) &&
        _categoryProducts[categoryId]!.isNotEmpty) {
      _fetchCategoryProducts(categoryId, page: 1, isSilent: true);
      return;
    }

    // 2. Persistent disk cache hit (SharedPreferences): < 10ms instant display!
    final diskCached = await cacheService.getCachedCategoryProducts(categoryId);
    if (diskCached != null && diskCached.isNotEmpty && mounted) {
      setState(() {
        _categoryProducts[categoryId] = diskCached;
        _isLoadingCategory = false;
      });
      _fetchCategoryProducts(categoryId, page: 1, isSilent: true);
      return;
    }

    // 3. Fallback: extract matches from all-products cache
    final allProducts = ref.read(productsProvider).valueOrNull ??
        await cacheService.getCachedProducts() ??
        [];
    final localMatches = _extractLocalMatchesForCategory(category, allProducts);
    if (localMatches.isNotEmpty && mounted) {
      setState(() {
        _categoryProducts[categoryId] = localMatches;
        _isLoadingCategory = false;
      });
      _fetchCategoryProducts(categoryId, page: 1, isSilent: true);
      return;
    }

    // 4. Cold start: fetch page 1 with skeleton shimmer
    _fetchCategoryProducts(categoryId, page: 1, isSilent: false);
  }

  @override
  void initState() {
    super.initState();
    _selectedCategorySlug = widget.initialCategorySlug;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmCategoryCache();
      if (_selectedCategorySlug != null) {
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];
        final cat = _findCategory(_selectedCategorySlug, categories);
        if (cat != null) {
          _selectCategoryWithCache(cat);
        }
        _scrollToSelectedCategory();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AllProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategorySlug != oldWidget.initialCategorySlug &&
        widget.initialCategorySlug != null) {
      setState(() {
        _selectedCategorySlug = widget.initialCategorySlug;
      });
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final cat = _findCategory(_selectedCategorySlug, categories);
      if (cat != null) {
        _selectCategoryWithCache(cat);
      }
      _scrollToSelectedCategory();
    }
  }

  void _scrollToSelectedCategory() {
    if (_selectedCategorySlug == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _categoryKeys[_selectedCategorySlug];
      final targetContext = key?.currentContext;
      if (targetContext != null) {
        final scrollable = Scrollable.maybeOf(targetContext);
        final renderObject = targetContext.findRenderObject();
        if (scrollable != null && renderObject != null) {
          scrollable.position.ensureVisible(
            renderObject,
            alignment: 0.5,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim().toLowerCase();
        });
      }
    });
  }

  List<Product> _getFilteredProducts(
    List<Product> allProducts, {
    bool filterCategory = true,
  }) {
    if (identical(_cachedOriginal, allProducts) &&
        _lastQuery == _searchQuery &&
        _lastCategory == _selectedCategorySlug &&
        _lastSort == _sortBy) {
      return _cachedFiltered;
    }

    _cachedOriginal = allProducts;
    _lastQuery = _searchQuery;
    _lastCategory = _selectedCategorySlug;
    _lastSort = _sortBy;

    var result = List<Product>.from(allProducts);

    // 1. Filter by category slug if selected and requested
    if (filterCategory && _selectedCategorySlug != null) {
      final target = _selectedCategorySlug!.toLowerCase().trim();
      final targetClean = target.replaceAll(_alphanumericRegex, '');
      final matchingSlugs = <String>{target, targetClean};
      final allCategories =
          ref.read(categoriesProvider).valueOrNull ?? <Category>[];

      for (final cat in allCategories) {
        final catSlug = cat.slug.toLowerCase().trim();
        final catName = cat.name.toLowerCase().trim();
        final catSlugClean = catSlug.replaceAll(_alphanumericRegex, '');
        final catNameClean = catName.replaceAll(_alphanumericRegex, '');

        if (catSlug == target ||
            catName == target ||
            catSlugClean == targetClean ||
            catNameClean == targetClean) {
          matchingSlugs.addAll([catSlug, catName, catSlugClean, catNameClean]);
          for (final child in cat.children) {
            final cSlug = child.slug.toLowerCase().trim();
            final cName = child.name.toLowerCase().trim();
            matchingSlugs.addAll([
              cSlug,
              cName,
              cSlug.replaceAll(_alphanumericRegex, ''),
              cName.replaceAll(_alphanumericRegex, ''),
            ]);
          }
          break;
        }
      }

      result = result.where((p) {
        final cat = p.category.toLowerCase().trim();
        final catClean = cat.replaceAll(_alphanumericRegex, '');
        return matchingSlugs.contains(cat) ||
            matchingSlugs.contains(catClean) ||
            matchingSlugs.any(
              (slug) =>
                  (slug.length >= 3 &&
                      (cat.contains(slug) || slug.contains(cat))) ||
                  (slug.length >= 3 &&
                      (catClean.contains(slug) || slug.contains(catClean))),
            );
      }).toList();
    }

    // 2. Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        final name = p.name.toLowerCase();
        final desc = p.shortDescription.toLowerCase();
        final brand = p.brand?.toLowerCase() ?? '';
        return name.contains(_searchQuery) ||
            desc.contains(_searchQuery) ||
            brand.contains(_searchQuery);
      }).toList();
    }

    // 3. Sort
    switch (_sortBy) {
      case SortOption.priceAsc:
        result.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case SortOption.priceDesc:
        result.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case SortOption.nameAsc:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case SortOption.rating:
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case SortOption.none:
        break;
    }

    _cachedFiltered = result;
    return result;
  }

  void _showSortSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D38) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (_sortBy != SortOption.none)
                    GestureDetector(
                      onTap: () {
                        setState(() => _sortBy = SortOption.none);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              ...SortOption.values.map((option) {
                final isSelected = _sortBy == option;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _sortBy = option);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _clearAllFilters() {
    HapticFeedback.selectionClick();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategorySlug = null;
      _sortBy = SortOption.none;
    });
    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BottomNavScrollEvent>(bottomNavScrollProvider, (previous, next) {
      if (next.tabIndex == 1 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });

    ref.listen<AsyncValue<List<Category>>>(categoriesProvider, (prev, next) {
      if (prev?.valueOrNull == null && next.valueOrNull != null) {
        _scrollToSelectedCategory();
      }
    });

    final productsState = ref.watch(productsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasActiveFilter =
        _selectedCategorySlug != null ||
        _searchQuery.isNotEmpty ||
        _sortBy != SortOption.none;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'All Products',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 23,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          // Sort Button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showSortSheet(context),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _sortBy != SortOption.none
                      ? theme.colorScheme.primary
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sortBy != SortOption.none
                        ? Colors.transparent
                        : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _sortBy != SortOption.none
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search all items...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Horizontal Category Filter Selector
          categoriesState.maybeWhen(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Items',
                        isSelected: _selectedCategorySlug == null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategorySlug = null);
                          if (_categoryScrollController.hasClients) {
                            _categoryScrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        theme: theme,
                        isDark: isDark,
                      ),
                      ...categories.map((category) {
                        final isSelected =
                            _selectedCategorySlug == category.slug ||
                            _selectedCategorySlug == category.name;
                        final chipKey = _categoryKeys.putIfAbsent(
                          category.slug,
                          () => GlobalKey(),
                        );
                        _categoryKeys[category.name] = chipKey;

                        return _FilterChip(
                          key: chipKey,
                          label: category.name,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _selectCategoryWithCache(category);
                          },
                          theme: theme,
                          isDark: isDark,
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Active Filter Reset Pill (shown if any filter is active)
          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Filtered results',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Product Grid
          Expanded(
            child: RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: () async {
                final categories = categoriesState.valueOrNull ?? <Category>[];
                final selectedCat = _findCategory(_selectedCategorySlug, categories);
                if (selectedCat != null) {
                  await _fetchCategoryProducts(selectedCat.id, page: 1);
                } else {
                  await Future.wait([
                    ref.read(productsProvider.notifier).refresh(),
                    ref.read(categoriesProvider.notifier).refresh(),
                  ]);
                }
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.extentAfter < 300) {
                    final categories = categoriesState.valueOrNull ?? <Category>[];
                    final selectedCat = _findCategory(_selectedCategorySlug, categories);
                    if (selectedCat != null) {
                      final cur = _categoryCurrentPage[selectedCat.id] ?? 1;
                      final last = _categoryLastPage[selectedCat.id] ?? 1;
                      if (cur < last && !_isLoadingMoreCategory) {
                        _fetchCategoryProducts(selectedCat.id, page: cur + 1);
                      }
                    } else {
                      ref.read(productsProvider.notifier).loadMore();
                    }
                  }
                  return false;
                },
                child: Builder(
                  builder: (context) {
                    final categories = categoriesState.valueOrNull ?? <Category>[];
                    final selectedCat = _findCategory(_selectedCategorySlug, categories);

                    if (selectedCat != null) {
                      final hasCachedItems = _categoryProducts.containsKey(selectedCat.id) &&
                          _categoryProducts[selectedCat.id]!.isNotEmpty;
                      if (_isLoadingCategory && !hasCachedItems) {
                        return const _ProductGridShimmer();
                      }
                      final catItems = _categoryProducts[selectedCat.id] ?? [];
                      final filtered = _getFilteredProducts(catItems, filterCategory: false);
                      return _buildProductGrid(
                        filtered,
                        isLoadingMore: _isLoadingMoreCategory,
                        theme: theme,
                        hasActiveFilter: hasActiveFilter,
                      );
                    }

                    return AsyncValueWidget(
                      value: productsState,
                      loading: const _ProductGridShimmer(),
                      onRetry: () => ref.invalidate(productsProvider),
                      data: (products) {
                        final filtered = _getFilteredProducts(products);
                        final isLoadingMore = ref.watch(isProductsLoadingMoreProvider);
                        return _buildProductGrid(
                          filtered,
                          isLoadingMore: isLoadingMore,
                          theme: theme,
                          hasActiveFilter: hasActiveFilter,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<Product> filtered, {
    required bool isLoadingMore,
    required ThemeData theme,
    required bool hasActiveFilter,
  }) {
    if (filtered.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: _searchQuery.isNotEmpty
                    ? 'No products for "$_searchQuery"'
                    : 'No Products Found',
                message: hasActiveFilter
                    ? 'Try clearing your category or search filter.'
                    : 'Check back later for newly added items.',
              ),
            ),
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = filtered[index];
                return ProductCard(
                  heroTagPrefix: 'all_products',
                  product: product,
                  onTap: () => context.push(
                    AppRoutes.productDetail,
                    extra: {
                      'product': product,
                      'heroTag': 'all_products_product_${product.id}',
                    },
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
        if (isLoadingMore)
          SliverToBoxAdapter(
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
          )
        else
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }
}

/// Horizontal category selector chip with smooth color transition and auto-scroll on tap
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _FilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          final scrollable = Scrollable.maybeOf(context);
          final renderObject = context.findRenderObject();
          if (scrollable != null && renderObject != null) {
            scrollable.position.ensureVisible(
              renderObject,
              alignment: 0.5,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
            );
          }
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0)),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton Shimmer Loader for Products Grid
class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const ProductCardShimmer(),
    );
  }
}
