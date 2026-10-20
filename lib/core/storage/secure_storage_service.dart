import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  String? _cachedToken;
  String? _cachedRefreshToken;
  bool _tokenLoaded = false;
  bool _refreshTokenLoaded = false;

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _cachedToken = token;
    _tokenLoaded = true;
  }

  Future<String?> getToken() async {
    if (_tokenLoaded) {
      return _cachedToken;
    }
    try {
      final token = await _storage.read(key: _tokenKey);
      _cachedToken = token;
      _tokenLoaded = true;
      return token;
    } catch (_) {
      // In case of hardware key corruption or Keystore error, safely reset cache
      _cachedToken = null;
      _tokenLoaded = true;
      return null;
    }
  }

  Future<void> deleteToken() async {
    _cachedToken = null;
    _tokenLoaded = true;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    _cachedRefreshToken = token;
    _refreshTokenLoaded = true;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshTokenLoaded) {
      return _cachedRefreshToken;
    }
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      _cachedRefreshToken = token;
      _refreshTokenLoaded = true;
      return token;
    } catch (_) {
      _cachedRefreshToken = null;
      _refreshTokenLoaded = true;
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    _cachedRefreshToken = null;
    _refreshTokenLoaded = true;
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<void> clearTokens() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _tokenLoaded = true;
    _refreshTokenLoaded = true;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }
}

