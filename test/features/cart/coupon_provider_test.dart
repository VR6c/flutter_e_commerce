import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';
import 'package:flutter_e_commerce/core/api/app_exception.dart';
import 'package:flutter_e_commerce/core/api/providers.dart';
import 'package:flutter_e_commerce/features/cart/providers/coupon_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockApiClient),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CouponProvider Tests', () {
    test('initial state is unapplied with 0 discount', () {
      final state = container.read(couponProvider);
      expect(state.isApplied, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.discountAmount, 0.0);
      expect(state.errorMessage, isNull);
      expect(state.code, isEmpty);
    });

    test('captures AppException error message correctly', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            '/coupons/validate',
            data: {'code': 'SAVE50'},
          )).thenThrow(
        ValidationException(
          message: 'Coupon "SAVE50" has expired',
        ),
      );

      final notifier = container.read(couponProvider.notifier);
      await notifier.applyCoupon('SAVE50');

      final state = container.read(couponProvider);
      expect(state.isApplied, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Coupon "SAVE50" has expired');
      expect(state.discountAmount, 0.0);
    });

    test('applies valid coupon successfully', () async {
      final requestOptions = RequestOptions(path: '/coupons/validate');
      when(() => mockApiClient.post<Map<String, dynamic>>(
            '/coupons/validate',
            data: {'code': 'PROMO20'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions,
          data: {
            'status': true,
            'data': {'discount_amount': 20.0},
          },
          statusCode: 200,
        ),
      );

      final notifier = container.read(couponProvider.notifier);
      await notifier.applyCoupon('PROMO20');

      final state = container.read(couponProvider);
      expect(state.isApplied, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.code, 'PROMO20');
      expect(state.discountAmount, 20.0);
      expect(state.errorMessage, isNull);
    });

    test('removeCoupon clears discount and code', () async {
      final requestOptions = RequestOptions(path: '/coupons/validate');
      when(() => mockApiClient.post<Map<String, dynamic>>(
            '/coupons/validate',
            data: {'code': 'FIXED15'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions,
          data: {
            'status': true,
            'data': {'discount_amount': 15.0},
          },
          statusCode: 200,
        ),
      );

      final notifier = container.read(couponProvider.notifier);
      await notifier.applyCoupon('FIXED15');
      expect(container.read(couponProvider).isApplied, isTrue);

      notifier.removeCoupon();
      final resetState = container.read(couponProvider);
      expect(resetState.isApplied, isFalse);
      expect(resetState.discountAmount, 0.0);
      expect(resetState.code, isEmpty);
    });
  });
}
