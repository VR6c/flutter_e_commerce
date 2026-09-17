import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';
import 'package:flutter_e_commerce/core/api/app_exception.dart';
import 'package:flutter_e_commerce/core/storage/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeDioException extends Fake implements DioException {}

class MockHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  MockHttpAdapter([this.handler]);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      jsonEncode({'data': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class TestItem {
  final int id;
  final String name;

  TestItem({required this.id, required this.name});

  factory TestItem.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return TestItem(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
  });

  late Dio dio;
  late MockSecureStorageService mockStorageService;
  late MockHttpAdapter mockAdapter;
  late ApiClient apiClient;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    mockAdapter = MockHttpAdapter();
    dio.httpClientAdapter = mockAdapter;
    mockStorageService = MockSecureStorageService();
    when(() => mockStorageService.getToken()).thenAnswer((_) async => null);
    apiClient = ApiClient(dio, mockStorageService);
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
      when(() => mockStorageService.getRefreshToken()).thenAnswer((_) async => null);
      when(() => mockStorageService.deleteToken()).thenAnswer((_) async => {});
      when(() => mockStorageService.clearTokens()).thenAnswer((_) async => {});

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

      verify(() => mockStorageService.clearTokens()).called(1);
      verify(() => handler.next(dioException)).called(1);
    });
  });

  group('Generic Core HTTP Methods (get, post, put, patch, delete)', () {
    test('get<T> with fromJson parses data into Response<T>', () async {
      mockAdapter.handler = (options) {
        expect(options.method, 'GET');
        expect(options.path, '/items/1');
        return ResponseBody.fromString(
          jsonEncode({'data': {'id': 1, 'name': 'Item 1'}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final response = await apiClient.get<TestItem>(
        '/items/1',
        fromJson: TestItem.fromJson,
      );

      expect(response.statusCode, 200);
      expect(response.data, isA<TestItem>());
      expect(response.data?.id, 1);
      expect(response.data?.name, 'Item 1');
    });

    test('get<T> without fromJson returns raw Response<T> (backwards-compatible)', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'data': {'id': 1, 'name': 'Item 1'}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final response = await apiClient.get('/items/1');
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data['data']['name'], 'Item 1');
    });

    test('post<T>, put<T>, patch<T>, delete<T> with fromJson', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'data': {'id': 10, 'name': options.method}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final postRes = await apiClient.post<TestItem>(
        '/items',
        data: {'name': 'POST'},
        fromJson: TestItem.fromJson,
      );
      expect(postRes.data?.name, 'POST');

      final putRes = await apiClient.put<TestItem>(
        '/items/10',
        data: {'name': 'PUT'},
        fromJson: TestItem.fromJson,
      );
      expect(putRes.data?.name, 'PUT');

      final patchRes = await apiClient.patch<TestItem>(
        '/items/10',
        data: {'name': 'PATCH'},
        fromJson: TestItem.fromJson,
      );
      expect(patchRes.data?.name, 'PATCH');

      final deleteRes = await apiClient.delete<TestItem>(
        '/items/10',
        fromJson: TestItem.fromJson,
      );
      expect(deleteRes.data?.name, 'DELETE');
    });
  });

  group('Generic Direct Model Methods (getModel, postModel, putModel, patchModel, deleteModel)', () {
    test('getModel returns deserialized model directly', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'data': {'id': 2, 'name': 'Direct Model'}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final item = await apiClient.getModel<TestItem>(
        '/items/2',
        fromJson: TestItem.fromJson,
      );

      expect(item.id, 2);
      expect(item.name, 'Direct Model');
    });

    test('postModel, putModel, patchModel, deleteModel return model directly', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'data': {'id': 99, 'name': '${options.method} Item'}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final postItem = await apiClient.postModel<TestItem>(
        '/items',
        fromJson: TestItem.fromJson,
      );
      expect(postItem.name, 'POST Item');

      final putItem = await apiClient.putModel<TestItem>(
        '/items/99',
        fromJson: TestItem.fromJson,
      );
      expect(putItem.name, 'PUT Item');

      final patchItem = await apiClient.patchModel<TestItem>(
        '/items/99',
        fromJson: TestItem.fromJson,
      );
      expect(patchItem.name, 'PATCH Item');

      final deleteItem = await apiClient.deleteModel<TestItem>(
        '/items/99',
        fromJson: TestItem.fromJson,
      );
      expect(deleteItem.name, 'DELETE Item');
    });
  });

  group('Generic List Methods (getList, postList, putList, patchList, deleteList)', () {
    test('getList deserializes wrapped list response', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {'id': 1, 'name': 'First'},
              {'id': 2, 'name': 'Second'},
            ]
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final list = await apiClient.getList<TestItem>(
        '/items',
        fromJson: TestItem.fromJson,
      );

      expect(list.length, 2);
      expect(list.first.name, 'First');
      expect(list.last.name, 'Second');
    });

    test('getList deserializes flat list response when unwrapData is false', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode([
            {'id': 10, 'name': 'Item 10'},
          ]),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final list = await apiClient.getList<TestItem>(
        '/items',
        fromJson: TestItem.fromJson,
        unwrapData: false,
      );

      expect(list.length, 1);
      expect(list.first.name, 'Item 10');
    });

    test('postList, putList, patchList, deleteList return List<T>', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {'id': 1, 'name': options.method},
            ]
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final postList = await apiClient.postList<TestItem>(
        '/items/batch',
        fromJson: TestItem.fromJson,
      );
      expect(postList.first.name, 'POST');

      final putList = await apiClient.putList<TestItem>(
        '/items/batch',
        fromJson: TestItem.fromJson,
      );
      expect(putList.first.name, 'PUT');

      final patchList = await apiClient.patchList<TestItem>(
        '/items/batch',
        fromJson: TestItem.fromJson,
      );
      expect(patchList.first.name, 'PATCH');

      final deleteList = await apiClient.deleteList<TestItem>(
        '/items/batch',
        fromJson: TestItem.fromJson,
      );
      expect(deleteList.first.name, 'DELETE');
    });

    test('throws ParseException when list response is not a list', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'data': 'Not A List'}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      expect(
        () => apiClient.getList<TestItem>('/items', fromJson: TestItem.fromJson),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('Generic Envelope Methods (getApiResponse, postApiResponse, etc.)', () {
    test('getApiResponse parses success envelope with model', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': 'Operation successful',
            'data': {'id': 5, 'name': 'Envelope Item'},
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final envelope = await apiClient.getApiResponse<TestItem>(
        '/items/5',
        fromJson: TestItem.fromJson,
      );

      expect(envelope.isSuccess, isTrue);
      expect(envelope.message, 'Operation successful');
      expect(envelope.data?.name, 'Envelope Item');
    });

    test('envelope aliases (getEnvelope, postEnvelope, etc.) match ApiResponse methods', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': '${options.method} success',
            'data': {'id': 7, 'name': 'Alias Item'},
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      final getEnv = await apiClient.getEnvelope<TestItem>(
        '/items/7',
        fromJson: TestItem.fromJson,
      );
      expect(getEnv.isSuccess, isTrue);

      final postEnv = await apiClient.postEnvelope<TestItem>(
        '/items',
        fromJson: TestItem.fromJson,
      );
      expect(postEnv.message, 'POST success');

      final putEnv = await apiClient.putEnvelope<TestItem>(
        '/items/7',
        fromJson: TestItem.fromJson,
      );
      expect(putEnv.message, 'PUT success');

      final patchEnv = await apiClient.patchEnvelope<TestItem>(
        '/items/7',
        fromJson: TestItem.fromJson,
      );
      expect(patchEnv.message, 'PATCH success');

      final deleteEnv = await apiClient.deleteEnvelope<TestItem>(
        '/items/7',
        fromJson: TestItem.fromJson,
      );
      expect(deleteEnv.message, 'DELETE success');
    });
  });

  group('Error Handling', () {
    test('throws ParseException when parsing fails', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'data': {'id': 'NOT_AN_INT', 'name': 'Bad'}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      };

      expect(
        () => apiClient.getModel<TestItem>('/bad', fromJson: TestItem.fromJson),
        throwsA(isA<ParseException>()),
      );
    });
  });
}
