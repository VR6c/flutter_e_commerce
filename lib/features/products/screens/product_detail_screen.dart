import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../../../shared/widgets/cart_icon_badge.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../widgets/related_products_section.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.product, this.heroTag});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;
  String? _selectedSize;

  late final List<String> _allColors;
  List<String> _availableSizes = [];
  ProductVariant? _selectedVariant;
  double _displayPrice = 0.0;
  double? _originalPrice;
  bool _hasDiscount = false;
  int? _discountPercentage;
  bool _inStock = true;

  String? _attr(ProductVariant v, String attrName) {
    try {
      return v.attributes
          .firstWhere((a) => a.name.toLowerCase() == attrName.toLowerCase())
          .value;
    } catch (_) {
      return null;
    }
  }

  List<ProductVariant> get _variants => widget.product.variants;

  List<String> _computeAllColors() {
    final seen = <String>{};
    return _variants
        .map((v) => _attr(v, 'Color') ?? '')
        .where((c) => c.isNotEmpty && seen.add(c))
        .toList();
  }

  List<String> _computeAvailableSizes() {
    final seen = <String>{};
    final source = _selectedColor == null
        ? _variants
        : _variants.where((v) => _attr(v, 'Color') == _selectedColor);
    return source
        .map((v) => _attr(v, 'Size') ?? '')
        .where((s) => s.isNotEmpty && seen.add(s))
        .toList();
  }

  ProductVariant? _computeSelectedVariant() {
    if (_variants.isEmpty) return null;
    if (_selectedColor == null && _selectedSize == null) {
      return _variants.firstWhere(
        (v) => v.isPrimary,
        orElse: () => _variants.first,
      );
    }
    try {
      return _variants.firstWhere(
        (v) =>
            (_selectedColor == null || _attr(v, 'Color') == _selectedColor) &&
            (_selectedSize == null || _attr(v, 'Size') == _selectedSize),
      );
    } catch (_) {
      return null;
    }
  }

  void _recomputeDerivedState() {
    _availableSizes = _computeAvailableSizes();
    _selectedVariant = _computeSelectedVariant();

    _displayPrice = _selectedVariant?.discountPrice ??
        _selectedVariant?.price ??
        widget.product.effectivePrice;

    final v = _selectedVariant;
    if (v != null &&
        v.discountPrice != null &&
        v.discountPrice! > 0 &&
        v.price > v.discountPrice!) {
      _originalPrice = v.price;
    } else if (widget.product.originalPrice != null &&
        widget.product.originalPrice! > _displayPrice) {
      _originalPrice = widget.product.originalPrice;
    } else {
      _originalPrice = null;
    }

    _hasDiscount = _originalPrice != null && _originalPrice! > _displayPrice;
    if (_hasDiscount && _originalPrice != null && _originalPrice! > 0) {
      final diff = _originalPrice! - _displayPrice;
      _discountPercentage = ((diff / _originalPrice!) * 100).round();
    } else {
      _discountPercentage = null;
    }

    _inStock = _variants.isEmpty || (_selectedVariant?.stock ?? 1) > 0;
  }

  @override
  void initState() {
    super.initState();
    _allColors = _computeAllColors();

    // Default to the primary variant's attributes if available
    final primary = widget.product.primaryVariant;
    if (primary != null) {
      final color = _attr(primary, 'Color');
      if (color != null && _allColors.contains(color)) {
        _selectedColor = color;
      }
    }
    if (_selectedColor == null && _allColors.isNotEmpty) {
      _selectedColor = _allColors.first;
    }

    final sizes = _computeAvailableSizes();
    if (primary != null) {
      final size = _attr(primary, 'Size');
      if (size != null && sizes.contains(size)) {
        _selectedSize = size;
      }
    }
    if (_selectedSize == null && sizes.isNotEmpty) {
      _selectedSize = sizes.first;
    }

    _recomputeDerivedState();
  }

  void _onColorSelected(String color) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedColor = color;
      final available = _computeAvailableSizes();
      if (_selectedSize == null || !available.contains(_selectedSize)) {
        _selectedSize = available.isNotEmpty ? available.first : null;
      }
      _recomputeDerivedState();
    });
  }

  void _onSizeSelected(String size) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSize = size;
      _recomputeDerivedState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWishlisted = ref.watch(isInWishlistProvider(widget.product.id));

    final imageBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F9F5);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 280 && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 6.0, bottom: 6.0),
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
                  icon: Icon(
                    isWishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isWishlisted
                        ? const Color(0xFFEF4444)
                        : (isDark ? Colors.grey[400] : const Color(0xFF94A3B8)),
                    size: 20,
                  ),
                  onPressed: () {
                    ref
                        .read(wishlistProvider.notifier)
                        .toggleItem(widget.product);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 16.0,
                top: 6.0,
                bottom: 6.0,
              ),
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
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Large rounded pastel image container matching mockup
                    Center(
                      child:
                          widget.heroTag != null && widget.heroTag!.isNotEmpty
                          ? Hero(
                              tag: widget.heroTag!,
                              transitionOnUserGestures: true,
                              placeholderBuilder: (context, heroSize, child) {
                                return SizedBox(
                                  width: heroSize.width,
                                  height: heroSize.height,
                                );
                              },
                              flightShuttleBuilder:
                                  (
                                    flightContext,
                                    animation,
                                    flightDirection,
                                    fromHeroContext,
                                    toHeroContext,
                                  ) {
                                    return Material(
                                      type: MaterialType.transparency,
                                      child: toHeroContext.widget,
                                    );
                                  },
                              child: _buildImageCard(imageBg, theme),
                            )
                          : _buildImageCard(imageBg, theme),
                    ),
                    const SizedBox(height: 20),

                    // Title and Rating row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: context.l10n.isKhmer
                                      ? 0
                                      : -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product.shortDescription.isNotEmpty
                                    ? widget.product.shortDescription
                                    : (context.l10n.isKhmer
                                          ? '${context.l10n.translateCategory(widget.product.category)} · មានក្នុងស្តុក'
                                          : '${widget.product.category} · Fresh Stock'),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  letterSpacing: 0,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (widget.product.rating ?? 4.8).toStringAsFixed(
                                  1,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price & Quantity Stepper Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.isKhmer
                                  ? 'តម្លៃសរុប'
                                  : 'Total Price',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$${(_displayPrice * _quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                if (_hasDiscount && _originalPrice != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${(_originalPrice! * _quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : const Color(0xFF94A3B8),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  if (_discountPercentage != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '-$_discountPercentage%',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ],
                        ),
                        // Quantity counter stepper
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF3F9F5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildStepperBtn(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                theme: theme,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              _buildStepperBtn(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  setState(() => _quantity++);
                                },
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Product Variants (if available)
                    if (_allColors.isNotEmpty) ...[
                      Text(
                        context.l10n.colorLabel,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _allColors.map((color) {
                          final isSel = _selectedColor == color;
                          return ChoiceChip(
                            label: Text(
                              context.l10n.translateColor(color),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isSel
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            onSelected: (val) {
                              if (val) _onColorSelected(color);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_availableSizes.isNotEmpty) ...[
                      Text(
                        context.l10n.sizeUnitLabel,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _availableSizes.map((size) {
                          final isSel = _selectedSize == size;
                          return ChoiceChip(
                            label: Text(
                              context.l10n.translateSize(size),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isSel
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            onSelected: (val) {
                              if (val) _onSizeSelected(size);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    Text(
                      context.l10n.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product.shortDescription.isNotEmpty
                          ? widget.product.shortDescription
                          : (context.l10n.isKhmer
                                ? 'ទំនិញគុណភាពខ្ពស់ ត្រូវបានជ្រើសរើសយ៉ាងយកចិត្តទុកដាក់ និងដឹកជញ្ជូនដល់គេហដ្ឋានរបស់អ្នកដោយផ្ទាល់ ធានាគុណភាពល្អ ១០០%។'
                                : 'High quality product are carefully selected and delivered straight to your door. Hand-picked for the best quality and freshness guaranteed.'),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.5,
                        height: 1.6,
                        letterSpacing: 0,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              RelatedProductsSection(productSlug: widget.product.slug),
              const SizedBox(height: 120),
            ],
          ),
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _inStock
                    ? () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              widget.product,
                              quantity: _quantity,
                              variantId: _selectedVariant?.id,
                              variantName: _selectedVariant?.name,
                              selectedColor: _selectedColor,
                              selectedSize: _selectedSize,
                              unitPrice: _displayPrice,
                            );
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.l10n.isKhmer
                                        ? 'បានបន្ថែម $_quantity × ${widget.product.name} ទៅកន្ត្រក'
                                        : 'Added $_quantity × ${widget.product.name} to cart',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: context.l10n.isKhmer
                                  ? 'មើលកន្ត្រក'
                                  : 'View Cart',
                              textColor: Colors.white,
                              onPressed: () => context.push('/cart'),
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                label: Text(
                  _inStock
                      ? '${context.l10n.addToCart} · \$${(_displayPrice * _quantity).toStringAsFixed(2)}'
                      : context.l10n.outOfStock,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(Color imageBg, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 340,
      decoration: BoxDecoration(
        color: imageBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: widget.product.thumbnail,
          fit: BoxFit.cover,
          memCacheWidth: AppImageCache.detailWidth,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => Center(
            child: Container(
              color: imageBg,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          errorWidget: (context, url, error) {
            final fallback = getFallbackImageUrl(
              slug: widget.product.slug,
              title: widget.product.name,
              category: widget.product.category,
            );
            if (fallback.isNotEmpty) {
              return CachedNetworkImage(
                imageUrl: fallback,
                fit: BoxFit.cover,
                memCacheWidth: AppImageCache.detailWidth,
              );
            }
            return Icon(
              Icons.eco_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
