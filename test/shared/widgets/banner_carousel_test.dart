import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_e_commerce/features/home/models/banner.dart';
import 'package:flutter_e_commerce/shared/widgets/banner_carousel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBanners = [
    const BannerModel(
      id: 1,
      type: 'sale',
      title: 'Mega Summer Sale',
      description: 'Up to 50% discount on all items',
      imageUrl: 'https://example.com/banner1.jpg',
    ),
    const BannerModel(
      id: 2,
      type: 'promotion',
      title: 'Ready to Shop',
      description: 'Your one-stop shop for fresh items',
      imageUrl: 'https://example.com/banner2.jpg',
    ),
    const BannerModel(
      id: 3,
      type: null,
      title: 'Daily Essentials',
      description: 'Always fresh and organic',
      imageUrl: 'https://example.com/banner3.jpg',
    ),
  ];

  group('BannerCarousel', () {
    testWidgets('renders SizedBox.shrink when banner list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerCarousel(banners: []),
          ),
        ),
      );

      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders dynamic badge, title, and description from API data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerCarousel(banners: testBanners),
          ),
        ),
      );

      // Verify the first banner's dynamic badge and texts
      expect(find.text('SPECIAL SALE'), findsOneWidget);
      expect(find.text('Mega Summer Sale'), findsOneWidget);
      expect(find.text('Up to 50% discount on all items'), findsOneWidget);
    });

    testWidgets('triggers onBannerTap callback when banner card is tapped', (tester) async {
      BannerModel? tappedBanner;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerCarousel(
              banners: testBanners,
              onBannerTap: (banner) => tappedBanner = banner,
            ),
          ),
        ),
      );

      // Tap the banner card
      final bannerFinder = find.text('Mega Summer Sale');
      expect(bannerFinder, findsOneWidget);
      await tester.tap(bannerFinder);
      await tester.pump();

      expect(tappedBanner, isNotNull);
      expect(tappedBanner!.id, 1);
      expect(tappedBanner!.type, 'sale');
      expect(tappedBanner!.title, 'Mega Summer Sale');
    });

    testWidgets('renders BannerCarouselShimmer properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerCarouselShimmer(),
          ),
        ),
      );

      expect(find.byType(BannerCarouselShimmer), findsOneWidget);
    });
  });
}
