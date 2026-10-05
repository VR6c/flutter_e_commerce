import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:flutter_e_commerce/features/auth/data/auth_repository.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AuthRepository authRepository;

  setUp(() {
    mockApiClient = MockApiClient();
    authRepository = AuthRepository(mockApiClient);
  });

  group('AuthRepository', () {
    test('login returns response data on success', () async {
      final successData = {
        'status': true,
        'token': 'jwt_token',
        'customer': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com', 'status': 'active'}
      };

      when(() => mockApiClient.post<dynamic>(
            '/customer/login',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/customer/login'),
            data: successData,
            statusCode: 200,
          ));

      final result = await authRepository.login(
        email: 'john@example.com',
        password: 'password123',
      );

      expect(result['token'], 'jwt_token');
      expect(result['status'], true);
    });

    test('register returns response data on success', () async {
      final successData = {
        'status': true,
        'token': 'jwt_token',
        'customer': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com', 'status': 'active'}
      };

      when(() => mockApiClient.post<dynamic>(
            '/customer/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/customer/register'),
            data: successData,
            statusCode: 200,
          ));

      final result = await authRepository.register(
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(result['token'], 'jwt_token');
      expect(result['status'], true);
    });

    test('getProfile returns Customer object on success', () async {
      final profileData = {
        'status': true,
        'data': {'id': 1, 'name': 'John Doe', 'email': 'john@example.com', 'status': 'active'}
      };

      when(() => mockApiClient.get<dynamic>('/customer/profile'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/customer/profile'),
                data: profileData,
                statusCode: 200,
              ));

      final result = await authRepository.getProfile();

      expect(result.id, 1);
      expect(result.name, 'John Doe');
      expect(result.email, 'john@example.com');
      expect(result.status, 'active');
    });

    test('logout makes post request to server', () async {
      when(() => mockApiClient.post<dynamic>('/customer/logout'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/customer/logout'),
                statusCode: 200,
              ));

      await authRepository.logout();

      verify(() => mockApiClient.post<dynamic>('/customer/logout')).called(1);
    });

    test('forgotPassword sends email to /password/forgot', () async {
      when(() => mockApiClient.post<dynamic>(
            '/password/forgot',
            data: {'email': 'test@example.com'},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/password/forgot'),
            data: {'status': true, 'message': 'Code sent'},
            statusCode: 200,
          ));

      final result = await authRepository.forgotPassword('test@example.com');
      expect(result['status'], true);
    });

    test('verifyOtp sends email and otp to /password/verify-otp', () async {
      when(() => mockApiClient.post<dynamic>(
            '/password/verify-otp',
            data: {'email': 'test@example.com', 'otp': '123456'},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/password/verify-otp'),
            data: {'status': true, 'message': 'Verified'},
            statusCode: 200,
          ));

      final result = await authRepository.verifyOtp(
        email: 'test@example.com',
        otp: '123456',
      );
      expect(result['status'], true);
    });

    test('resendOtp sends email to /password/resend-otp', () async {
      when(() => mockApiClient.post<dynamic>(
            '/password/resend-otp',
            data: {'email': 'test@example.com'},
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/password/resend-otp'),
            data: {'status': true, 'message': 'Resent'},
            statusCode: 200,
          ));

      final result = await authRepository.resendOtp('test@example.com');
      expect(result['status'], true);
    });

    test('resetPassword sends email, otp and new password to /password/reset', () async {
      when(() => mockApiClient.post<dynamic>(
            '/password/reset',
            data: {
              'email': 'test@example.com',
              'otp': '123456',
              'password': 'newpassword123',
              'password_confirmation': 'newpassword123',
            },
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/password/reset'),
            data: {
              'status': true,
              'token': 'new_token',
              'customer': {'id': 1, 'name': 'John', 'email': 'test@example.com'}
            },
            statusCode: 200,
          ));

      final result = await authRepository.resetPassword(
        email: 'test@example.com',
        otp: '123456',
        password: 'newpassword123',
        passwordConfirmation: 'newpassword123',
      );
      expect(result['token'], 'new_token');
      expect(result['status'], true);
    });
  });
}
