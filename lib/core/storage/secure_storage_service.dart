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
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_tokenLoaded) {
      return _cachedToken;
    }
    final token = await _storage.read(key: _tokenKey);
    _cachedToken = token;
    _tokenLoaded = true;
    return token;
  }

  Future<void> deleteToken() async {
    _cachedToken = null;
    _tokenLoaded = true;
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    _refreshTokenLoaded = true;
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    if (_refreshTokenLoaded) {
      return _cachedRefreshToken;
    }
    final token = await _storage.read(key: _refreshTokenKey);
    _cachedRefreshToken = token;
    _refreshTokenLoaded = true;
    return token;
  }

  Future<void> deleteRefreshToken() async {
    _cachedRefreshToken = null;
    _refreshTokenLoaded = true;
    await _storage.delete(key: _refreshTokenKey);
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
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

