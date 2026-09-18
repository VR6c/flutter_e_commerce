import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/brand_provider.dart';

class BrandListScreen extends ConsumerWidget {
  const BrandListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsState = ref.watch(brandsProvider);
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final l10n = context.l10n;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final placeholderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          l10n.brands,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(brandsProvider),
        child: AsyncValueWidget(
          value: brandsState,
          onRetry: () => ref.invalidate(brandsProvider),
          loading: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderSubtle, width: 1.2),
              ),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 52, width: 52, color: placeholderColor),
                    const SizedBox(height: 12),
                    Container(height: 14, width: 80, color: placeholderColor),
                  ],
                ),
              ),
            ),
          ),
          data: (brands) {
            if (brands.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.branding_watermark_outlined,
                title: l10n.noBrandsFound,
                message: l10n.noBrandsAreRegisteredAt,
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return RepaintBoundary(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderSubtle, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push(
                              AppRoutes.categoryProducts,
                              extra: {
                                'categoryName': brand.name,
                                'categorySlugs': [brand.slug, brand.name],
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                                      ? AppCachedImage(
                                          imageUrl: brand.logoUrl!,
                                          fit: BoxFit.contain,
                                          memCacheWidth: AppImageCache.thumbnailWidth,
                                          errorWidget: Icon(
                                            Icons.business_rounded,
                                            size: 40,
                                            color: theme.hintColor,
                                          ),
                                        )
                                      : Icon(
                                          Icons.business_rounded,
                                          size: 40,
                                          color: theme.hintColor,
                                        ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  brand.name,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
