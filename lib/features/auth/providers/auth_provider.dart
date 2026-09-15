import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../models/customer.dart';

part 'auth_provider.g.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

@riverpod
class AuthState extends _$AuthState {
  late final AuthRepository _authRepository;
  late final SecureStorageService _secureStorageService;

  @override
  FutureOr<Customer?> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    _secureStorageService = ref.watch(secureStorageServiceProvider);

    final token = await _secureStorageService.getToken();
    if (token != null) {
      try {
        return await _authRepository.getProfile();
      } catch (e) {
        await _secureStorageService.deleteToken();
        return null;
      }
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _authRepository.login(email: email, password: password);
      final token = response['token'] ?? response['data']?['token'];
      if (token != null) {
        final tokenStr = token as String;
        await _secureStorageService.saveTokens(
          accessToken: tokenStr,
          refreshToken: tokenStr,
        );
        return await _authRepository.getProfile();
      }
      throw Exception('Login failed: Token not found in response');
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      final token = response['token'] ?? response['data']?['token'];
      if (token != null) {
        final tokenStr = token as String;
        await _secureStorageService.saveTokens(
          accessToken: tokenStr,
          refreshToken: tokenStr,
        );
        return await _authRepository.getProfile();
      }
      throw Exception('Registration failed: Token not found in response');
    });
  }

  Future<Customer> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    final updatedCustomer = await _authRepository.updateProfile(
      name: name,
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );
    state = AsyncValue.data(updatedCustomer);
    return updatedCustomer;
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _authRepository.logout();
      } catch (_) {
        // Continue logout even if server fails
      } finally {
        await _secureStorageService.deleteToken();
      }
      return null;
    });
  }
}
