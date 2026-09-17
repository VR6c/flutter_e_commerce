import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/sort_option.dart';

/// Horizontal active filter chips strip for the Home Screen.
class HomeFilterChipsBar extends StatelessWidget {
  final SortOption sortBy;
  final String? selectedCategoryName;
  final RangeValues? priceRange;
  final double? minRating;
  final VoidCallback onClearSort;
  final VoidCallback onClearCategory;
  final VoidCallback onClearPriceRange;
  final VoidCallback onClearMinRating;
  final VoidCallback onClearAll;

  const HomeFilterChipsBar({
    super.key,
    required this.sortBy,
    required this.selectedCategoryName,
    required this.priceRange,
    required this.minRating,
    required this.onClearSort,
    required this.onClearCategory,
    required this.onClearPriceRange,
    required this.onClearMinRating,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (sortBy != SortOption.none)
              _buildChip(
                icon: Icons.swap_vert_rounded,
                label: sortBy.label,
                onRemove: onClearSort,
                theme: theme,
                isDark: isDark,
              ),
            if (selectedCategoryName != null)
              _buildChip(
                icon: Icons.category_rounded,
                label: selectedCategoryName!,
                onRemove: onClearCategory,
                theme: theme,
                isDark: isDark,
              ),
            if (priceRange != null)
              _buildChip(
                icon: Icons.attach_money_rounded,
                label: '\$${priceRange!.start.round()} – \$${priceRange!.end.round()}',
                onRemove: onClearPriceRange,
                theme: theme,
                isDark: isDark,
              ),
            if (minRating != null && minRating! > 0)
              _buildChip(
                icon: Icons.star_rounded,
                label: '$minRating★ & up',
                onRemove: onClearMinRating,
                theme: theme,
                isDark: isDark,
              ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onClearAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.isKhmer ? 'សម្អាតទាំងអស់' : 'Clear All',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
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
}
