import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  DioClient._();

  static const Duration defaultTimeout = Duration(seconds: 45);
  static const Duration refreshTimeout = Duration(seconds: 15);

  static Dio createDio({
    required SecureStorageService storageService,
    VoidCallback? onAuthFailed,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: defaultTimeout,
        receiveTimeout: defaultTimeout,
        sendTimeout: defaultTimeout,
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate',
        },
        contentType: 'application/json',
      ),
    );

    final refreshDio = createRefreshDio(baseUrl: baseUrl);

    dio.interceptors.addAll([
      AuthInterceptor(
        storageService: storageService,
        dio: dio,
        refreshDio: refreshDio,
        onAuthFailed: onAuthFailed,
      ),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    return dio;
  }

  static Dio createRefreshDio({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: refreshTimeout,
        receiveTimeout: refreshTimeout,
        sendTimeout: refreshTimeout,
        headers: {
          'Accept': 'application/json',
        },
        contentType: 'application/json',
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }

    return dio;
  }
}
