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
  });
}
