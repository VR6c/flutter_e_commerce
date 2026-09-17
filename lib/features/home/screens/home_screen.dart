import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/sort_option.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/banner_carousel.dart';
import '../../../shared/widgets/cart_icon_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/user_avatar.dart';

import '../../auth/providers/auth_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/providers/category_products_provider.dart';
import '../../../core/router/app_routes.dart';
import '../models/banner.dart';
import '../providers/banner_provider.dart';
import '../providers/delivery_location_provider.dart';
import '../widgets/location_selection_sheet.dart';
import '../widgets/home_filter_sheet.dart';
import '../widgets/suggested_for_you_section.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../../products/providers/product_suggestions_provider.dart';
import '../../products/widgets/search_suggestion_overlay.dart';
import '../../../shared/providers/bottom_nav_scroll_provider.dart';

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
  String _searchQuery = '';
  bool _showSuggestions = false;
  SortOption _sortBy = SortOption.none;
  String? _selectedCategorySlug;
  RangeValues? _priceRange;
  double? _minRating;

  // Cache filtered results to avoid expensive re-calculation on every build
  List<Product>? _cachedOriginalProducts;
  List<Product> _cachedFilteredProducts = [];
  String _lastFilterQuery = '';
  SortOption _lastSortOption = SortOption.none;
  String? _lastCategorySlug;
  RangeValues? _lastPriceRange;
  double? _lastMinRating;

  static final _alphanumericRegex = RegExp(r'[^a-z0-9]');

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
      setState(() {
        _showSuggestions = true;
      });
    } else if (trimmed.isEmpty && _showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
    }
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = trimmed;
        });
      }
    });
  }

  void _onCategorySelected(String? slug) {
    setState(() {
      _selectedCategorySlug = slug;
    });
    if (slug == null) return;

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final cat = CategoryProductsNotifier.findCategory(slug, categories);
    if (cat == null) return;

    ref.read(categoryProductsProvider.notifier).selectCategory(cat);
  }

  List<Product> _getFilteredProducts(
    List<Product> products, {
    bool filterCategory = true,
  }) {
    if (identical(_cachedOriginalProducts, products) &&
        _lastFilterQuery == _searchQuery &&
        _lastSortOption == _sortBy &&
        _lastCategorySlug == _selectedCategorySlug &&
        _lastPriceRange == _priceRange &&
        _lastMinRating == _minRating) {
      return _cachedFilteredProducts;
    }

    _cachedOriginalProducts = products;
    _lastFilterQuery = _searchQuery;
    _lastSortOption = _sortBy;
    _lastCategorySlug = _selectedCategorySlug;
    _lastPriceRange = _priceRange;
    _lastMinRating = _minRating;

    var filtered = products.where((p) {
      // Category filter
      if (filterCategory &&
          _selectedCategorySlug != null &&
          _selectedCategorySlug!.isNotEmpty) {
        final catClean =
            p.category.toLowerCase().replaceAll(_alphanumericRegex, '');
        final selClean = _selectedCategorySlug!
            .toLowerCase()
            .replaceAll(_alphanumericRegex, '');
        bool matches = catClean == selClean ||
            catClean.contains(selClean) ||
            selClean.contains(catClean);

        if (!matches) {
          final categories = ref.read(categoriesProvider).valueOrNull ?? [];
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

        if (!matches) {
          return false;
        }
      }

      // Rating filter
      if (_minRating != null && _minRating! > 0) {
        if ((p.rating ?? 0) < _minRating!) {
          return false;
        }
      }

      // Price range filter
      if (_priceRange != null) {
        if (p.effectivePrice < _priceRange!.start ||
            p.effectivePrice > _priceRange!.end) {
          return false;
        }
      }

      // Text search query
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          (p.brand?.toLowerCase().contains(q) ?? false);
    }).toList();

    switch (_sortBy) {
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

    _cachedFilteredProducts = filtered;
    return filtered;
  }

  Future<void> _showFilterSheet() async {
    HapticFeedback.selectionClick();
    final productsState = ref.read(productsProvider);
    final products = productsState.valueOrNull ?? [];
    final categoriesState = ref.read(categoriesProvider);
    final categories = categoriesState.valueOrNull;

    final result = await HomeFilterSheet.show(
      context: context,
      initialState: HomeFilterState(
        sortBy: _sortBy,
        categorySlug: _selectedCategorySlug,
        priceRange: _priceRange,
        minRating: _minRating,
      ),
      allProducts: products,
      initialCategories: categories,
    );

    if (result != null && mounted) {
      final newCat = result.categorySlug;
      setState(() {
        _sortBy = result.sortBy;
        _priceRange = result.priceRange;
        _minRating = result.minRating;
      });
      _onCategorySelected(newCat);
    }
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _sortBy = SortOption.none;
      _selectedCategorySlug = null;
      _priceRange = null;
      _minRating = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _handleBannerTap(BannerModel banner) {
    // 1. Check if the banner matches any loaded category
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final text =
        '${banner.title} ${banner.description ?? ''} ${banner.type ?? ''}'
            .toLowerCase();

    for (final cat in categories) {
      if (text.contains(cat.name.toLowerCase()) ||
          text.contains(cat.slug.toLowerCase())) {
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

    // 2. Otherwise navigate to /categories (Explore / All Products)
    context.go(AppRoutes.categories);
  }

  Widget _buildActiveFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
    required ThemeData theme,
    required bool isDark,
  }) {
    final primary = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onRemove();
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 12,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
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

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final activeFiltersCount = (_sortBy != SortOption.none ? 1 : 0) +
        (_selectedCategorySlug != null ? 1 : 0) +
        (_priceRange != null ? 1 : 0) +
        ((_minRating != null && _minRating! > 0) ? 1 : 0);
    final filterActive = activeFiltersCount > 0 || _searchQuery.isNotEmpty;

    final customer = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 66,
        title: Row(
          children: [
            UserAvatar(
              radius: 19,
              name: customer?.name,
              showBorder: true,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.profile);
              },
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customer != null
                        ? (l10n.isKhmer
                            ? 'សួស្តី, ${customer.name.split(' ').first} 👋'
                            : 'Hi, ${customer.name.split(' ').first} 👋')
                        : (l10n.isKhmer
                            ? 'សូមស្វាគមន៍មកកាន់ TVR 👋'
                            : 'Welcome to TVR 👋'),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      LocationSelectionSheet.show(context);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final locState =
                                  ref.watch(deliveryLocationProvider);
                              final selected = locState.selectedLocation;

                              final String displayText;
                              if (selected != null) {
                                final streetPart =
                                    selected.street.split(',').first.trim();
                                String labelText = selected.label;
                                if (l10n.isKhmer) {
                                  final lower = labelText.toLowerCase().trim();
                                  if (lower == 'home') labelText = 'ផ្ទះ';
                                  if (lower == 'work') labelText = 'កន្លែងធ្វើការ';
                                  if (lower == 'office') labelText = 'ការិយាល័យ';
                                }
                                displayText = streetPart.isNotEmpty
                                    ? '$labelText · $streetPart'
                                    : labelText;
                              } else if (customer != null) {
                                displayText = l10n.isKhmer
                                    ? 'ផ្ទះ · ${customer.name}'
                                    : 'Home · ${customer.name}';
                              } else {
                                displayText = l10n.selectLocation;
                              }

                              return Text(
                                displayText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wishlist Shortcut Button
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.favorite_border_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: 'Wishlist',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.wishlist);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Cart Button with Badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const CartIconBadge(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          if (_selectedCategorySlug != null) {
            final categories = ref.read(categoriesProvider).valueOrNull ?? [];
            final cat =
                CategoryProductsNotifier.findCategory(_selectedCategorySlug, categories);
            if (cat != null) {
              await ref
                  .read(categoryProductsProvider.notifier)
                  .fetchCategoryProducts(cat.id, page: 1);
            }
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
              if (_selectedCategorySlug != null) {
                final categories =
                    ref.read(categoriesProvider).valueOrNull ?? [];
                final cat =
                    CategoryProductsNotifier.findCategory(_selectedCategorySlug, categories);
                if (cat != null) {
                  ref.read(categoryProductsProvider.notifier).loadMore(cat.id);
                }
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
              // Modern Search & Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            onSubmitted: (val) {
                              setState(() => _showSuggestions = false);
                              _searchFocusNode.unfocus();
                            },
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.searchPlaceholder,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : const Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.primary,
                                size: 21,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.cancel_rounded,
                                        size: 18,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _searchController.clear();
                                        _onSearchChanged('');
                                        setState(() => _showSuggestions = false);
                                        _searchFocusNode.unfocus();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter Button with Badge
                      InkWell(
                        onTap: _showFilterSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: filterActive
                                    ? theme.colorScheme.primary
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: filterActive
                                      ? Colors.transparent
                                      : (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE2E8F0)),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: filterActive
                                        ? theme.colorScheme.primary.withValues(
                                            alpha: 0.35,
                                          )
                                        : Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.03,
                                          ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: filterActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (activeFiltersCount > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 19,
                                    minHeight: 19,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$activeFiltersCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Live Autocomplete / Typeahead Suggestions
              if (_showSuggestions && _searchController.text.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: SearchSuggestionOverlay(
                    query: _searchQuery.isNotEmpty
                        ? _searchQuery
                        : _searchController.text.trim(),
                    onKeywordSelected: (keyword) {
                      _searchController.text = keyword;
                      _onSearchChanged(keyword);
                      setState(() => _showSuggestions = false);
                      _searchFocusNode.unfocus();
                    },
                    onCategorySelected: (catSlug) {
                      setState(() {
                        _selectedCategorySlug = catSlug;
                        _showSuggestions = false;
                      });
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
              if (activeFiltersCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_sortBy != SortOption.none)
                            _buildActiveFilterChip(
                              icon: Icons.swap_vert_rounded,
                              label: _sortBy.label,
                              onRemove: () =>
                                  setState(() => _sortBy = SortOption.none),
                              theme: theme,
                              isDark: isDark,
                            ),
                          if (_selectedCategorySlug != null)
                            _buildActiveFilterChip(
                              icon: Icons.category_rounded,
                              label: () {
                                final categories = ref
                                        .read(categoriesProvider)
                                        .valueOrNull ??
                                    [];
                                final match = categories
                                    .where((c) => c.slug == _selectedCategorySlug)
                                    .firstOrNull;
                                return match?.name ?? _selectedCategorySlug!;
                              }(),
                              onRemove: () =>
                                  _onCategorySelected(null),
                              theme: theme,
                              isDark: isDark,
                            ),
                          if (_priceRange != null)
                            _buildActiveFilterChip(
                              icon: Icons.attach_money_rounded,
                              label:
                                  '\$${_priceRange!.start.round()} – \$${_priceRange!.end.round()}',
                              onRemove: () =>
                                  setState(() => _priceRange = null),
                              theme: theme,
                              isDark: isDark,
                            ),
                          if (_minRating != null && _minRating! > 0)
                            _buildActiveFilterChip(
                              icon: Icons.star_rounded,
                              label: '$_minRating★ & up',
                              onRemove: () =>
                                  setState(() => _minRating = null),
                              theme: theme,
                              isDark: isDark,
                            ),
                          GestureDetector(
                            onTap: _clearAllFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.isKhmer ? 'សម្អាតទាំងអស់' : 'Clear All',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Banner Carousel
              if (_searchQuery.isEmpty && _selectedCategorySlug == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
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

              // Trust / Store Highlights Perks Strip
              if (_searchQuery.isEmpty && _selectedCategorySlug == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131D38)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFDCFCE7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPerkItem(
                            icon: Icons.bolt_rounded,
                            label: l10n.fastDelivery,
                            iconColor: const Color(0xFFF59E0B),
                            theme: theme,
                            isDark: isDark,
                          ),
                          Container(
                            height: 14,
                            width: 1,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFCBD5E1),
                          ),
                          _buildPerkItem(
                            icon: Icons.eco_rounded,
                            label: l10n.organic100,
                            iconColor: theme.colorScheme.primary,
                            theme: theme,
                            isDark: isDark,
                          ),
                          Container(
                            height: 14,
                            width: 1,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFCBD5E1),
                          ),
                          _buildPerkItem(
                            icon: Icons.verified_user_rounded,
                            label: l10n.bestPrices,
                            iconColor: const Color(0xFF10B981),
                            theme: theme,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Horizontal Category Story Badges
              if (_searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.categories,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: l10n.isKhmer ? 0 : -0.2,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/categories');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.seeAll,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 98,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final categoriesState = ref.watch(categoriesProvider);
                        return AsyncValueWidget(
                          value: categoriesState,
                          loading: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          onRetry: () => ref.invalidate(categoriesProvider),
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: categories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final isAllSelected =
                                      _selectedCategorySlug == null;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 14.0),
                                    child: Builder(
                                      builder: (itemContext) => GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          final scrollable = Scrollable.maybeOf(itemContext);
                                          final renderObject = itemContext.findRenderObject();
                                          if (scrollable != null && renderObject != null) {
                                            scrollable.position.ensureVisible(
                                              renderObject,
                                              alignment: 0.5,
                                              duration: const Duration(milliseconds: 350),
                                              curve: Curves.easeInOutCubic,
                                            );
                                          }
                                          _onCategorySelected(null);
                                        },
                                        child: SizedBox(
                                          width: 68,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  gradient: isAllSelected
                                                      ? LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end:
                                                              Alignment.bottomRight,
                                                          colors: [
                                                            theme.colorScheme
                                                                .primary,
                                                            const Color(0xFF10B981),
                                                          ],
                                                        )
                                                      : null,
                                                  color: isAllSelected
                                                      ? null
                                                      : theme.cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  border: Border.all(
                                                    color: isAllSelected
                                                        ? Colors.transparent
                                                        : (isDark
                                                            ? const Color(
                                                                0xFF1E293B,
                                                              )
                                                            : const Color(
                                                                0xFFE2E8F0,
                                                              )),
                                                    width: 1.2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isAllSelected
                                                          ? theme
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.35,
                                                              )
                                                          : Colors.black.withValues(
                                                              alpha: isDark
                                                                  ? 0.15
                                                                  : 0.02,
                                                            ),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.grid_view_rounded,
                                                  color: isAllSelected
                                                      ? Colors.white
                                                      : theme.colorScheme.primary,
                                                  size: 26,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                l10n.allItems,
                                                style: TextStyle(
                                                  fontFamily: AppTheme.fontFamily,
                                                  color: isAllSelected
                                                      ? theme.colorScheme.primary
                                                      : (isDark
                                                          ? Colors.grey[300]
                                                          : const Color(
                                                              0xFF334155,
                                                            )),
                                                  fontWeight: isAllSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  fontSize: 12,
                                                  letterSpacing: 0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final category = categories[index - 1];
                                final isSelected =
                                    _selectedCategorySlug == category.slug;
                                final imageUrl = category.imageUrl ?? '';

                                return Padding(
                                  padding: const EdgeInsets.only(right: 14.0),
                                  child: Builder(
                                    builder: (itemContext) => GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        final scrollable = Scrollable.maybeOf(itemContext);
                                        final renderObject = itemContext.findRenderObject();
                                        if (scrollable != null && renderObject != null) {
                                          scrollable.position.ensureVisible(
                                            renderObject,
                                            alignment: 0.5,
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeInOutCubic,
                                          );
                                        }
                                        _onCategorySelected(
                                          isSelected ? null : category.slug,
                                        );
                                      },
                                      child: SizedBox(
                                        width: 68,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF131D38)
                                                    : const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? theme.colorScheme.primary
                                                      : (isDark
                                                          ? const Color(
                                                              0xFF1E293B,
                                                            )
                                                          : const Color(
                                                              0xFFE2E8F0,
                                                            )),
                                                  width: isSelected ? 2.5 : 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isSelected
                                                        ? theme
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.35,
                                                            )
                                                        : Colors.black.withValues(
                                                            alpha: isDark
                                                                ? 0.15
                                                                : 0.02,
                                                          ),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: imageUrl.isNotEmpty
                                                    ? CachedNetworkImage(
                                                        imageUrl: imageUrl,
                                                        fit: BoxFit.cover,
                                                        memCacheWidth: 200,
                                                        memCacheHeight: 200,
                                                        placeholder: (context, url) =>
                                                            Center(
                                                          child: Container(
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF1E293B,
                                                                  )
                                                                : const Color(
                                                                    0xFFF1F5F9,
                                                                  ),
                                                          ),
                                                        ),
                                                        errorWidget:
                                                            (_, _, _) => Center(
                                                          child: Icon(
                                                            Icons.eco_rounded,
                                                            size: 26,
                                                            color: theme
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Icon(
                                                          Icons.eco_rounded,
                                                          size: 26,
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              l10n.translateCategory(category.name),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                fontSize: 12,
                                                letterSpacing: 0,
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : (isDark
                                                        ? Colors.grey[300]
                                                        : const Color(
                                                            0xFF334155,
                                                          )),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Personalized Recommendations: Suggested For You Carousel
              if (_searchQuery.isEmpty && _selectedCategorySlug == null)
                const SliverToBoxAdapter(
                  child: SuggestedForYouSection(),
                ),

              // Section Title: "Our Best Items" or "Search Results" + Result Count
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
                            _searchQuery.isNotEmpty
                                ? (l10n.isKhmer ? 'លទ្ធផលស្វែងរក' : 'Search Results')
                                : (_selectedCategorySlug != null
                                    ? (l10n.isKhmer ? 'ទំនិញតាមប្រភេទ' : 'Category Items')
                                    : (l10n.isKhmer ? 'ទំនិញលក់ដាច់បំផុត' : 'Our Best Items')),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: l10n.isKhmer ? 0 : -0.2,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              l10n.isKhmer
                                  ? 'បង្ហាញលទ្ធផលសម្រាប់ "$_searchQuery"'
                                  : 'Showing matches for "$_searchQuery"',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      if (_sortBy != SortOption.none)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
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
                                _sortBy.label,
                                style: TextStyle(
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

              // Virtualized SliverGrid for high performance
              Consumer(
                builder: (context, ref, _) {
                  final productsState = ref.watch(productsProvider);
                  return productsState.when(
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          const Text(
                            'Unable to load products',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(productsProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (products) {
                  final categories =
                      ref.read(categoriesProvider).valueOrNull ?? [];
                  final selectedCat =
                      CategoryProductsNotifier.findCategory(_selectedCategorySlug, categories);

                  if (selectedCat != null) {
                    final catState = ref.watch(categoryProductsProvider);
                    final catProducts = catState.productsFor(selectedCat.id);
                    final isLoadingCategory = catState.isLoading(selectedCat.id);

                    if (isLoadingCategory && catProducts.isEmpty) {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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

                    final filtered = _getFilteredProducts(
                      catProducts,
                      filterCategory: false,
                    );

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              EmptyStateWidget(
                                icon: Icons.search_off_rounded,
                                title: _searchQuery.isEmpty
                                    ? 'No Products in ${selectedCat.name}'
                                    : 'No results for "$_searchQuery"',
                                message: _searchQuery.isEmpty
                                    ? 'Check back later for fresh stock in this category!'
                                    : 'Try adjusting your search terms or clearing filters.',
                              ),
                              if (filterActive) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.clear_all_rounded),
                                  label: const Text('Clear All Filters'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = filtered[index];
                          return ProductCard(
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
                        }, childCount: filtered.length),
                      ),
                    );
                  }

                  final filtered = _getFilteredProducts(products);

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            EmptyStateWidget(
                              icon: Icons.search_off_rounded,
                              title: _searchQuery.isEmpty
                                  ? 'No Products Available'
                                  : 'No results for "$_searchQuery"',
                              message: _searchQuery.isEmpty
                                  ? 'Check back later for fresh stock!'
                                  : 'Try adjusting your search terms or clearing filters.',
                            ),
                            if (filterActive) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Clear All Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = filtered[index];
                        return ProductCard(
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
                      }, childCount: filtered.length),
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
                  final selectedCat = _selectedCategorySlug != null
                      ? CategoryProductsNotifier.findCategory(
                          _selectedCategorySlug,
                          ref.read(categoriesProvider).valueOrNull ?? [],
                        )
                      : null;
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

  Widget _buildPerkItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
