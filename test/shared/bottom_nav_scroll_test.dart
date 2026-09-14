import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_e_commerce/shared/providers/bottom_nav_scroll_provider.dart';

void main() {
  group('bottomNavScrollProvider', () {
    test('initial state has tabIndex -1 and triggerCount 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(bottomNavScrollProvider);
      expect(state.tabIndex, -1);
      expect(state.triggerCount, 0);
    });

    test('requestScrollToTop increments triggerCount and updates tabIndex', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bottomNavScrollProvider.notifier);

      notifier.requestScrollToTop(0);
      expect(container.read(bottomNavScrollProvider).tabIndex, 0);
      expect(container.read(bottomNavScrollProvider).triggerCount, 1);

      // Multiple clicks on the same tab
      notifier.requestScrollToTop(0);
      expect(container.read(bottomNavScrollProvider).tabIndex, 0);
      expect(container.read(bottomNavScrollProvider).triggerCount, 2);

      notifier.requestScrollToTop(1);
      expect(container.read(bottomNavScrollProvider).tabIndex, 1);
      expect(container.read(bottomNavScrollProvider).triggerCount, 3);
    });

    testWidgets('scrolls scrollable view back to top on bottomNavScrollProvider event', (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                ref.listen<BottomNavScrollEvent>(bottomNavScrollProvider, (previous, next) {
                  if (next.tabIndex == 0 && scrollController.hasClients) {
                    scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return Scaffold(
                  body: ListView.builder(
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (context, index) => SizedBox(
                      height: 50,
                      child: Text('Item $index'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial offset is 0
      expect(scrollController.offset, 0.0);

      // Scroll down
      scrollController.jumpTo(500.0);
      await tester.pumpAndSettle();
      expect(scrollController.offset, 500.0);

      // Trigger scroll-to-top event via provider
      final element = tester.element(find.byType(Scaffold));
      final container = ProviderScope.containerOf(element);
      container.read(bottomNavScrollProvider.notifier).requestScrollToTop(0);

      await tester.pumpAndSettle();
      expect(scrollController.offset, 0.0);
    });
  });
}
