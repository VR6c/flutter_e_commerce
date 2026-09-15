import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const AppException({required this.message, this.statusCode, this.errors});

  factory AppException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.cancel:
        return const CancelException(
          message: 'Request to API server was cancelled',
        );

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(message: _getTimeoutMessage(dioException.type));

      case DioExceptionType.connectionError:
        return const NetworkException(
          message:
              'No internet connection. Please check your network settings.',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(dioException.response);

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Security certificate verification failed',
        );

      case DioExceptionType.unknown:
      default:
        if (dioException.error != null &&
            dioException.error.toString().contains('SocketException')) {
          return const NetworkException(
            message:
                'No internet connection. Please check your network settings.',
          );
        }
        return UnexpectedException(
          message: dioException.message ?? 'An unexpected error occurred',
        );
    }
  }

  static AppException _handleBadResponse(Response? response) {
    if (response == null) {
      return const UnexpectedException(
        message: 'Empty response received from server',
      );
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = 'Server returned status code $statusCode';
    Map<String, dynamic>? rawErrors;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('errors') && data['errors'] is Map) {
        rawErrors = data['errors'] as Map<String, dynamic>;
      }
      message =
          data['message']?.toString() ??
          data['error']?.toString() ??
          'Server error occurred';
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message: message, errors: rawErrors);
      case 401:
        return UnauthorizedException(message: message, errors: rawErrors);
      case 403:
        return ForbiddenException(message: message, errors: rawErrors);
      case 404:
        return NotFoundException(message: message, errors: rawErrors);
      case 422:
        return ValidationException(message: message, rawErrors: rawErrors);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: message,
          statusCode: statusCode,
          errors: rawErrors,
        );
      default:
        return AppException(
          message: message,
          statusCode: statusCode,
          errors: rawErrors,
        );
    }
  }

  static String _getTimeoutMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout with API server';
      case DioExceptionType.sendTimeout:
        return 'Send timeout in connection with API server';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout in connection with API server';
      default:
        return 'Network request timed out';
    }
  }

  @override
  String toString() => message;
}

/// Thrown when device has no connectivity or network is unreachable.
class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode = 0});
}

/// Thrown on connection, send, or receive timeout.
class TimeoutException extends AppException {
  const TimeoutException({required super.message, super.statusCode = 408});
}

/// Thrown on 401 Unauthorized (invalid or expired token).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.statusCode = 401,
    super.errors,
  });
}

/// Thrown on 403 Forbidden (insufficient permissions).
class ForbiddenException extends AppException {
  const ForbiddenException({
    required super.message,
    super.statusCode = 403,
    super.errors,
  });
}

/// Thrown on 404 Not Found.
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
    super.errors,
  });
}

/// Thrown on 400 Bad Request.
class BadRequestException extends AppException {
  const BadRequestException({
    required super.message,
    super.statusCode = 400,
    super.errors,
  });
}

/// Thrown on 422 Unprocessable Entity (Laravel form validation errors).
class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  ValidationException({required super.message, Map<String, dynamic>? rawErrors})
    : fieldErrors = _normalizeValidationErrors(rawErrors),
      super(statusCode: 422, errors: rawErrors);

  /// Returns the first error message across all fields, useful for a quick banner/toast.
  String? get firstError {
    for (final messages in fieldErrors.values) {
      if (messages.isNotEmpty) {
        return messages.first;
      }
    }
    return message;
  }

  /// Extracts the first error for a specific field name, e.g. `getError('email')`.
  String? getFieldError(String fieldName) {
    return fieldErrors[fieldName]?.firstOrNull;
  }

  static Map<String, List<String>> _normalizeValidationErrors(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null) return {};
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        result[key] = [value];
      }
    });
    return result;
  }
}

/// Thrown on 5xx Internal Server Error.
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.errors,
  });
}

/// Thrown when client cancels the HTTP request.
class CancelException extends AppException {
  const CancelException({required super.message, super.statusCode});
}

/// Thrown when deserializing response JSON fails.
class ParseException extends AppException {
  final dynamic originalData;

  const ParseException({required super.message, this.originalData})
    : super(statusCode: -1);
}

/// Thrown when an unexpected error occurs.
class UnexpectedException extends AppException {
  const UnexpectedException({
    required super.message,
    super.statusCode,
    super.errors,
  });
}
