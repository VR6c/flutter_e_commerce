import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_e_commerce/features/ai_assistant/models/chat_message.dart';
import 'package:flutter_e_commerce/features/ai_assistant/models/gemini_config.dart';
import 'package:flutter_e_commerce/features/ai_assistant/services/gemini_service.dart';
import 'package:flutter_e_commerce/features/ai_assistant/providers/ai_assistant_provider.dart';
import 'package:flutter_e_commerce/features/ai_assistant/widgets/suggested_prompts_bar.dart';
import 'package:flutter_e_commerce/features/products/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testProduct1 = Product(
    id: 101,
    slug: 'organic-avocado',
    name: 'Organic Avocado',
    shortDescription: 'Fresh Hass avocados',
    price: 3.50,
    thumbnail: 'https://example.com/avocado.png',
    category: 'Fresh Produce',
  );

  const testProduct2 = Product(
    id: 102,
    slug: 'fresh-spinach',
    name: 'Fresh Spinach',
    shortDescription: 'Locally grown crisp spinach',
    price: 2.20,
    thumbnail: 'https://example.com/spinach.png',
    category: 'Vegetables',
  );

  group('ChatMessage model tests', () {
    test('Serializes to and from JSON correctly', () {
      final message = ChatMessage(
        id: 'msg_1',
        text: 'What are the delivery hours?',
        isUser: true,
        createdAt: DateTime(2026, 9, 14, 12, 0, 0),
        productIds: [101, 102],
      );

      final json = message.toJson();
      expect(json['id'], 'msg_1');
      expect(json['text'], 'What are the delivery hours?');
      expect(json['isUser'], true);
      expect(json['productIds'], [101, 102]);

      final restored = ChatMessage.fromJson(json);
      expect(restored.id, 'msg_1');
      expect(restored.text, 'What are the delivery hours?');
      expect(restored.isUser, true);
      expect(restored.productIds, [101, 102]);
    });

    test('copyWith works as expected', () {
      final original = ChatMessage(
        id: 'msg_1',
        text: 'Initial',
        isUser: false,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(text: 'Updated Text', isError: true);
      expect(updated.id, original.id);
      expect(updated.text, 'Updated Text');
      expect(updated.isError, true);
    });
  });

  group('GeminiService tests', () {
    late GeminiService geminiService;

    setUp(() {
      geminiService = GeminiService();
    });

    test('Extracts explicit product tags [Product: <ID>]', () {
      const response =
          'I recommend [Product: 101] for your salad, along with [Product: 102]!';
      final extracted = geminiService.extractProductRecommendations(
        response,
        [testProduct1, testProduct2],
      );

      expect(extracted, containsAll([101, 102]));
    });

    test('Extracts product by name matching in catalog', () {
      const response =
          'You might like our Fresh Spinach which is sourced locally.';
      final extracted = geminiService.extractProductRecommendations(
        response,
        [testProduct1, testProduct2],
      );

      expect(extracted, contains(102));
    });

    test('Offline fallback answers delivery questions cleanly', () async {
      final response = await geminiService.generateResponse(
        apiKey: '',
        conversationHistory: [
          ChatMessage(
            id: '1',
            text: 'How fast is delivery?',
            isUser: true,
            createdAt: DateTime.now(),
          )
        ],
        availableProducts: [testProduct1],
      );

      expect(response, contains('30 to 45 minutes'));
      expect(response, contains('Free delivery'));
    });

    test('Offline fallback answers payment methods cleanly', () async {
      final response = await geminiService.generateResponse(
        apiKey: '',
        conversationHistory: [
          ChatMessage(
            id: '1',
            text: 'What payment methods do you accept?',
            isUser: true,
            createdAt: DateTime.now(),
          )
        ],
        availableProducts: [testProduct1],
      );

      expect(response, contains('ABA PayWay'));
      expect(response, contains('Cash on Delivery'));
    });
  });

  group('Suggested prompts tests', () {
    test('Ensures suggested prompts contain no food emojis', () {
      final foodEmojiRegex = RegExp(
        r'[\u{1F344}-\u{1F37F}\u{1F950}-\u{1F96F}\u{1F980}-\u{1F9FF}\u{1F6D2}]',
        unicode: true,
      );

      for (final prompt in SuggestedPromptsBar.defaultPrompts) {
        expect(
          foodEmojiRegex.hasMatch(prompt.label),
          isFalse,
          reason: 'Label "${prompt.label}" should not contain food emojis',
        );
        expect(
          foodEmojiRegex.hasMatch(prompt.prompt),
          isFalse,
          reason: 'Prompt "${prompt.prompt}" should not contain food emojis',
        );
      }
    });
  });

  group('AiAssistantNotifier tests', () {
    test('Initial state contains welcome message and default model', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(aiAssistantProvider);
      expect(state.messages.isNotEmpty, isTrue);
      expect(state.messages.first.isUser, isFalse);
      expect(state.messages.first.text, contains('TVR Assistant'));
      expect(state.selectedModel, GeminiConfig.defaultModel);
      expect(state.isLoading, isFalse);
    });

    test('Clear chat resets messages back to welcome message', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiAssistantProvider.notifier);
      await notifier.sendMessage('Hello');

      expect(container.read(aiAssistantProvider).messages.length, greaterThan(1));

      await notifier.clearChat();
      final resetState = container.read(aiAssistantProvider);
      expect(resetState.messages.length, 1);
      expect(resetState.messages.first.isUser, isFalse);
    });
  });
}
