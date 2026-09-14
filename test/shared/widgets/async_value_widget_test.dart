import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_e_commerce/shared/widgets/async_value_widget.dart';

void main() {
  group('AsyncValueWidget', () {
    testWidgets('renders loading state when value is AsyncLoading', (tester) async {
      const loadingKey = Key('loading');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncValue<String>.loading(),
              loading: const Text('Custom Loading', key: loadingKey),
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byKey(loadingKey), findsOneWidget);
      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('renders error state when value is AsyncError', (tester) async {
      var retryCalled = false;
      final exception = Exception('Error message');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncValue<String>.error(exception, StackTrace.empty),
              onRetry: () => retryCalled = true,
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.text('Exception: Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(retryCalled, true);
    });

    testWidgets('renders data state when value is AsyncData', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncValue<String>.data('My Test Data'),
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.text('My Test Data'), findsOneWidget);
    });
  });
}
