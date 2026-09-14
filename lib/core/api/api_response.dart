/// Standard wrapper for backend API responses.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.meta,
  });

  /// True if the response indicates success
  bool get isSuccess => success;

  /// Creates an ApiResponse by inspecting common Laravel/REST response shapes:
  /// - `{ "success": true, "message": "...", "data": ... }`
  /// - `{ "status": "success", "message": "...", "data": ... }`
  /// - Direct data without wrapper
  factory ApiResponse.fromJson(
    dynamic json,
    T Function(dynamic data)? fromJsonT,
  ) {
    if (json is! Map<String, dynamic>) {
      final parsedData = fromJsonT != null ? fromJsonT(json) : json as T?;
      return ApiResponse(
        success: true,
        data: parsedData,
      );
    }

    final hasSuccessKey = json.containsKey('success');
    final hasStatusKey = json.containsKey('status');

    bool isSuccess = true;
    if (hasSuccessKey) {
      isSuccess = json['success'] == true;
    } else if (hasStatusKey) {
      isSuccess = json['status'] == 'success' || json['status'] == 200 || json['status'] == true;
    }

    final message = json['message']?.toString();
    final meta = json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic> : null;

    final rawData = json.containsKey('data') ? json['data'] : json;
    final parsedData = (rawData != null && fromJsonT != null)
        ? fromJsonT(rawData)
        : (rawData is T? ? rawData : null);

    return ApiResponse<T>(
      success: isSuccess,
      message: message,
      data: parsedData,
      meta: meta,
    );
  }
}
