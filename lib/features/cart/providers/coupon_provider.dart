import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/api/providers.dart';

/// State for the coupon step in checkout.
class CouponState {
  final String code;
  final double discountAmount;
  final String? errorMessage;
  final bool isLoading;
  final bool isApplied;

  const CouponState({
    this.code = '',
    this.discountAmount = 0.0,
    this.errorMessage,
    this.isLoading = false,
    this.isApplied = false,
  });

  CouponState copyWith({
    String? code,
    double? discountAmount,
    String? errorMessage,
    bool? isLoading,
    bool? isApplied,
    bool clearError = false,
  }) {
    return CouponState(
      code: code ?? this.code,
      discountAmount: discountAmount ?? this.discountAmount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}

class CouponNotifier extends StateNotifier<CouponState> {
  final Ref _ref;

  CouponNotifier(this._ref) : super(const CouponState());

  /// Validate and apply a coupon code via the API.
  /// Expects a POST /coupons/validate response like:
  ///   { "status": true, "data": { "discount_amount": 5.00 } }
  Future<void> applyCoupon(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter a coupon code.',
        isApplied: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isApplied: false,
      clearError: true,
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post<Map<String, dynamic>>(
        '/coupons/validate',
        data: {'code': trimmed},
      );

      final data = response.data;
      if (data != null &&
          data['status'] == true &&
          data['data'] is Map<String, dynamic>) {
        final discount =
            (data['data']['discount_amount'] as num?)?.toDouble() ?? 0.0;
        state = state.copyWith(
          code: trimmed,
          discountAmount: discount,
          isApplied: true,
          isLoading: false,
          clearError: true,
        );
      } else {
        final message =
            (data is Map<String, dynamic> ? data['message'] as String? : null) ??
                'Invalid coupon code.';
        state = state.copyWith(
          errorMessage: message,
          isApplied: false,
          isLoading: false,
          discountAmount: 0.0,
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(
        errorMessage: e.message,
        isApplied: false,
        isLoading: false,
        discountAmount: 0.0,
      );
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final message = (errorData is Map<String, dynamic>
              ? errorData['message'] as String?
              : null) ??
          'Failed to validate coupon. Please try again.';
      state = state.copyWith(
        errorMessage: message,
        isApplied: false,
        isLoading: false,
        discountAmount: 0.0,
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Failed to validate coupon. Please try again.',
        isApplied: false,
        isLoading: false,
        discountAmount: 0.0,
      );
    }
  }

  /// Remove the applied coupon and reset state.
  void removeCoupon() {
    state = const CouponState();
  }
}

final couponProvider =
    StateNotifierProvider.autoDispose<CouponNotifier, CouponState>(
  (ref) => CouponNotifier(ref),
);
