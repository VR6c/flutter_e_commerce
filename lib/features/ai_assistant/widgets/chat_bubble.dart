import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../models/chat_message.dart';
import 'chat_product_card.dart';

class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.isUser) {
      return _buildUserBubble(context, isDark);
    } else {
      return _buildAiBubble(context, ref, theme, isDark);
    }
  }

  Widget _buildUserBubble(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 6),
            child: Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF131D38) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    // Resolve recommended products if any
    final allProducts = ref.watch(productsProvider).valueOrNull ?? [];
    final recommendedProducts = <Product>[];
    if (message.productIds.isNotEmpty && allProducts.isNotEmpty) {
      for (final id in message.productIds) {
        final match = allProducts.where((p) => p.id == id);
        if (match.isNotEmpty) {
          recommendedProducts.add(match.first);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gemini Avatar Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF23AA49), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),

              // Main Message Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? (isDark
                            ? const Color(0xFF2D1214)
                            : const Color(0xFFFEF2F2))
                        : cardBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: message.isError
                          ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                          : borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header tag: TVR Assistant
                      Row(
                        children: [
                          Text(
                            'TVR Assistant',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: message.isError
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Formatted Text
                      _FormattedMarkdownText(
                        text: message.text,
                        isError: message.isError,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 8),

                      // Actions Row: Copy & Retry
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (message.isError && onRetry != null)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: const Color(0xFFEF4444),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _copyMessage(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Recommended Products Carousel if matches are found
          if (recommendedProducts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Recommended Items (${recommendedProducts.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedProducts.length,
                      itemBuilder: (context, idx) {
                        return ChatProductCard(
                          product: recommendedProducts[idx],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lightweight, clean markdown formatter for clean bullet points, bold text, and headers
class _FormattedMarkdownText extends StatelessWidget {
  final String text;
  final bool isError;
  final bool isDark;

  const _FormattedMarkdownText({
    required this.text,
    required this.isError,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final textColor = isError
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }

        // Header ##
        if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
          final headerText = trimmed.replaceFirst(RegExp(r'^#{2,3}\s*'), '');
          return Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          );
        }

        // Bullet point
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          final bulletText = trimmed.substring(2);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isError
                        ? const Color(0xFFEF4444)
                        : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: _parseRichInlineText(bulletText, textColor),
                ),
              ],
            ),
          );
        }

        // Standard paragraph
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: _parseRichInlineText(trimmed, textColor),
        );
      }).toList(),
    );
  }

  Widget _parseRichInlineText(String text, Color baseColor) {
    // Check for **bold** patterns
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            color: baseColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: baseColor,
          fontSize: 13.5,
          height: 1.45,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
