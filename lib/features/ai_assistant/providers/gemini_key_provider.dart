import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gemini_config.dart';

final geminiApiKeyProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, String>((ref) {
  return GeminiApiKeyNotifier();
});

class GeminiApiKeyNotifier extends StateNotifier<String> {
  static const _storageKey = GeminiConfig.storageKey;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  GeminiApiKeyNotifier() : super(GeminiConfig.fallbackApiKey) {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      // 1. Try secure storage first
      final secureKey = await _secureStorage.read(key: _storageKey);
      if (secureKey != null && secureKey.trim().isNotEmpty && !secureKey.startsWith('AQ.')) {
        state = secureKey.trim();
        return;
      }

      // 2. Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final prefsKey = prefs.getString(_storageKey);
      if (prefsKey != null && prefsKey.trim().isNotEmpty && !prefsKey.startsWith('AQ.')) {
        state = prefsKey.trim();
        return;
      }

      // 3. Fallback to default configured key
      state = GeminiConfig.fallbackApiKey;
      if (state.isNotEmpty) {
        await _secureStorage.write(key: _storageKey, value: state);
        await prefs.setString(_storageKey, state);
      }
    } catch (_) {
      state = GeminiConfig.fallbackApiKey;
    }
  }

  Future<void> setApiKey(String key) async {
    final clean = key.trim();
    state = clean;
    try {
      await _secureStorage.write(key: _storageKey, value: clean);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, clean);
    } catch (_) {}
  }

  Future<void> clearApiKey() async {
    state = '';
    try {
      await _secureStorage.delete(key: _storageKey);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
