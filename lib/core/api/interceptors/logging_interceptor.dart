import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Clean, structured logger for API requests, responses, and errors.
/// Active only in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO >> REQUEST] ${options.method} ${options.uri}');
      if (options.headers.isNotEmpty) {
        final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
        if (sanitizedHeaders.containsKey('Authorization')) {
          sanitizedHeaders['Authorization'] = 'Bearer ***';
        }
        debugPrint('   Headers: $sanitizedHeaders');
      }
      if (options.data != null) {
        debugPrint('   Body: ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   QueryParams: ${options.queryParameters}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[DIO << RESPONSE] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '❌ [DIO !! ERROR] ${err.response?.statusCode ?? 'NO_STATUS'} ${err.requestOptions.method} ${err.requestOptions.uri}',
      );
      debugPrint('   Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('   Response Data: ${err.response?.data}');
      }
    }
    super.onError(err, handler);
  }
}
