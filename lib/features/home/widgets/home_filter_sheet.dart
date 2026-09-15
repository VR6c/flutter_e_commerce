import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/sort_option.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_provider.dart';
import '../../products/models/product.dart';

/// Immutable filter state encapsulating all filter and sort criteria.
class HomeFilterState {
  final SortOption sortBy;
  final String? categorySlug;
  final RangeValues? priceRange;
  final double? minRating;

  const HomeFilterState({
    this.sortBy = SortOption.none,
    this.categorySlug,
    this.priceRange,
    this.minRating,
  });

  bool get isActive =>
      sortBy != SortOption.none ||
      categorySlug != null ||
      priceRange != null ||
      (minRating != null && minRating! > 0);

  int get activeCount {
    int count = 0;
    if (sortBy != SortOption.none) count++;
    if (categorySlug != null) count++;
    if (priceRange != null) count++;
    if (minRating != null && minRating! > 0) count++;
    return count;
  }

  HomeFilterState copyWith({
    SortOption? sortBy,
    String? Function()? categorySlug,
    RangeValues? Function()? priceRange,
    double? Function()? minRating,
  }) {
    return HomeFilterState(
      sortBy: sortBy ?? this.sortBy,
      categorySlug: categorySlug != null ? categorySlug() : this.categorySlug,
      priceRange: priceRange != null ? priceRange() : this.priceRange,
      minRating: minRating != null ? minRating() : this.minRating,
    );
  }
}

class HomeFilterSheet extends ConsumerStatefulWidget {
  final HomeFilterState initialState;
  final List<Product> allProducts;
  final List<Category>? initialCategories;

  const HomeFilterSheet({
    super.key,
    required this.initialState,
    required this.allProducts,
    this.initialCategories,
  });

