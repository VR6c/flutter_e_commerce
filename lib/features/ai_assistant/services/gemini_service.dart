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

  List<String>? _cachedAvailableModels;

  /// Queries Google AI Studio to discover which models are enabled for this API key
  Future<List<String>> fetchAvailableModels(String cleanKey) async {
    if (_cachedAvailableModels != null && _cachedAvailableModels!.isNotEmpty) {
      return _cachedAvailableModels!;
    }
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey';
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': cleanKey,
          },
        ),
      );

      final data = response.data;
      if (data is Map && data['models'] is List) {
        final list = (data['models'] as List)
            .whereType<Map>()
            .where((m) {
              final methods = m['supportedGenerationMethods'] as List<dynamic>?;
              return methods != null && methods.contains('generateContent');
            })
            .map((m) => m['name']?.toString().replaceFirst('models/', '') ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        if (list.isNotEmpty) {
          _cachedAvailableModels = list;
          debugPrint('Fetched available Gemini models for key: $list');
          return list;
        }
      }
    } catch (e) {
      debugPrint('Could not list models: $e');
    }
    return [];
  }

  /// Sends the conversation history to the Gemini API and returns the assistant's reply.
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

    // If OpenRouter API key is used, route through OpenRouter completions
    if (cleanKey.startsWith('sk-or-')) {
      return _generateOpenRouterResponse(
        apiKey: cleanKey,
        conversationHistory: conversationHistory,
        availableProducts: availableProducts,
        availableCategories: availableCategories,
        onModelResolved: onModelResolved,
      );
    }

    // Discover models available to this specific key from Google AI Studio
    final discoveredModels = await fetchAvailableModels(cleanKey);

    final modelsToTry = <String>[];
    if (discoveredModels.isNotEmpty) {
      // Prioritize Flash models first (highest free tier quota & RPM)
      final flashModels =
          discoveredModels.where((m) => m.toLowerCase().contains('flash')).toList();
      modelsToTry.addAll(flashModels);
      modelsToTry.addAll(
        discoveredModels.where((m) => !m.toLowerCase().contains('flash')),
      );
    } else {
      modelsToTry.addAll([
        model,
        ...GeminiConfig.candidateModels.where((m) => m != model),
      ]);
    }

    DioException? lastDioException;
    String? lastErrorMessage;

    for (final candidate in modelsToTry) {
      try {
        final result = await _callModelEndpoint(
          candidate,
          cleanKey,
          conversationHistory,
          availableProducts,
          availableCategories,
        );
        onModelResolved?.call(candidate);
        return result;
      } on DioException catch (dioErr) {
        lastDioException = dioErr;
        final statusCode = dioErr.response?.statusCode;
        final responseBody = dioErr.response?.data;
        String? msg;
        if (responseBody is Map && responseBody['error'] is Map) {
          msg = responseBody['error']['message']?.toString();
        }

        // If 404 or model not found or no longer available, try the next candidate model
        final isModelError = statusCode == 404 ||
            (msg != null &&
                (msg.contains('not found') ||
                    msg.contains('no longer available') ||
                    msg.contains('not supported')));

        if (isModelError) {
          debugPrint(
            'Model $candidate unavailable ($statusCode: $msg), falling back to next candidate model...',
          );
          continue;
        }

        // For auth errors (401, 403), quota limits (429), or syntax errors, throw immediately
        _handleDioException(dioErr);
      } catch (e) {
        lastErrorMessage = e.toString();
        if (lastErrorMessage.contains('not found') ||
            lastErrorMessage.contains('no longer available') ||
            lastErrorMessage.contains('not supported')) {
          continue;
        }
        rethrow;
      }
    }

    if (lastDioException != null) {
      _handleDioException(lastDioException);
    }

    throw Exception(lastErrorMessage ?? 'Unable to connect to Gemini models.');
  }

  Future<String> _callModelEndpoint(
    String model,
    String cleanKey,
    List<ChatMessage> conversationHistory,
    List<Product> availableProducts,
    List<Category> availableCategories,
  ) async {
    final url = '${GeminiConfig.baseUrl}/$model:generateContent?key=$cleanKey';

    final systemPrompt = _buildSystemInstruction(
      products: availableProducts,
      categories: availableCategories,
    );

    // Format previous messages into Gemini contents array
    final relevantHistory = conversationHistory
        .where((m) => !m.isError && m.text.trim().isNotEmpty)
        .toList();

    final startIndex =
        relevantHistory.length > 10 ? relevantHistory.length - 10 : 0;
    final recentMessages = relevantHistory.sublist(startIndex);

    final contents = recentMessages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ],
      };
    }).toList();

    if (contents.isEmpty || contents.last['role'] != 'user') {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': conversationHistory.last.text}
        ],
      });
    }

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
      },
    };

    Response<dynamic>? response;
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        response = await _dio.post(
          url,
          data: payload,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': cleanKey,
            },
          ),
        );
        break;
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 429 && attempt < 2) {
          debugPrint(
            'Rate limit 429 received. Waiting 4 seconds before automatic retry...',
          );
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }
        rethrow;
      }
    }

    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final firstCandidate = candidates.first as Map<String, dynamic>;
        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final textParts = parts
              .where((p) =>
                  p is Map &&
                  p['thought'] != true &&
                  p['text'] != null &&
                  p['text'].toString().trim().isNotEmpty)
              .map((p) => (p as Map)['text'].toString().trim())
              .toList();

          if (textParts.isNotEmpty) {
            return textParts.join('\n\n');
          }

          final firstPart = parts.first as Map<String, dynamic>;
          final text = firstPart['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
    }


    throw Exception('Unexpected empty response received from Gemini.');
  }

  Never _handleDioException(DioException dioErr) {
    debugPrint(
      'Gemini API DioException: ${dioErr.response?.statusCode} - ${dioErr.message}',
    );
    final statusCode = dioErr.response?.statusCode;
    final responseBody = dioErr.response?.data;

    if (statusCode == 400) {
      throw Exception(
        'Request error (400): Unable to process request. Please check your Gemini API key.',
      );
    } else if (statusCode == 401 || statusCode == 403) {
      throw Exception(
        'Authentication error ($statusCode): Invalid Gemini API key. Please configure a valid key in settings.',
      );
    } else if (statusCode == 429) {
      throw Exception(
        'Gemini rate limit exceeded. Google AI Studio Free Tier has a limit of requests per minute. Please wait 15-30 seconds and tap Retry.',
      );
    } else if (dioErr.type == DioExceptionType.connectionTimeout ||
        dioErr.type == DioExceptionType.receiveTimeout) {
      throw Exception(
        'Connection timed out while contacting Gemini. Please verify your internet connection.',
      );
    } else if (responseBody is Map && responseBody['error']?['message'] != null) {
      final msg = responseBody['error']['message'] as String;
      throw Exception('Gemini Error: $msg');
    }

    throw Exception(
      'Unable to connect to Gemini (${statusCode ?? 'network'}). Please check your connection.',
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

  /// Provides intelligent offline assistance when no API key is supplied yet
  String _generateOfflineFallback(
    String userQuery,
    List<Product> products,
    List<Category> categories,
  ) {
    final lower = userQuery.toLowerCase();

    if (lower.contains('delivery') || lower.contains('ship') || lower.contains('time')) {
      return 'TVR Store offers standard delivery within 30 to 45 minutes across the city.\n\n'
          'Key Delivery Details:\n'
          '- Free delivery on orders over \$25\n'
          '- Standard delivery fee: \$1.50\n'
          '- Real-time delivery tracking available in your Orders tab';
    }

    if (lower.contains('pay') || lower.contains('card') || lower.contains('cash') || lower.contains('aba')) {
      return 'TVR Store accepts multiple secure payment options:\n\n'
          '- ABA PayWay (QR code & instant bank app checkout)\n'
          '- Credit / Debit Cards (Visa, Mastercard)\n'
          '- Cash on Delivery (pay when your items arrive)';
    }

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

    if (lower.contains('fruit') || lower.contains('vegetable') || lower.contains('produce') || lower.contains('food') || lower.contains('recipe')) {
      final sample = products.take(3).toList();
      final buffer = StringBuffer('TVR Store does not carry groceries or fresh food. We specialize in electronics, fashion, and accessories.\n\nHere are some of our featured catalog items:\n\n');
      for (final p in sample) {
        buffer.writeln('- [Product: ${p.id}] - ${p.name}: \$${p.effectivePrice.toStringAsFixed(2)}');
      }
      buffer.writeln('\nTap any product card below to view details or add it directly to your cart.');
      return buffer.toString();
    }

    return 'Welcome to TVR Assistant!\n\n'
        'To connect with generative AI for real-time answers and smart recommendations:\n'
        '1. Tap the Settings icon in the top right corner.\n'
        '2. Enter your API key (available from Google AI Studio or OpenRouter).\n\n'
        'In the meantime, feel free to ask about our delivery terms, payment methods, or browse our catalog!';
  }

  /// Sends conversation to OpenRouter using free models with automatic fallback
  Future<String> _generateOpenRouterResponse({
    required String apiKey,
    required List<ChatMessage> conversationHistory,
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

    final freeCandidateModels = [
      'openrouter/free',
      'google/gemini-2.0-flash-exp:free',
      'meta-llama/llama-3.3-70b-instruct:free',
      'deepseek/deepseek-chat:free',
    ];

    DioException? lastError;

    for (final candidate in freeCandidateModels) {
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
        lastError = e;
        debugPrint('OpenRouter ($candidate) error: ${e.response?.statusCode} - ${e.message}');
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw Exception('Invalid OpenRouter API key. Please check your key in settings.');
        }
        continue;
      } catch (e) {
        debugPrint('OpenRouter ($candidate) exception: $e');
        continue;
      }
    }

    if (lastError != null) {
      throw Exception(
        'OpenRouter error (${lastError.response?.statusCode ?? 'network'}). Please try again.',
      );
    }

    throw Exception('Unable to get response from OpenRouter free models.');
  }
}

