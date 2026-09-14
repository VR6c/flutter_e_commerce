import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';
import 'package:flutter_e_commerce/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeDioException extends Fake implements DioException {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
  });

  late Dio dio;
  late MockSecureStorageService mockStorageService;

  setUp(() {
    dio = Dio();
    mockStorageService = MockSecureStorageService();
    ApiClient(dio, mockStorageService);
  });

  group('ApiClient Interceptors', () {
    test('onRequest adds Authorization header when token is present', () async {
      const token = 'test-token';
      when(() => mockStorageService.getToken()).thenAnswer((_) async => token);

      final interceptor = dio.interceptors.last;
      final options = RequestOptions(path: '/test');
      final handler = MockRequestInterceptorHandler();

      final completer = Completer<void>();
      when(() => handler.next(any())).thenAnswer((_) {
        completer.complete();
      });

      interceptor.onRequest(options, handler);
      
      await completer.future;

      expect(options.headers['Authorization'], 'Bearer $token');
      verify(() => handler.next(options)).called(1);
    });

    test('onRequest does not add Authorization header when token is null', () async {
      when(() => mockStorageService.getToken()).thenAnswer((_) async => null);

      final interceptor = dio.interceptors.last;
      final options = RequestOptions(path: '/test');
      final handler = MockRequestInterceptorHandler();

      final completer = Completer<void>();
      when(() => handler.next(any())).thenAnswer((_) {
        completer.complete();
      });

      interceptor.onRequest(options, handler);

      await completer.future;

      expect(options.headers.containsKey('Authorization'), false);
      verify(() => handler.next(options)).called(1);
    });

    test('onError deletes token when status is 401', () async {
      when(() => mockStorageService.deleteToken()).thenAnswer((_) async => {});

      final interceptor = dio.interceptors.last;
      final requestOptions = RequestOptions(path: '/test');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = MockErrorInterceptorHandler();

      final completer = Completer<void>();
      when(() => handler.next(any())).thenAnswer((_) {
        completer.complete();
      });

      interceptor.onError(dioException, handler);

      await completer.future;

      verify(() => mockStorageService.deleteToken()).called(1);
      verify(() => handler.next(dioException)).called(1);
    });
  });
}
