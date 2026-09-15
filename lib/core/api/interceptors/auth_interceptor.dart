import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../storage/secure_storage_service.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _storageService;
  final Dio _dio;
  final Dio _refreshDio;
  final VoidCallback? onAuthFailed;

  AuthInterceptor({
    required SecureStorageService storageService,
    required Dio dio,
    required Dio refreshDio,
    this.onAuthFailed,
  }) : _storageService = storageService,
       _dio = dio,
       _refreshDio = refreshDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only attach authorization if not already provided explicitly
    if (!options.headers.containsKey('Authorization')) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // Handle 401 Unauthorized
    if (response?.statusCode == 401) {
      final requestPath = err.requestOptions.path;

      // Avoid infinite refresh loops if auth endpoints themselves failed with 401
      final isAuthEndpoint =
          requestPath.contains(ApiEndpoints.login) ||
          requestPath.contains(ApiEndpoints.register) ||
          requestPath.contains(ApiEndpoints.refreshToken) ||
          requestPath.contains('refresh');

      if (isAuthEndpoint) {
        await _handleAuthFailure();
        return handler.next(err);
      }

      // Check for available refresh token (or fallback to current token for Sanctum rotation)
      String? refreshToken;
      try {
        refreshToken = await _storageService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          refreshToken = await _storageService.getToken();
        }
      } catch (_) {
        refreshToken = null;
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        // No token available, session is expired
        await _handleAuthFailure();
        return handler.next(err);
      }

      // Attempt token refresh with header and body compatibility
      try {
        final refreshResponse = await _refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {
            'refresh_token': refreshToken,
            'token': refreshToken,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $refreshToken',
            },
          ),
        );

        final newTokens = _extractTokens(refreshResponse.data);
        if (newTokens != null) {
          final effectiveRefreshToken =
              newTokens.refreshToken ?? newTokens.accessToken;
          await _storageService.saveTokens(
            accessToken: newTokens.accessToken,
            refreshToken: effectiveRefreshToken,
          );

          // Update header and retry the original request
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] =
              'Bearer ${newTokens.accessToken}';

          final retryResponse = await _dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } else {
          await _handleAuthFailure();
          return handler.next(err);
        }
      } catch (refreshErr) {
        if (kDebugMode) {
          debugPrint('[AUTH INTERCEPTOR] Token refresh failed: $refreshErr');
        }
        await _handleAuthFailure();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<void> _handleAuthFailure() async {
    await _storageService.clearTokens();
    onAuthFailed?.call();
  }

  _TokenPair? _extractTokens(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;

    final accessToken =
        payload['token']?.toString() ??
        payload['access_token']?.toString() ??
        payload['jwt']?.toString();

    if (accessToken == null || accessToken.isEmpty) return null;

    final refreshToken = payload['refresh_token']?.toString();

    return _TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }
}

class _TokenPair {
  final String accessToken;
  final String? refreshToken;

  const _TokenPair({required this.accessToken, this.refreshToken});
}
