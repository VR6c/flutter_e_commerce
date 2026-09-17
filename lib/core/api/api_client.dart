import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_response.dart';
import 'app_exception.dart';
import 'dio_client.dart';
import 'interceptors/auth_interceptor.dart';
import 'pagination/paginated_response.dart';

class ApiClient {
  static const String baseUrl = ApiEndpoints.baseUrl;

  final Dio dio;
  final SecureStorageService? _storageService;

  ApiClient(this.dio, [this._storageService]) {
    dio.options.baseUrl = dio.options.baseUrl.isNotEmpty
        ? dio.options.baseUrl
        : baseUrl;
    dio.options.connectTimeout ??= const Duration(seconds: 30);
    dio.options.receiveTimeout ??= const Duration(seconds: 30);
    dio.options.sendTimeout ??= const Duration(seconds: 30);
    dio.options.headers['Accept-Encoding'] ??= 'gzip, deflate';
    dio.options.headers['Accept'] ??= 'application/json';

    // Ensure AuthInterceptor is wired if storageService is provided and not yet registered
    if (_storageService != null) {
      final hasAuth = dio.interceptors.any((i) => i is AuthInterceptor);
      if (!hasAuth) {
        final refreshDio = DioClient.createRefreshDio(
          baseUrl: dio.options.baseUrl,
        );
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
  // Generic Core HTTP Methods returning Response<T>
  // ---------------------------------------------------------------------------

  /// Unified HTTP request method returning a [Response<T>].
  /// If [fromJson] is provided, parses the payload into [T] and stores it in [Response.data].
  /// If [fromJson] is null, returns raw [Response<T>] for full backwards compatibility with Dio.
  Future<Response<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
    bool unwrapData = true,
  }) async {
    try {
      final reqOptions = (options ?? Options()).copyWith(method: method);
      if (fromJson != null) {
        final response = await dio.request<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: reqOptions,
          cancelToken: cancelToken,
        );
        final parsed = _parseData<T>(
          response.data,
          fromJson,
          unwrapData: unwrapData,
        );
        return Response<T>(
          data: parsed,
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          isRedirect: response.isRedirect,
          redirects: response.redirects,
          extra: response.extra,
          headers: response.headers,
        );
      } else {
        return await dio.request<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: reqOptions,
          cancelToken: cancelToken,
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic GET request returning [Response<T>].
  /// If [fromJson] is provided, parses payload directly into [T].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
    bool unwrapData = true,
  }) {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJson: fromJson,
      unwrapData: unwrapData,
    );
  }

