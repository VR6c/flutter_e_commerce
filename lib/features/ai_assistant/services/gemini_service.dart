import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../categories/models/category.dart';
import '../../products/models/product.dart';
import '../models/chat_message.dart';
import '../models/gemini_config.dart';

class GeminiService {
  final Dio _dio;

  GeminiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  /// Builds a dynamic system instruction incorporating store catalog context
  String _buildSystemInstruction({
    List<Product> products = const [],
    List<Category> categories = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are TVR Assistant, the official shopping assistant for TVR Store.\n\n'
      '=== STRICT DATA SOURCE & SCOPE RULES ===\n'
      '1. ONLY STORE DATA: You must ONLY answer questions and recommend products using the TVR Store catalog and store information provided below. NEVER suggest or bring in outside products, external brands, recipes, or items from outside sources.\n'
      '2. HANDLE OUT-OF-SCOPE INQUIRIES: If a user asks for something outside our store inventory (such as groceries, cooking recipes, general web trivia, or unrelated items), politely inform them that TVR Store does not carry those items. State what categories we DO carry, and invite them to explore items from our catalog instead.\n'
      '3. PRODUCT RECOMMENDATIONS: When recommending any item from the catalog below, you MUST include its ID in the format: [Product: <ID>] (for example: [Product: 12]). This automatically renders an interactive product card for the customer.\n'
      '4. STORE POLICIES:\n'
      '   - Delivery: Orders arrive in 30 to 45 minutes across the city. Free delivery on orders over \$25. Standard delivery fee is \$1.50.\n'
      '   - Payment Methods: ABA PayWay (instant mobile banking & QR code), Credit/Debit cards (Visa/Mastercard), and Cash on Delivery.\n'
      '5. TONE & STYLE: Be courteous, professional, and concise. Do not use food emojis. Use clean bullet points and clear formatting.\n'
      '6. COMPLETENESS: When asked for a specific number of items (e.g. "top 10 items", "5 deals"), always provide the full requested list (all 10 items) with complete lines. Never truncate or stop mid-sentence.',
    );

    if (categories.isNotEmpty) {
      final categoryNames = categories.map((c) => c.name).join(', ');
      buffer.writeln('\nOfficial Available Categories in TVR Store: $categoryNames');
    }

    if (products.isNotEmpty) {
      buffer.writeln('\nOfficial TVR Store Inventory:');
      final catalogSample = products.take(60).map((p) {
        final priceStr = p.effectivePrice.toStringAsFixed(2);
        final discStr = p.hasDiscount ? ' (Sale: Save ${p.discountPercentage}%)' : '';
        final brandStr = p.brand != null && p.brand!.isNotEmpty ? ', Brand: ${p.brand}' : '';
        return '- [Product: ${p.id}] "${p.name}" - \$$priceStr$discStr, Category: ${p.category}$brandStr';
      }).join('\n');
      buffer.writeln(catalogSample);
    }

    return buffer.toString();
  }

  /// Sends conversation to OpenRouter and returns the assistant's reply.
  /// If no key is set or services are unreachable, provides intelligent store assistance.
  Future<String> generateResponse({
    required String apiKey,
    required List<ChatMessage> conversationHistory,
    String model = GeminiConfig.defaultModel,
    List<Product> availableProducts = const [],
    List<Category> availableCategories = const [],
    void Function(String resolvedModel)? onModelResolved,
  }) async {
    final cleanKey = apiKey.trim();

    // If no key is set, use the smart built-in fallback helper
    if (cleanKey.isEmpty) {
      return _generateOfflineFallback(
        conversationHistory.last.text,
        availableProducts,
        availableCategories,
      );
    }

    return _generateOpenRouterResponse(
      apiKey: cleanKey,
      conversationHistory: conversationHistory,
      preferredModel: model,
      availableProducts: availableProducts,
      availableCategories: availableCategories,
      onModelResolved: onModelResolved,
    );
  }

