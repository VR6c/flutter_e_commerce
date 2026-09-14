import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/brand_provider.dart';

class BrandListScreen extends ConsumerWidget {
  const BrandListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsState = ref.watch(brandsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final placeholderColor = isDark ? Colors.black : Colors.white;

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
        title: const Text(
          'Brands',
          style: TextStyle(fontWeight: FontWeight.w700),
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
              childAspectRatio: 1.1,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => Card(
              clipBehavior: Clip.antiAlias,
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 50, width: 50, color: placeholderColor),
                    const SizedBox(height: 12),
                    Container(height: 12, width: 70, color: placeholderColor),
                  ],
                ),
              ),
            ),
          ),
          data: (brands) {
            if (brands.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.branding_watermark_outlined,
                title: 'No Brands Found',
                message: 'No brands are registered at this time.',
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return RepaintBoundary(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: brand.logoUrl!,
                                      fit: BoxFit.contain,
                                      memCacheWidth: 200,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                        child: Container(color: placeholderColor),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: theme.hintColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.business,
                                      size: 40,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              brand.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