  static Future<HomeFilterState?> show({
    required BuildContext context,
    required HomeFilterState initialState,
    required List<Product> allProducts,
    List<Category>? initialCategories,
  }) {
    return showModalBottomSheet<HomeFilterState>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => HomeFilterSheet(
        initialState: initialState,
        allProducts: allProducts,
        initialCategories: initialCategories,
      ),
    );
  }

  @override
  ConsumerState<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends ConsumerState<HomeFilterSheet> {
  late SortOption _draftSort;
  late String? _draftCategorySlug;
  late RangeValues? _draftPriceRange;
  late double? _draftMinRating;

  late double _maxBoundPrice;

  @override
  void initState() {
    super.initState();
    _draftSort = widget.initialState.sortBy;
    _draftCategorySlug = widget.initialState.categorySlug;
    _draftPriceRange = widget.initialState.priceRange;
    _draftMinRating = widget.initialState.minRating;

    // Calculate maximum bound for price slider
    if (widget.allProducts.isNotEmpty) {
      final highest = widget.allProducts
          .map((p) => p.effectivePrice)
          .fold<double>(0.0, (prev, curr) => max(prev, curr));
      _maxBoundPrice = max(20.0, (highest / 10).ceil() * 10.0);
    } else {
      _maxBoundPrice = 100.0;
    }
  }

  HomeFilterState get _currentState => HomeFilterState(
        sortBy: _draftSort,
        categorySlug: _draftCategorySlug,
        priceRange: _draftPriceRange,
        minRating: _draftMinRating,
      );

  int _calculateMatches() {
    return widget.allProducts.where((p) {
      // Category filter
      if (_draftCategorySlug != null && _draftCategorySlug!.isNotEmpty) {
        final cat = p.category.toLowerCase();
        final sel = _draftCategorySlug!.toLowerCase();
        if (!cat.contains(sel) && !sel.contains(cat)) {
          return false;
        }
      }

      // Rating filter
      if (_draftMinRating != null && _draftMinRating! > 0) {
        if ((p.rating ?? 0) < _draftMinRating!) {
          return false;
        }
      }

      // Price range filter
      if (_draftPriceRange != null) {
        if (p.effectivePrice < _draftPriceRange!.start ||
            p.effectivePrice > _draftPriceRange!.end) {
          return false;
        }
      }

      return true;
    }).length;
  }

  void _resetAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _draftSort = SortOption.none;
      _draftCategorySlug = null;
      _draftPriceRange = null;
      _draftMinRating = null;
    });
  }

  void _applyAndClose() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(_currentState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final categories = widget.initialCategories ??
        ref.watch(categoriesProvider).valueOrNull ??
        <Category>[];

    final matchesCount = _calculateMatches();
    final activeCount = _currentState.activeCount;
    final hasActiveFilter = _currentState.isActive;

    final currentSliderRange = _draftPriceRange ??
        RangeValues(0.0, _maxBoundPrice);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D38) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              children: [
                Text(
                  context.l10n.isKhmer ? 'តម្រៀប & តម្រង' : 'Sort & Filter',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: 0,
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      context.l10n.isKhmer
                          ? '$activeCount កំពុងប្រើ'
                          : '$activeCount Active',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (hasActiveFilter)
                  GestureDetector(
                    onTap: _resetAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        context.l10n.isKhmer ? 'កំណត់ឡើងវិញ' : 'Reset All',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Filter Sections
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sort By Section
                  _buildSectionHeader(
                    icon: Icons.swap_vert_rounded,
                    title: context.l10n.sortBy,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildSortOptions(theme, isDark, primary),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // 2. Categories Section
                  if (categories.isNotEmpty) ...[
                    _buildSectionHeader(
                      icon: Icons.grid_view_rounded,
                      title: context.l10n.categories,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryChips(categories, theme, isDark, primary),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                  ],

                  // 3. Price Range Section
                  _buildSectionHeader(
                    icon: Icons.attach_money_rounded,
                    title: context.l10n.isKhmer ? 'កម្រិតតម្លៃ' : 'Price Range',
                    theme: theme,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _draftPriceRange == null
                            ? (context.l10n.isKhmer ? 'តម្លៃទាំងអស់' : 'All Prices')
                            : '\$${currentSliderRange.start.round()} – \$${currentSliderRange.end.round()}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPriceSelector(
                    currentSliderRange,
                    theme,
                    isDark,
                    primary,
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // 4. Rating Section
                  _buildSectionHeader(
                    icon: Icons.star_rounded,
                    title: context.l10n.isKhmer ? 'ការវាយតម្លៃ' : 'Customer Rating',
                    iconColor: Colors.amber[600],
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildRatingChips(theme, isDark, primary),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D38) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              children: [
                // Reset Button
                if (hasActiveFilter)
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _resetAll,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        context.l10n.reset,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                if (hasActiveFilter) const SizedBox(width: 12),

                // Apply Button
                Expanded(
                  flex: hasActiveFilter ? 3 : 1,
                  child: ElevatedButton(
                    onPressed: matchesCount > 0 ? _applyAndClose : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: matchesCount > 0 ? 3 : 0,
                      shadowColor: primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          matchesCount > 0
                              ? (context.l10n.isKhmer
                                  ? 'អនុវត្ត ($matchesCount មុខ)'
                                  : 'Apply ($matchesCount Products)')
                              : (context.l10n.isKhmer
                                  ? 'គ្មានទំនិញត្រូវគ្នាទេ'
                                  : 'No Products Match'),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required ThemeData theme,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildSortOptions(ThemeData theme, bool isDark, Color primary) {
    final isKm = context.l10n.isKhmer;
    final sortItems = [
      (
        SortOption.none,
        isKm ? 'លំនាំដើម (ណែនាំ)' : 'Default (Recommended)',
        Icons.auto_awesome_rounded,
      ),
      (
        SortOption.priceAsc,
        isKm ? 'តម្លៃ: ពីទាបទៅខ្ពស់' : 'Price: Low to High',
        Icons.arrow_downward_rounded,
      ),
      (
        SortOption.priceDesc,
        isKm ? 'តម្លៃ: ពីខ្ពស់ទៅទាប' : 'Price: High to Low',
        Icons.arrow_upward_rounded,
      ),
      (
        SortOption.rating,
        isKm ? 'ការវាយតម្លៃខ្ពស់' : 'Top Rated',
        Icons.star_rounded,
      ),
      (
        SortOption.nameAsc,
        isKm ? 'ឈ្មោះ: A – Z' : 'Name: A – Z',
        Icons.sort_by_alpha_rounded,
      ),
    ];

    return Column(
      children: sortItems.map((item) {
        final (opt, label, icon) = item;
        final isSelected = _draftSort == opt;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _draftSort = opt);
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.10)
                    : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withValues(alpha: 0.16)
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFEDF2F7)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: isSelected ? primary : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0,
                      color: isSelected
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? primary
                            : (isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1)),
                        width: 1.8,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips(
    List<Category> categories,
    ThemeData theme,
    bool isDark,
    Color primary,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // All Categories Chip
        _buildChipItem(
          label: context.l10n.allItems,
          isSelected: _draftCategorySlug == null,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _draftCategorySlug = null);
          },
          theme: theme,
          isDark: isDark,
          primary: primary,
        ),
        // Each Category Chip
        ...categories.map((cat) {
          final isSelected = _draftCategorySlug == cat.slug;
          return _buildChipItem(
            label: context.l10n.translateCategory(cat.name),
            imageUrl: cat.imageUrl,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _draftCategorySlug = isSelected ? null : cat.slug;
              });
            },
            theme: theme,
            isDark: isDark,
            primary: primary,
          );
        }),
      ],
    );
  }

  Widget _buildChipItem({
    required String label,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                  memCacheWidth: 60,
                  memCacheHeight: 60,
                  errorWidget: (_, _, _) => Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: isSelected ? Colors.white : primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSelector(
    RangeValues currentRange,
    ThemeData theme,
    bool isDark,
    Color primary,
  ) {
    final quickTiers = [
      (context.l10n.isKhmer ? 'ទាំងអស់' : 'All', null),
      ('Under \$10', const RangeValues(0.0, 10.0)),
      ('\$10 – \$25', const RangeValues(10.0, 25.0)),
      ('\$25 – \$50', const RangeValues(25.0, 50.0)),
      ('\$50+', RangeValues(50.0, _maxBoundPrice)),
    ];

    return Column(
      children: [
        // Quick tier chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickTiers.map((tier) {
            final (title, range) = tier;
            final isTierSelected = range == null
                ? _draftPriceRange == null
                : (_draftPriceRange != null &&
                    (_draftPriceRange!.start - range.start).abs() < 0.1 &&
                    (_draftPriceRange!.end - range.end).abs() < 0.1);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _draftPriceRange = range;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isTierSelected
                      ? primary.withValues(alpha: 0.12)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTierSelected
                        ? primary
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    width: isTierSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isTierSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isTierSelected
                        ? primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Range Slider
        RangeSlider(
          values: RangeValues(
            currentRange.start.clamp(0.0, _maxBoundPrice),
            currentRange.end.clamp(0.0, _maxBoundPrice),
          ),
          min: 0.0,
          max: _maxBoundPrice,
          divisions: (_maxBoundPrice / 5).round().clamp(10, 50),
          activeColor: primary,
          inactiveColor: isDark
              ? const Color(0xFF1E293B)
              : primary.withValues(alpha: 0.15),
          labels: RangeLabels(
            '\$${currentRange.start.round()}',
            '\$${currentRange.end.round()}',
          ),
          onChanged: (newValues) {
            setState(() {
              if (newValues.start <= 0.5 &&
                  newValues.end >= _maxBoundPrice - 0.5) {
                _draftPriceRange = null; // covers all prices
              } else {
                _draftPriceRange = newValues;
              }
            });
          },
        ),

        // Min - Max readout labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${_maxBoundPrice.round()}+',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingChips(ThemeData theme, bool isDark, Color primary) {
    final isKm = context.l10n.isKhmer;
    final ratings = [
      (isKm ? 'ទាំងអស់' : 'Any', null),
      (isKm ? '4.5★ ឡើងទៅ' : '4.5★ & up', 4.5),
      (isKm ? '4.0★ ឡើងទៅ' : '4.0★ & up', 4.0),
      (isKm ? '3.5★ ឡើងទៅ' : '3.5★ & up', 3.5),
      (isKm ? '3.0★ ឡើងទៅ' : '3.0★ & up', 3.0),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ratings.map((item) {
        final (label, val) = item;
        final isSelected = _draftMinRating == val;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _draftMinRating = val);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.12)
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primary
                    : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (val != null) ...[
                  Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: isSelected ? Colors.amber[700] : Colors.amber,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
