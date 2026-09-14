import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_response.dart';
import 'app_exception.dart';
import 'dio_client.dart';
import 'interceptors/auth_interceptor.dart';
import 'pagination/paginated_response.dart';

/// Highly reusable, type-safe API Client wrapping Dio.
/// Supports generic deserialization, pagination, standard error mapping, and token refresh.
class ApiClient {
  static const String baseUrl = ApiEndpoints.baseUrl;

  final Dio dio;
  final SecureStorageService? _storageService;

  ApiClient(this.dio, [this._storageService]) {
    dio.options.baseUrl =
        dio.options.baseUrl.isNotEmpty ? dio.options.baseUrl : baseUrl;
    dio.options.connectTimeout ??= const Duration(seconds: 30);
    dio.options.receiveTimeout ??= const Duration(seconds: 30);
    dio.options.sendTimeout ??= const Duration(seconds: 30);
    dio.options.headers['Accept-Encoding'] ??= 'gzip, deflate';
    dio.options.headers['Accept'] ??= 'application/json';

    // Ensure AuthInterceptor is wired if storageService is provided and not yet registered
    if (_storageService != null) {
      final hasAuth = dio.interceptors.any((i) => i is AuthInterceptor);
      if (!hasAuth) {
        final refreshDio =
            DioClient.createRefreshDio(baseUrl: dio.options.baseUrl);
        dio.interceptors.add(
          AuthInterceptor(
            storageService: _storageService,
            dio: dio,
            refreshDio: refreshDio,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Core HTTP Methods returning Response<T> (100% backwards-compatible with Dio)
  // ---------------------------------------------------------------------------

  /// Standard GET request returning [Response<T>].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Standard POST request returning [Response<T>].
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Standard PUT request returning [Response<T>].
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Standard PATCH request returning [Response<T>].
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Standard DELETE request returning [Response<T>].
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Generic Deserialized Model Methods (Automatically parses into Domain Models)
  // ---------------------------------------------------------------------------

  /// Performs a GET request and directly deserializes the response payload into [T].
  Future<T> getModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) async {
    final response = await get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _parseData<T>(response.data, fromJson, unwrapData: unwrapData);
  }

  /// Performs a POST request and directly deserializes the response payload into [T].
  Future<T> postModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) async {
    final response = await post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _parseData<T>(response.data, fromJson, unwrapData: unwrapData);
  }

  /// Performs a PUT request and directly deserializes the response payload into [T].
  Future<T> putModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) async {
    final response = await put<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _parseData<T>(response.data, fromJson, unwrapData: unwrapData);
  }

  /// Performs a PATCH request and directly deserializes the response payload into [T].
  Future<T> patchModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) async {
    final response = await patch<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _parseData<T>(response.data, fromJson, unwrapData: unwrapData);
  }

  /// Performs a DELETE request and directly deserializes the response payload into [T].
  Future<T> deleteModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) async {
    final response = await delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _parseData<T>(response.data, fromJson, unwrapData: unwrapData);
  }

  // ---------------------------------------------------------------------------
  // Generic Pagination
  // ---------------------------------------------------------------------------

  /// Fetches paginated data and deserializes it directly into a [PaginatedResponse<T>].
  Future<PaginatedResponse<T>> getPaginated<T>(
    String path, {
    required T Function(dynamic item) fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return PaginatedResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(
        message: 'Failed to parse paginated response of ${T.toString()}: $e',
        originalData: null,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Envelope & Raw Requests
  // ---------------------------------------------------------------------------

  /// Unified request method returning an [ApiResponse<T>] wrapper.
  Future<ApiResponse<T>> requestEnvelope<T>({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final reqOptions = (options ?? Options()).copyWith(method: method);
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: reqOptions,
        cancelToken: cancelToken,
      );
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  T _parseData<T>(
    dynamic rawData,
    T Function(dynamic) fromJson, {
    bool unwrapData = true,
  }) {
    try {
      dynamic target = rawData;
      if (unwrapData &&
          rawData is Map<String, dynamic> &&
          rawData.containsKey('data')) {
        target = rawData['data'];
      }
      return fromJson(target);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(
        message: 'Failed to parse ${T.toString()}: $e',
        originalData: rawData,
      );
    }
  }

  AppException _handleError(DioException e) {
    if (e.error is AppException) {
      return e.error as AppException;
    }
    return AppException.fromDioException(e);
  }
}
