import 'dart:io';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/customer.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Customer> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final customerData = Map<String, dynamic>.from(
        (data['data'] ?? data['customer'] ?? data) as Map,
      );
      customerData['status'] ??= 'active';
      return Customer.fromJson(customerData);
    }
    throw Exception('Invalid profile response');
  }

  Future<Customer> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      payload['current_password'] = currentPassword;
      payload['new_password'] = newPassword;
      payload['new_password_confirmation'] = newPasswordConfirmation;
    }
    final response = await _apiClient.put(
      ApiEndpoints.profile,
      data: payload,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final customerData = Map<String, dynamic>.from(
        (data['customer'] ?? data['data'] ?? data) as Map,
      );
      customerData['status'] ??= 'active';
      return Customer.fromJson(customerData);
    }
    throw Exception('Invalid profile update response');
  }

  Future<Customer> uploadAvatar({
    required File imageFile,
    String avatarType = 'photo',
  }) async {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
      'avatar_type': avatarType,
    });

    final response = await _apiClient.post(
      ApiEndpoints.avatar,
      data: formData,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final customerData = Map<String, dynamic>.from(
        (data['data'] ?? data['customer'] ?? data) as Map,
      );
      customerData['status'] ??= 'active';
      return Customer.fromJson(customerData);
    }
    throw Exception('Invalid avatar upload response');
  }

  Future<Customer> deleteAvatar() async {
    final response = await _apiClient.delete(ApiEndpoints.avatar);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final customerData = Map<String, dynamic>.from(
        (data['data'] ?? data['customer'] ?? data) as Map,
      );
      customerData['status'] ??= 'active';
      return Customer.fromJson(customerData);
    }
    throw Exception('Invalid delete avatar response');
  }

  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.logout);
  }
}
