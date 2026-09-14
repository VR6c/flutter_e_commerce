import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../categories/providers/category_provider.dart';
import '../../products/providers/product_provider.dart';
import '../models/ai_chat_state.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import 'gemini_key_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiChatState>((ref) {
  final service = ref.watch(geminiServiceProvider);
  return AiAssistantNotifier(ref, service);
});

class AiAssistantNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;
  final GeminiService _service;
  static const _historyPrefsKey = 'freshmart_ai_chat_history_v1';

  AiAssistantNotifier(this._ref, this._service) : super(const AiChatState()) {
    _loadHistory();
  }

  static const String initialGreeting =
      'Hello! I am TVR Assistant, your personal shopping assistant.\n\n'
      'I can help you with:\n'
      '- Product recommendations from our store\n'
      '- Finding deals and special discounts\n'
      '- Checking delivery options and payment methods\n\n'
      'What can I help you find today?';

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) {
          state = state.copyWith(messages: list);
          return;
        }
      }
    } catch (_) {}

    // First time welcome message
    final initialMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      text: initialGreeting,
      isUser: false,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [initialMessage]);
  }

  Future<void> _persistHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep up to 50 most recent messages for performance
      final toSave = messages.length > 50
          ? messages.sublist(messages.length - 50)
          : messages;
      final encoded = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(_historyPrefsKey, encoded);
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMsg];
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      clearError: true,
    );

    final apiKey = _ref.read(geminiApiKeyProvider);
    final products = _ref.read(productsProvider).valueOrNull ?? [];
    final categories = _ref.read(categoriesProvider).valueOrNull ?? [];

    try {
      final reply = await _service.generateResponse(
        apiKey: apiKey,
        conversationHistory: updatedMessages,
        model: state.selectedModel,
        availableProducts: products,
        availableCategories: categories,
        onModelResolved: (resolvedModel) {
          if (resolvedModel != state.selectedModel) {
            state = state.copyWith(selectedModel: resolvedModel);
          }
        },
      );

      final recommendedIds = _service.extractProductRecommendations(
        reply,
        products,
      );

      final aiMsg = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: reply,
        isUser: false,
        createdAt: DateTime.now(),
        productIds: recommendedIds,
      );

      final finalMessages = [...updatedMessages, aiMsg];
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
      );

      await _persistHistory(finalMessages);
    } catch (e) {
      final errorText = e.toString().replaceFirst('Exception: ', '');
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: errorText,
        isUser: false,
        createdAt: DateTime.now(),
        isError: true,
      );

      final finalMessages = [...updatedMessages, errorMsg];
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
        errorMessage: errorText,
      );

      await _persistHistory(finalMessages);
    }
  }

  Future<void> retryLastMessage() async {
    final lastUserMsg = state.messages.reversed.where((m) => m.isUser).firstOrNull;

    if (lastUserMsg != null && lastUserMsg.text.isNotEmpty) {
      // Remove any trailing error message
      final cleanedMessages = state.messages.where((m) => !m.isError).toList();
      state = state.copyWith(messages: cleanedMessages);
      await sendMessage(lastUserMsg.text);
    }
  }


  Future<void> clearChat() async {
    final welcomeMsg = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      text: initialGreeting,
      isUser: false,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [welcomeMsg],
      isLoading: false,
      clearError: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyPrefsKey);
    } catch (_) {}
  }

  void updateModel(String model) {
    state = state.copyWith(selectedModel: model);
  }
}