  /// Generic POST request returning [Response<T>].
  /// If [fromJson] is provided, parses payload directly into [T].
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
    bool unwrapData = true,
  }) {
    return request<T>(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJson: fromJson,
      unwrapData: unwrapData,
    );
  }

  /// Generic PUT request returning [Response<T>].
  /// If [fromJson] is provided, parses payload directly into [T].
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
    bool unwrapData = true,
  }) {
    return request<T>(
      path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJson: fromJson,
      unwrapData: unwrapData,
    );
  }

  /// Generic PATCH request returning [Response<T>].
  /// If [fromJson] is provided, parses payload directly into [T].
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
    bool unwrapData = true,
  }) {
    return request<T>(
      path,
      method: 'PATCH',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJson: fromJson,
      unwrapData: unwrapData,
    );
  }

  /// Generic DELETE request returning [Response<T>].
  /// If [fromJson] is provided, parses payload directly into [T].
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromJson,
    bool unwrapData = true,
  }) {
    return request<T>(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJson: fromJson,
      unwrapData: unwrapData,
    );
  }

  // ---------------------------------------------------------------------------
  // Generic Deserialized Model Methods (Returns Domain Model T directly)
  // ---------------------------------------------------------------------------

  /// Unified request method directly deserializing response payload into domain model [T].
  Future<T> requestModel<T>({
    required String path,
    required String method,
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) async {
    final response = await request<T>(
      path,
      method: method,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      fromJson: fromJson,
      unwrapData: unwrapData,
    );
    return response.data as T;
  }

  /// Performs a generic GET request and directly deserializes the response payload into [T].
  Future<T> getModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestModel<T>(
      path: path,
      method: 'GET',
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic POST request and directly deserializes the response payload into [T].
  Future<T> postModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestModel<T>(
      path: path,
      method: 'POST',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic PUT request and directly deserializes the response payload into [T].
  Future<T> putModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestModel<T>(
      path: path,
      method: 'PUT',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic PATCH request and directly deserializes the response payload into [T].
  Future<T> patchModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestModel<T>(
      path: path,
      method: 'PATCH',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic DELETE request and directly deserializes the response payload into [T].
  Future<T> deleteModel<T>(
    String path, {
    required T Function(dynamic data) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestModel<T>(
      path: path,
      method: 'DELETE',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  // ---------------------------------------------------------------------------
  // Generic List Methods (Returns List<T> directly)
  // ---------------------------------------------------------------------------

  /// Unified request method directly deserializing a list response payload into `List<T>`.
  Future<List<T>> requestList<T>({
    required String path,
    required String method,
    required T Function(dynamic item) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
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
      return _parseListData<T>(response.data, fromJson, unwrapData: unwrapData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs a generic GET request and deserializes the response into `List<T>`.
  Future<List<T>> getList<T>(
    String path, {
    required T Function(dynamic item) fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestList<T>(
      path: path,
      method: 'GET',
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic POST request and deserializes the response into `List<T>`.
  Future<List<T>> postList<T>(
    String path, {
    required T Function(dynamic item) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestList<T>(
      path: path,
      method: 'POST',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic PUT request and deserializes the response into `List<T>`.
  Future<List<T>> putList<T>(
    String path, {
    required T Function(dynamic item) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestList<T>(
      path: path,
      method: 'PUT',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic PATCH request and deserializes the response into `List<T>`.
  Future<List<T>> patchList<T>(
    String path, {
    required T Function(dynamic item) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestList<T>(
      path: path,
      method: 'PATCH',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  /// Performs a generic DELETE request and deserializes the response into `List<T>`.
  Future<List<T>> deleteList<T>(
    String path, {
    required T Function(dynamic item) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool unwrapData = true,
  }) {
    return requestList<T>(
      path: path,
      method: 'DELETE',
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      unwrapData: unwrapData,
    );
  }

  // ---------------------------------------------------------------------------
  // Generic ApiResponse Envelope Requests
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

  /// Performs a generic GET request and wraps the response in an [ApiResponse<T>].
  Future<ApiResponse<T>> getApiResponse<T>(
    String path, {
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestEnvelope<T>(
      path: path,
      method: 'GET',
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a generic POST request and wraps the response in an [ApiResponse<T>].
  Future<ApiResponse<T>> postApiResponse<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestEnvelope<T>(
      path: path,
      method: 'POST',
      data: data,
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a generic PUT request and wraps the response in an [ApiResponse<T>].
  Future<ApiResponse<T>> putApiResponse<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestEnvelope<T>(
      path: path,
      method: 'PUT',
      data: data,
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a generic PATCH request and wraps the response in an [ApiResponse<T>].
  Future<ApiResponse<T>> patchApiResponse<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestEnvelope<T>(
      path: path,
      method: 'PATCH',
      data: data,
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a generic DELETE request and wraps the response in an [ApiResponse<T>].
  Future<ApiResponse<T>> deleteApiResponse<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestEnvelope<T>(
      path: path,
      method: 'DELETE',
      data: data,
      fromJson: fromJson,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // Envelope convenience alias methods
  Future<ApiResponse<T>> getEnvelope<T>(
    String path, {
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => getApiResponse<T>(
    path,
    fromJson: fromJson,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> postEnvelope<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => postApiResponse<T>(
    path,
    data: data,
    fromJson: fromJson,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> putEnvelope<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => putApiResponse<T>(
    path,
    data: data,
    fromJson: fromJson,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> patchEnvelope<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => patchApiResponse<T>(
    path,
    data: data,
    fromJson: fromJson,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> deleteEnvelope<T>(
    String path, {
    dynamic data,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => deleteApiResponse<T>(
    path,
    data: data,
    fromJson: fromJson,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

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
  // Parsers & Error Mapping
  // ---------------------------------------------------------------------------

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

  List<T> _parseListData<T>(
    dynamic rawData,
    T Function(dynamic item) fromJson, {
    bool unwrapData = true,
  }) {
    try {
      dynamic target = rawData;
      if (unwrapData &&
          rawData is Map<String, dynamic> &&
          rawData.containsKey('data')) {
        target = rawData['data'];
      }
      if (target is! List) {
        throw ParseException(
          message:
              'Expected List in response payload for List<${T.toString()}>, got ${target.runtimeType}',
          originalData: rawData,
        );
      }
      return target.map((item) => fromJson(item)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(
        message: 'Failed to parse List<${T.toString()}>: $e',
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
