import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../categories/providers/category_provider.dart';

/// Horizontal Category story badges with auto-centering on selection.
class HomeCategorySelector extends ConsumerWidget {
  final String? selectedCategorySlug;
  final ValueChanged<String?> onCategorySelected;

  const HomeCategorySelector({
    super.key,
    required this.selectedCategorySlug,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Categories" + "See All"
          Padding(
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.seeAll,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
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

          // Horizontal Category Items
          SizedBox(
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
                    if (categories.isEmpty) return const SizedBox.shrink();

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isAllSelected = selectedCategorySlug == null;
                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Builder(
                              builder: (itemContext) => GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _ensureVisible(itemContext);
                                  onCategorySelected(null);
                                },
                                child: SizedBox(
                                  width: 68,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: isAllSelected
                                              ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    theme.colorScheme.primary,
                                                    const Color(0xFF10B981),
                                                  ],
                                                )
                                              : null,
                                          color: isAllSelected ? null : theme.cardColor,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isAllSelected
                                                ? Colors.transparent
                                                : (isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFE2E8F0)),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isAllSelected
                                                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                                                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          color: isAllSelected ? Colors.white : theme.colorScheme.primary,
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
                                              : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                                          fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w600,
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
                        final isSelected = selectedCategorySlug == category.slug;
                        final imageUrl = category.imageUrl ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: Builder(
                            builder: (itemContext) => GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _ensureVisible(itemContext);
                                onCategorySelected(isSelected ? null : category.slug);
                              },
                              child: SizedBox(
                                width: 68,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF131D38) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                          width: isSelected ? 2.5 : 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                                                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: imageUrl.isNotEmpty
                                            ? AppCachedImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                memCacheWidth: AppImageCache.thumbnailWidth,
                                                errorWidget: Center(
                                                  child: Icon(
                                                    Icons.eco_rounded,
                                                    size: 26,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.eco_rounded,
                                                  size: 26,
                                                  color: theme.colorScheme.primary,
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
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        fontSize: 12,
                                        letterSpacing: 0,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
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
        ],
      ),
    );
  }

  void _ensureVisible(BuildContext context) {
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
  }
}
