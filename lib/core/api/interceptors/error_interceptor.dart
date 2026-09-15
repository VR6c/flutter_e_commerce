import 'package:dio/dio.dart';
import '../app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = AppException.fromDioException(err);
    final enrichedException = err.copyWith(error: appException);
    return handler.next(enrichedException);
  }
}
