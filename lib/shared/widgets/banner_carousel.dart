import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/utils/image_url_formatter.dart';
import '../../features/home/models/banner.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  final ValueChanged<BannerModel>? onBannerTap;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  Timer? _timer;

  String _getBannerBadge(BannerModel banner) {
    final type = banner.type?.trim();
    if (type != null && type.isNotEmpty) {
      switch (type.toLowerCase()) {
        case 'promotion':
          return 'PROMOTION';
        case 'sale':
          return 'SPECIAL SALE';
        case 'seasonal':
          return 'SEASONAL';
        case 'featured':
          return 'FEATURED';
        case 'announcement':
          return 'ANNOUNCEMENT';
        default:
          return type.toUpperCase();
      }
    }
    return 'FRESH DEALS';
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
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final placeholderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

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
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                          child: Container(color: placeholderColor),
                        ),
                        errorWidget: (context, url, error) {
                          final fallback = getFallbackImageUrl(
                            title: banner.title,
                            url: banner.imageUrl,
                            isBanner: true,
                          );
                          if (url != fallback && fallback.isNotEmpty) {
                            return CachedNetworkImage(
                              imageUrl: fallback,
                              fit: BoxFit.cover,
                              memCacheWidth: 800,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: baseColor,
                                highlightColor: highlightColor,
                                child: Container(color: placeholderColor),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                child: Icon(Icons.shopping_bag_outlined, size: 40, color: theme.hintColor),
                              ),
                            );
                          }
                          return Container(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            child: Icon(Icons.shopping_bag_outlined, size: 40, color: theme.hintColor),
                          );
                        },
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getBannerBadgeColor(banner, theme.colorScheme.primary),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getBannerBadgeColor(banner, theme.colorScheme.primary).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _getBannerBadge(banner),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (banner.description != null && banner.description!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                banner.description!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                              highlightColor: Colors.white.withValues(alpha: 0.08),
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
                          : (isDark ? Colors.grey[700] : const Color(0xFFCBD5E1)),
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
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
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
