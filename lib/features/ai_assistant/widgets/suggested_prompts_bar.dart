import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class SuggestedPromptItem {
  final String label;
  final String prompt;
  final IconData icon;

  const SuggestedPromptItem({
    required this.label,
    required this.prompt,
    required this.icon,
  });
}

class SuggestedPromptsBar extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const SuggestedPromptsBar({super.key, required this.onSelected});

  static const List<SuggestedPromptItem> defaultPrompts = [
    SuggestedPromptItem(
      label: 'Explore catalog',
      prompt: 'What product categories and items do you currently have available in TVR Store?',
      icon: Icons.storefront_rounded,
    ),
    SuggestedPromptItem(
      label: "Today's discounts",
      prompt: "What products are currently discounted or on sale in the store?",
      icon: Icons.local_offer_outlined,
    ),
    SuggestedPromptItem(
      label: 'Popular items',
      prompt: 'Can you show me the featured and top recommended products from our store?',
      icon: Icons.stars_rounded,
    ),
    SuggestedPromptItem(
      label: 'Delivery options',
      prompt: 'What are the delivery times, fees, and minimum order requirements?',
      icon: Icons.local_shipping_outlined,
    ),
    SuggestedPromptItem(
      label: 'Payment methods',
      prompt: 'What payment methods can I use to checkout (ABA PayWay, Cards, COD)?',
      icon: Icons.payment_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chipBg = isDark ? const Color(0xFF192545) : Colors.white;
    final borderColor = isDark ? const Color(0xFF263558) : const Color(0xFFE2E8F0);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: defaultPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = defaultPrompts[index];
          return Container(
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelected(item.prompt);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 15,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
