import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/storage/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService secureStorageService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorageService = SecureStorageService(mockStorage);
  });

  group('SecureStorageService', () {
    const tokenKey = 'auth_token';
    const tokenVal = 'my_jwt_token';

    test('saveToken writes token to storage', () async {
      when(() => mockStorage.write(key: tokenKey, value: tokenVal))
          .thenAnswer((_) async => {});

      await secureStorageService.saveToken(tokenVal);

      verify(() => mockStorage.write(key: tokenKey, value: tokenVal)).called(1);
    });

    test('getToken reads token from storage', () async {
      when(() => mockStorage.read(key: tokenKey))
          .thenAnswer((_) async => tokenVal);

      final result = await secureStorageService.getToken();

      expect(result, tokenVal);
      verify(() => mockStorage.read(key: tokenKey)).called(1);
    });

    test('deleteToken deletes token from storage', () async {
      when(() => mockStorage.delete(key: tokenKey))
          .thenAnswer((_) async => {});

      await secureStorageService.deleteToken();

      verify(() => mockStorage.delete(key: tokenKey)).called(1);
    });

    test('getToken returns null safely when storage throws an exception', () async {
      when(() => mockStorage.read(key: tokenKey))
          .thenThrow(Exception('Keystore corrupted'));

      final result = await secureStorageService.getToken();

      expect(result, isNull);
    });

    test('saveToken propagates error if write fails without updating cache', () async {
      when(() => mockStorage.write(key: tokenKey, value: tokenVal))
          .thenThrow(Exception('Write failed'));
      when(() => mockStorage.read(key: tokenKey))
          .thenAnswer((_) async => null);

      expect(
        () => secureStorageService.saveToken(tokenVal),
        throwsA(isA<Exception>()),
      );

      // Verify that cache was not updated with the failed token
      final cached = await secureStorageService.getToken();
      expect(cached, isNull);
    });

    test('clearTokens removes both access and refresh tokens', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      await secureStorageService.clearTokens();

      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });
}
