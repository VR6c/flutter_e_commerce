import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/secure_storage_service.dart';
import 'api_client.dart';
import 'dio_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
});

final dioProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return DioClient.createDio(
    storageService: storageService,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return ApiClient(dio, storageService);
});
