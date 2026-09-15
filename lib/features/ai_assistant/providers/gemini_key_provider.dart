import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gemini_config.dart';

final geminiApiKeyProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, String>((ref) {
  return GeminiApiKeyNotifier();
});

class GeminiApiKeyNotifier extends StateNotifier<String> {
  GeminiApiKeyNotifier() : super(GeminiConfig.apiKey);

  /// Method to dynamically update key if needed by code
  Future<void> setApiKey(String key) async {
    state = key.trim();
  }

  /// Reset to code-configured key
  Future<void> clearApiKey() async {
    state = GeminiConfig.apiKey;
  }
}

