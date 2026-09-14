class GeminiConfig {
  GeminiConfig._();

  /// Default active model for conversational grocery shopping assistance.
  static const String defaultModel = 'gemini-3.1-pro-preview';

  /// Alternative high-speed / fallback models
  static const String fastModel = 'gemini-3.1-pro-preview-customtools';

  /// Candidate models to try in order of capability and availability
  static const List<String> candidateModels = [
    'gemini-3.1-pro-preview',
    'gemini-3.1-pro-preview-customtools',
    'gemini-2.5-flash',
  ];

  /// Base URL for the Google Gemini Generative Language REST API.
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Secure storage key for persisting the user's Gemini API key.
  static const String storageKey = 'gemini_api_key';

  /// OpenRouter API Endpoint
  static const String openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Default free router for OpenRouter
  static const String openRouterFreeModel = 'openrouter/free';

  /// Default API key fallback (can be configured by user via in-app settings).
  static const String fallbackApiKey = '';

  /// Google AI Studio URL for obtaining an API key.
  static const String getApiKeyUrl = 'https://aistudio.google.com/app/apikey';
}