  /// Sends conversation to OpenRouter with automatic candidate model fallback
  Future<String> _generateOpenRouterResponse({
    required String apiKey,
    required List<ChatMessage> conversationHistory,
    String preferredModel = GeminiConfig.defaultModel,
    List<Product> availableProducts = const [],
    List<Category> availableCategories = const [],
    void Function(String resolvedModel)? onModelResolved,
  }) async {
    final systemPrompt = _buildSystemInstruction(
      products: availableProducts,
      categories: availableCategories,
    );

    final relevantHistory = conversationHistory
        .where((m) => !m.isError && m.text.trim().isNotEmpty)
        .toList();

    final startIndex =
        relevantHistory.length > 10 ? relevantHistory.length - 10 : 0;
    final recentMessages = relevantHistory.sublist(startIndex);

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
      ...recentMessages.map((m) {
        return {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        };
      }),
    ];

    if (messages.length == 1 || messages.last['role'] != 'user') {
      messages.add({
        'role': 'user',
        'content': conversationHistory.last.text,
      });
    }

    final modelsToTry = <String>[
      preferredModel,
      ...GeminiConfig.candidateModels.where((m) => m != preferredModel),
    ];

    for (final candidate in modelsToTry) {
      try {
        final payload = {
          'model': candidate,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 4096,
        };

        final response = await _dio.post(
          GeminiConfig.openRouterUrl,
          data: payload,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://tvr.store',
              'X-Title': 'TVR Assistant',
            },
          ),
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices.first as Map<String, dynamic>;
            final message = firstChoice['message'] as Map<String, dynamic>?;
            var content = message?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              content = content
                  .replaceAll(
                    RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false),
                    '',
                  )
                  .trim();
              if (content.isNotEmpty) {
                onModelResolved?.call(candidate);
                return content;
              }
            }
          }
        }
      } on DioException catch (e) {
        debugPrint('OpenRouter ($candidate) error: ${e.response?.statusCode} - ${e.message}');
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // If the key is invalid or unauthorized, fall back gracefully to store assistant
          debugPrint('OpenRouter unauthorized/invalid key, falling back to store assistant');
          return _generateOfflineFallback(
            conversationHistory.last.text,
            availableProducts,
            availableCategories,
          );
        }
        continue;
      } catch (e) {
        debugPrint('OpenRouter ($candidate) exception: $e');
        continue;
      }
    }

    // If OpenRouter calls failed or timed out, gracefully answer using local catalog
    debugPrint('All OpenRouter candidates exhausted, using catalog fallback');
    return _generateOfflineFallback(
      conversationHistory.last.text,
      availableProducts,
      availableCategories,
    );
  }

  /// Extracts product IDs mentioned in the AI response or matches store product names
  List<int> extractProductRecommendations(
    String aiResponse,
    List<Product> catalog,
  ) {
    if (catalog.isEmpty) return const [];

    final matchedIds = <int>{};

    // 1. Check for explicit pattern: [Product: <ID>] or [Product: <ID> - <Name>]
    final explicitRegex = RegExp(r'\[Product:\s*(\d+)[^\]]*\]', caseSensitive: false);
    for (final match in explicitRegex.allMatches(aiResponse)) {
      final idStr = match.group(1);
      if (idStr != null) {
        final parsedId = int.tryParse(idStr);
        if (parsedId != null && catalog.any((p) => p.id == parsedId)) {
          matchedIds.add(parsedId);
        }
      }
    }

    // 2. If no explicit tags, match product names directly (case-insensitive substring)
    if (matchedIds.isEmpty) {
      final lowerResponse = aiResponse.toLowerCase();
      for (final product in catalog) {
        final lowerName = product.name.toLowerCase();
        // Avoid matching very short generic words
        if (lowerName.length >= 4 && lowerResponse.contains(lowerName)) {
          matchedIds.add(product.id);
          if (matchedIds.length >= 4) break; // Limit to 4 cards for optimal UI
        }
      }
    }

    return matchedIds.toList();
  }

  /// Provides intelligent offline assistance when no API key is supplied or service is offline
  String _generateOfflineFallback(
    String userQuery,
    List<Product> products,
    List<Category> categories,
  ) {
    final lower = userQuery.toLowerCase();

    // 1. Delivery & Shipping
    if (lower.contains('delivery') || lower.contains('ship') || lower.contains('time')) {
      return 'TVR Store offers standard delivery within 30 to 45 minutes across the city.\n\n'
          'Key Delivery Details:\n'
          '- Free delivery on orders over \$25\n'
          '- Standard delivery fee: \$1.50\n'
          '- Real-time delivery tracking available in your Orders tab';
    }

    // 2. Payments & Checkout
    if (lower.contains('pay') || lower.contains('card') || lower.contains('cash') || lower.contains('aba')) {
      return 'TVR Store accepts multiple secure payment options:\n\n'
          '- ABA PayWay (QR code & instant bank app checkout)\n'
          '- Credit / Debit Cards (Visa, Mastercard)\n'
          '- Cash on Delivery (pay when your items arrive)';
    }

    // 3. Deals & Discounts
    if (lower.contains('deal') || lower.contains('discount') || lower.contains('sale') || lower.contains('cheap')) {
      final discounted = products.where((p) => p.hasDiscount).take(3).toList();
      if (discounted.isNotEmpty) {
        final buffer = StringBuffer('Here are current deals available at TVR Store:\n\n');
        for (final p in discounted) {
          buffer.writeln('- [Product: ${p.id}] - ${p.name}: \$${p.effectivePrice.toStringAsFixed(2)} (Save ${p.discountPercentage}%)');
        }
        return buffer.toString();
      }
      return 'You can check our daily discounts right from the Home page banners and Featured Deals section.';
    }

    // 4. Categories, Products, and Catalog
    if (lower.contains('categor') ||
        lower.contains('item') ||
        lower.contains('product') ||
        lower.contains('available') ||
        lower.contains('catalog') ||
        lower.contains('what do you have') ||
        lower.contains('browse') ||
        lower.contains('store')) {
      final buffer = StringBuffer('Welcome to TVR Store! Here is what we have available in our catalog:\n\n');
      if (categories.isNotEmpty) {
        buffer.writeln('📂 Available Categories:');
        for (final c in categories) {
          buffer.writeln('• ${c.name}');
        }
        buffer.writeln();
      }
      if (products.isNotEmpty) {
        buffer.writeln('🛍️ Featured Products:');
        for (final p in products.take(4)) {
          buffer.writeln('- [Product: ${p.id}] - ${p.name}: \$${p.effectivePrice.toStringAsFixed(2)}');
        }
        buffer.writeln('\nYou can tap any product card below to view details or add items to your cart.');
      }
      return buffer.toString();
    }

    // 5. Groceries / Food inquiry
    if (lower.contains('fruit') || lower.contains('vegetable') || lower.contains('produce') || lower.contains('food') || lower.contains('recipe')) {
      final sample = products.take(3).toList();
      final buffer = StringBuffer('TVR Store specializes in electronics, fashion, and accessories rather than fresh food.\n\nHere are some of our popular products:\n\n');
      for (final p in sample) {
        buffer.writeln('- [Product: ${p.id}] - ${p.name}: \$${p.effectivePrice.toStringAsFixed(2)}');
      }
      buffer.writeln('\nTap any product card below to view details or add it directly to your cart.');
      return buffer.toString();
    }

    // 6. Default friendly assistant introduction
    return 'Hello! I am TVR Assistant, your shopping assistant.\n\n'
        'I can help you with:\n'
        '• Exploring product categories and catalog items\n'
        '• Finding current sales and special discounts\n'
        '• Checking delivery options and payment methods\n\n'
        'What can I help you find today?';
  }
}
