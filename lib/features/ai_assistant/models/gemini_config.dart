class GeminiConfig {
  GeminiConfig._();

  /// OpenRouter API Endpoint
  static const String openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Default active model for conversational shopping assistance on OpenRouter.
  static const String defaultModel = 'google/gemini-2.0-flash-exp:free';

  /// Candidate models to try in order of capability, availability, and quota.
  static const List<String> candidateModels = [
    'google/gemini-2.0-flash-exp:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-chat:free',
    'openrouter/free',
    'google/gemini-2.5-flash',
  ];

  /// OpenRouter API Key configured directly in code.
  /// Set your API key here in code, or inject at build-time using:
  /// flutter build ipa --dart-define=OPENROUTER_API_KEY=your_key
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue:
        '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', // <-- Paste your OpenRouter API Key here (sk-or-v1-...)
  );

  /// Key aliases for backward compatibility across existing providers
  static const String apiKey = openRouterApiKey;
  static const String fallbackApiKey = openRouterApiKey;

  /// OpenRouter dashboard URL for managing API keys
  static const String getApiKeyUrl = 'https://openrouter.ai/keys';
}
