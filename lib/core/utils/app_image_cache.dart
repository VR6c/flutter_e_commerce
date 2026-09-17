import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Centralized image cache dimensions and optimized image widget.
/// Standardizes memory decoding bounds to prevent OOM and reduce GPU/RAM usage.
abstract final class AppImageCache {
  /// Optimal decode width for small avatars and compact list thumbnails (e.g. Cart, Search).
  static const int thumbnailWidth = 180;

  /// Optimal decode width for 2-column grid product cards.
  /// Decoded at ~360px physical width, leaving height unconstrained to preserve aspect ratio.
  static const int cardWidth = 360;

  /// Optimal decode width for high-fidelity product detail hero image.
  static const int detailWidth = 720;

  /// Optimal decode width for full-width home screen promo banners.
  static const int bannerWidth = 800;
}

/// Optimized, memory-bounded network image with dark/light mode shimmer and graceful fallback.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth = AppImageCache.cardWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 120),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final fallbackBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      placeholder: (context, url) =>
          placeholder ??
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              color: Colors.white,
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: fallbackBg,
            alignment: Alignment.center,
            child: Icon(
              Icons.eco_rounded,
              size: 28,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
