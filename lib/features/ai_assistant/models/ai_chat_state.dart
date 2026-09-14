import 'chat_message.dart';
import 'gemini_config.dart';

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final String selectedModel;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedModel = GeminiConfig.defaultModel,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? selectedModel,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}
