import 'package:dio/dio.dart';

class AuthService {
  final Dio dio;

  AuthService(this.dio);

  // 1. Request OTP
  Future<Response> forgotPassword(String email) async {
    return await dio.post('/password/forgot', data: {'email': email.trim()});
  }

  // 2. Verify OTP code
  Future<Response> verifyOtp(String email, String otp) async {
    return await dio.post('/password/verify-otp', data: {
      'email': email.trim(),
      'otp': otp.trim(),
    });
  }

  // 3. Resend OTP code
  Future<Response> resendOtp(String email) async {
    return await dio.post('/password/resend-otp', data: {'email': email.trim()});
  }

  // 4. Reset Password
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await dio.post('/password/reset', data: {
      'email': email.trim(),
      'otp': otp.trim(),
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }
}
