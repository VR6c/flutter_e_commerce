import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/ai_assistant_provider.dart';
import '../providers/gemini_key_provider.dart';
import '../widgets/ai_thinking_indicator.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/gemini_key_dialog.dart';
import '../widgets/suggested_prompts_bar.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScrollChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    // In reverse: true, offset == 0 is bottom. offset > 120 means user scrolled up.
    final show = _scrollController.offset > 120;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _sendMessage([String? overrideText]) {
    final text = overrideText ?? _textController.text;
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear your conversation with TVR Assistant?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(aiAssistantProvider.notifier).clearChat();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatState = ref.watch(aiAssistantProvider);
    final apiKey = ref.watch(geminiApiKeyProvider);

    final isKeyConfigured = apiKey.isNotEmpty;

    // Smoothly scroll to bottom when a new message arrives or sending starts
    ref.listen(aiAssistantProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          (prev?.isLoading == false && next.isLoading == true)) {
        _scrollToBottom();
      }
    });

    final inputBg = isDark ? const Color(0xFF131D38) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF23AA49), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TVR Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isKeyConfigured
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isKeyConfigured ? 'Online' : 'Offline Mode',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Clear Chat Button
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            onPressed: chatState.messages.length > 1 ? _confirmClearChat : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // API Key Notice Banner if not configured yet
            if (!isKeyConfigured)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF281E0D)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Using offline demo responses. Add your Gemini API key for real-time AI.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => GeminiKeyDialog.show(context),
                      child: const Text(
                        'Setup',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Message List (reverse: true provides instant, zero-glitch bottom anchoring)
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (chatState.isLoading && index == 0) {
                        return const AiThinkingIndicator();
                      }

                      final messageIndex = chatState.isLoading
                          ? chatState.messages.length - index
                          : chatState.messages.length - 1 - index;

                      if (messageIndex < 0 ||
                          messageIndex >= chatState.messages.length) {
                        return const SizedBox.shrink();
                      }

                      final msg = chatState.messages[messageIndex];
                      return ChatBubble(
                        message: msg,
                        onRetry: msg.isError
                            ? () {
                                ref
                                    .read(aiAssistantProvider.notifier)
                                    .retryLastMessage();
                              }
                            : null,
                      );
                    },
                  ),
                  // Floating Scroll to Bottom Button
                  Positioned(
                    bottom: 8,
                    right: 16,
                    child: AnimatedScale(
                      scale: _showScrollToBottom ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: _showScrollToBottom ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: _showScrollToBottom
                            ? Material(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                elevation: 4,
                                shadowColor: Colors.black.withValues(
                                  alpha: isDark ? 0.4 : 0.15,
                                ),
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _scrollToBottom();
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Suggested Prompts Quick Bar
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
              child: SuggestedPromptsBar(
                onSelected: (prompt) {
                  _sendMessage(prompt);
                },
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: inputBg,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0B132B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask TVR Assistant anything...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (_canSend && !chatState.isLoading)
                          ? AppTheme.primaryColor
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0)),
                      shape: BoxShape.circle,
                      boxShadow: (_canSend && !chatState.isLoading)
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        size: 22,
                        color: (_canSend && !chatState.isLoading)
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                      ),
                      onPressed: (_canSend && !chatState.isLoading)
                          ? () => _sendMessage()
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
