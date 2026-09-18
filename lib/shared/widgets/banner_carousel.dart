import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/utils/app_image_cache.dart';
import '../../core/utils/image_url_formatter.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/models/banner.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  final ValueChanged<BannerModel>? onBannerTap;

  const BannerCarousel({super.key, required this.banners, this.onBannerTap});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  Timer? _timer;

  String _getBannerBadge(BuildContext context, BannerModel banner) {
    final l10n = context.l10n;
    final type = banner.type?.trim();
    if (type != null && type.isNotEmpty) {
      switch (type.toLowerCase()) {
        case 'promotion':
          return l10n.promotion;
        case 'sale':
          return l10n.specialSale;
        case 'seasonal':
          return l10n.seasonal;
        case 'featured':
          return l10n.featured;
        case 'announcement':
          return l10n.announcement;
        default:
          return type.toUpperCase();
      }
    }
    return l10n.freshDeals;
  }

  String _getLocalizedTitle(BuildContext context, String title) {
    if (!context.l10n.isKhmer) return title;
    final lower = title.toLowerCase();
    if (lower.contains('summer sale')) return 'ការបញ្ចុះតម្លៃរដូវក្តៅ';
    if (lower.contains('flash sale')) return 'ការបញ្ចុះតម្លៃរហ័ស';
    if (lower.contains('special sale') || lower.contains('special deals')) {
      return 'ការផ្ដល់ជូនពិសេស';
    }
    if (lower.contains('fresh')) return 'ទំនិញគុណភាពល្អៗ';
    return title;
  }

  String _getLocalizedDesc(BuildContext context, String desc) {
    if (!context.l10n.isKhmer) return desc;
    final lower = desc.toLowerCase();
    if (lower.contains('50% off') || lower.contains('selected fashion')) {
      return 'បញ្ចុះតម្លៃរហូតដល់ 50% លើទំនិញពេញនិយម';
    }
    if (lower.contains('free delivery') || lower.contains('free shipping')) {
      return 'ដឹកជញ្ជូនឥតគិតថ្លៃសម្រាប់ការបញ្ជាទិញដំបូង';
    }
    return desc;
  }

  Color _getBannerBadgeColor(BannerModel banner, Color primary) {
    final type = banner.type?.trim().toLowerCase();
    switch (type) {
      case 'sale':
        return const Color(0xFFEF4444); // Vibrant Red
      case 'promotion':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'seasonal':
        return const Color(0xFF10B981); // Emerald Green
      case 'announcement':
        return const Color(0xFF6366F1); // Indigo
      default:
        return primary;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.banners.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          final nextPage =
              (_currentPageNotifier.value + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _currentPageNotifier.value = index;
              },
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.04,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppCachedImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: AppImageCache.bannerWidth,
                        fallbackImageUrl: getFallbackImageUrl(
                          title: banner.title,
                          url: banner.imageUrl,
                          isBanner: true,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 18,
                        right: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getBannerBadgeColor(
                                  banner,
                                  theme.colorScheme.primary,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getBannerBadgeColor(
                                      banner,
                                      theme.colorScheme.primary,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _getBannerBadge(context, banner),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: context.l10n.isKhmer ? 0 : 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getLocalizedTitle(context, banner.title),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: context.l10n.isKhmer ? 0 : -0.3,
                              ),
                            ),
                            if (banner.description != null &&
                                banner.description!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                _getLocalizedDesc(context, banner.description!),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.onBannerTap != null)
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onBannerTap!(banner),
                              splashColor: Colors.white.withValues(alpha: 0.15),
                              highlightColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: _currentPageNotifier,
            builder: (context, currentPage, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: currentPage == index ? 22 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: currentPage == index
                          ? theme.colorScheme.primary
                          : (isDark
                                ? Colors.grey[700]
                                : const Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BannerCarouselShimmer extends StatelessWidget {
  const BannerCarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF8FAFC);
    final placeholderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return RepaintBoundary(
      child: Column(
        children: [
          Container(
            height: 170,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: placeholderColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                width: index == 0 ? 22 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
