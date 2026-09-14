import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/api/api_endpoints.dart';
import 'package:flutter_e_commerce/core/api/api_response.dart';
import 'package:flutter_e_commerce/core/api/app_exception.dart';
import 'package:flutter_e_commerce/core/api/interceptors/auth_interceptor.dart';
import 'package:flutter_e_commerce/core/api/pagination/paginated_response.dart';
import 'package:flutter_e_commerce/core/storage/secure_storage_service.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}
class FakeRequestOptions extends Fake implements RequestOptions {}

class DummyItem {
  final int id;
  final String name;

  DummyItem({required this.id, required this.name});

  factory DummyItem.fromJson(Map<String, dynamic> json) {
    return DummyItem(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  group('Pagination Parsing', () {
    test('parses Laravel nested meta format correctly', () {
      final payload = {
        'data': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'meta': {
          'current_page': 1,
          'last_page': 5,
          'per_page': 2,
          'total': 10,
        },
      };

      final response = PaginatedResponse<DummyItem>.fromJson(
        payload,
        (item) => DummyItem.fromJson(item as Map<String, dynamic>),
      );

      expect(response.items.length, 2);
      expect(response.items.first.name, 'Item 1');
      expect(response.currentPage, 1);
      expect(response.lastPage, 5);
      expect(response.total, 10);
      expect(response.hasMore, isTrue);
      expect(response.nextPage, 2);
    });

    test('parses Laravel flat pagination format correctly', () {
      final payload = {
        'data': [
          {'id': 10, 'name': 'Item 10'},
        ],
        'current_page': 3,
        'last_page': 3,
        'per_page': 15,
        'total': 31,
      };

      final response = PaginatedResponse<DummyItem>.fromJson(
        payload,
        (item) => DummyItem.fromJson(item as Map<String, dynamic>),
      );

      expect(response.items.length, 1);
      expect(response.currentPage, 3);
      expect(response.lastPage, 3);
      expect(response.hasMore, isFalse);
    });
  });

  group('AppException & Validation Parsing', () {
    test('maps 422 to ValidationException and parses fieldErrors correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/register'),
          statusCode: 422,
          data: {
            'message': 'The given data was invalid.',
            'errors': {
              'email': ['The email has already been taken.'],
              'password': [
                'Password too short.',
                'Password must contain a symbol.',
              ],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = AppException.fromDioException(dioException);

      expect(exception, isA<ValidationException>());
      final valEx = exception as ValidationException;
      expect(valEx.message, 'The given data was invalid.');
      expect(valEx.fieldErrors['email'], ['The email has already been taken.']);
      expect(valEx.fieldErrors['password']?.length, 2);
      expect(valEx.firstError, 'The email has already been taken.');
      expect(valEx.getFieldError('email'), 'The email has already been taken.');
      expect(valEx.getFieldError('password'), 'Password too short.');
    });

    test('maps 401 to UnauthorizedException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/profile'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 401,
          data: {'message': 'Unauthenticated.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = AppException.fromDioException(dioException);
      expect(exception, isA<UnauthorizedException>());
      expect(exception.message, 'Unauthenticated.');
    });

    test('maps connectionError to NetworkException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError,
      );

      final exception = AppException.fromDioException(dioException);
      expect(exception, isA<NetworkException>());
    });
  });

  group('ApiResponse Envelope', () {
    test('parses success envelope correctly', () {
      final json = {
        'success': true,
        'message': 'Loaded successfully',
        'data': {'id': 1, 'name': 'Sample'},
      };

      final apiRes = ApiResponse<DummyItem>.fromJson(
        json,
        (data) => DummyItem.fromJson(data as Map<String, dynamic>),
      );

      expect(apiRes.isSuccess, isTrue);
      expect(apiRes.message, 'Loaded successfully');
      expect(apiRes.data?.name, 'Sample');
    });
  });

  group('AuthInterceptor Refresh Flow', () {
    test('does not attempt refresh on auth endpoints (login, register)', () async {
      final mockStorage = MockSecureStorageService();
      final mockMainDio = MockDio();
      final mockRefreshDio = MockDio();

      when(() => mockStorage.deleteToken()).thenAnswer((_) async {});
      when(() => mockStorage.deleteRefreshToken()).thenAnswer((_) async {});

      final interceptor = AuthInterceptor(
        storageService: mockStorage,
        dio: mockMainDio,
        refreshDio: mockRefreshDio,
      );

      final requestOptions = RequestOptions(path: ApiEndpoints.login);
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

      // Must NOT call refreshDio
      verifyNever(() => mockRefreshDio.post(any(), data: any(named: 'data')));
      verify(() => mockStorage.deleteToken()).called(1);
    });
  });
}
