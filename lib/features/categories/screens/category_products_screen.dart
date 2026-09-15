import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/models/sort_option.dart';
import '../../../shared/widgets/cart_icon_badge.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product.dart';
import '../providers/category_provider.dart';
import '../../../core/storage/local_cache_service.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final List<String> categorySlugs;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.categorySlugs,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  SortOption _sortBy = SortOption.none;

  List<Product>? _cachedOriginal;
  List<Product> _cachedFiltered = [];
  String _lastQuery = '';
  SortOption _lastSort = SortOption.none;

  List<Product> _serverProducts = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int? _resolvedCategoryId;
  static final _alphanumericRegex = RegExp(r'[^a-z0-9]');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAndFetch();
    });
  }

  Future<void> _resolveAndFetch() async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    for (final c in categories) {
      if (c.name.toLowerCase() == widget.categoryName.toLowerCase() ||
          widget.categorySlugs.any((s) => s.toLowerCase() == c.slug.toLowerCase())) {
        _resolvedCategoryId = c.id;
        break;
      }
    }

    if (_resolvedCategoryId != null) {
      final cacheService = ref.read(localCacheServiceProvider);
      final diskCached = await cacheService.getCachedCategoryProducts(_resolvedCategoryId!);
      if (diskCached != null && diskCached.isNotEmpty && mounted) {
        setState(() {
          _serverProducts = diskCached;
          _isLoading = false;
        });
        await _fetchPage(page: 1, isSilent: true);
        return;
      }
    }

    await _fetchPage(page: 1);
  }

  Future<void> _fetchPage({int page = 1, bool isSilent = false}) async {
    if (page == 1) {
      if (!isSilent) {
        setState(() => _isLoading = true);
      }
    } else {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final repository = ref.read(productRepositoryProvider);
      final cacheService = ref.read(localCacheServiceProvider);
      final response = await repository.fetchProductsPage(
        page: page,
        perPage: 20,
        categoryId: _resolvedCategoryId,
      );

      if (!mounted) return;
      final current = _serverProducts;
      final existingIds = current.map((p) => p.id).toSet();
      final newItems = response.products.where((p) => !existingIds.contains(p.id)).toList();

      setState(() {
        _serverProducts = page == 1 ? response.products : [...current, ...newItems];
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (page == 1 && _resolvedCategoryId != null && response.products.isNotEmpty) {
        await cacheService.saveCachedCategoryProducts(_resolvedCategoryId!, response.products);
      }
    } catch (e) {
      debugPrint('Error fetching category products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _searchQuery = v.trim();
        });
      }
    });
  }

  List<Product> _filterByCategory(List<Product> all) {
    if (widget.categorySlugs.isEmpty && widget.categoryName.isEmpty) return all;
    final slugSet = <String>{};
    for (final s in widget.categorySlugs) {
      final sLower = s.toLowerCase().trim();
      slugSet.add(sLower);
      slugSet.add(sLower.replaceAll(_alphanumericRegex, ''));
    }
    final nameLower = widget.categoryName.toLowerCase().trim();
    slugSet.add(nameLower);
    slugSet.add(nameLower.replaceAll(_alphanumericRegex, ''));

    return all.where((p) {
      final c = p.category.toLowerCase().trim();
      final cClean = c.replaceAll(_alphanumericRegex, '');
      return slugSet.contains(c) ||
          slugSet.contains(cClean) ||
          slugSet.any(
            (slug) =>
                (slug.length >= 3 && (c.contains(slug) || slug.contains(c))) ||
                (slug.length >= 3 &&
                    (cClean.contains(slug) || slug.contains(cClean))),
          );
    }).toList();
  }

  List<Product> _getFilteredProducts(
    List<Product> all, {
    bool filterCategory = true,
  }) {
    if (identical(_cachedOriginal, all) &&
        _lastQuery == _searchQuery &&
        _lastSort == _sortBy) {
      return _cachedFiltered;
    }

    _cachedOriginal = all;
    _lastQuery = _searchQuery;
    _lastSort = _sortBy;

    var result =
        filterCategory ? _filterByCategory(all) : List<Product>.from(all);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.brand?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    switch (_sortBy) {
      case SortOption.priceAsc:
        result.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case SortOption.priceDesc:
        result.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case SortOption.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
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

  void _showSortSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.isKhmer ? 'តម្រៀបផលិតផល' : 'Sort Products',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              ...SortOption.values.map((opt) {
                final isSelected = _sortBy == opt;
                return GestureDetector(
                  onTap: () {
                    setSheetState(() {});
                    setState(() => _sortBy = opt);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF9FAFB)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          opt.icon,
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          opt.localizedLabel(context),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            letterSpacing: 0,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filterActive = _sortBy != SortOption.none || _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 6.0, bottom: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          context.l10n.translateCategory(widget.categoryName),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 6.0, bottom: 6.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: const CartIconBadge(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.02,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.isKhmer
                            ? 'ស្វែងរកក្នុង ${context.l10n.translateCategory(widget.categoryName)}...'
                            : 'Search in ${widget.categoryName}...',
                        hintStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? Colors.grey[500]
                              : const Color(0xFF94A3B8),
                          fontSize: 13,
                          letterSpacing: 0,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
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
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: filterActive
                          ? theme.colorScheme.primary
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: filterActive
                            ? Colors.transparent
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: filterActive
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: _isLoading && _serverProducts.isEmpty
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const ProductCardShimmer(),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: () async => _fetchPage(page: 1),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.extentAfter < 300) {
                          if (_currentPage < _lastPage && !_isLoadingMore) {
                            _fetchPage(page: _currentPage + 1);
                          }
                        }
                        return false;
                      },
                      child: Builder(
                        builder: (context) {
                          final isUsingServer = _serverProducts.isNotEmpty;
                          final allItems = isUsingServer
                              ? _serverProducts
                              : _filterByCategory(
                                  ref.watch(productsProvider).valueOrNull ?? [],
                                );
                          final filtered = _getFilteredProducts(
                            allItems,
                            filterCategory: !isUsingServer,
                          );

                          if (filtered.isEmpty) {
                            return LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Center(
                                        child: EmptyStateWidget(
                                          icon: Icons.inventory_2_outlined,
                                          title: _searchQuery.isNotEmpty
                                              ? (context.l10n.isKhmer
                                                  ? 'គ្មានលទ្ធផលសម្រាប់ "$_searchQuery"'
                                                  : 'No results for "$_searchQuery"')
                                              : (context.l10n.isKhmer
                                                  ? 'មិនមានផលិតផលទេ'
                                                  : 'No Products Found'),
                                          message: _searchQuery.isNotEmpty
                                              ? (context.l10n.isKhmer
                                                  ? 'សូមសាកល្បងស្វែងរកពាក្យផ្សេង។'
                                                  : 'Try a different search term.')
                                              : (context.l10n.isKhmer
                                                  ? 'មិនទាន់មានផលិតផលនៅក្នុងប្រភេទនេះនៅឡើយទេ។'
                                                  : 'No products are available in this category yet.'),
                                        ),
                                      ),
                                    ),
                                  ),
                            );
                          }

                          return CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.72,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final product = filtered[index];
                                      return ProductCard(
                                        heroTagPrefix: 'cat_list',
                                        product: product,
                                        onTap: () => context.push(
                                          AppRoutes.productDetail,
                                          extra: {
                                            'product': product,
                                            'heroTag':
                                                'cat_list_product_${product.id}',
                                          },
                                        ),
                                      );
                                    },
                                    childCount: filtered.length,
                                  ),
                                ),
                              ),
                              if (_isLoadingMore)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child:
                                            CircularProgressIndicator.adaptive(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.primary,
                                                  ),
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 100),
                                ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 40),
                              ),
                            ],
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
}
