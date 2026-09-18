import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Highly reusable, isolated price breakdown card.
/// Consolidates pricing logic and layout across Cart, Checkout, and Order Details.
class PriceBreakdownCard extends StatelessWidget {
  final double subtotal;
  final double? discount;
  final String? couponCode;
  final double? weight;
  final double? vat;
  final double deliveryFee;
  final double total;
  final String? title;
  final EdgeInsetsGeometry padding;
  final Widget? footer;

  const PriceBreakdownCard({
    super.key,
    required this.subtotal,
    this.discount,
    this.couponCode,
    this.weight,
    this.vat,
    this.deliveryFee = 0.0,
    required this.total,
    this.title,
    this.padding = const EdgeInsets.all(16),
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final hasDiscount = discount != null && discount! > 0;
    final hasWeight = weight != null && weight! > 0;
    final hasVat = vat != null;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _priceRow(
            label: l10n.subtotal,
            value: '\$${subtotal.toStringAsFixed(2)}',
            theme: theme,
            isDark: isDark,
          ),
          if (hasWeight) ...[
            const SizedBox(height: 8),
            _priceRow(
              label: l10n.weightLabel,
              value: l10n.weightKg(weight!.toStringAsFixed(1)),
              theme: theme,
              isDark: isDark,
            ),
          ],
          if (hasVat) ...[
            const SizedBox(height: 8),
            _priceRow(
              label: l10n.vatLabel,
              value: '\$${vat!.toStringAsFixed(2)}',
              theme: theme,
              isDark: isDark,
            ),
          ],
          if (hasDiscount) ...[
            const SizedBox(height: 8),
            _priceRow(
              label: couponCode != null
                  ? '${l10n.discount} (${couponCode!})'
                  : l10n.discount,
              value: '-\$${discount!.toStringAsFixed(2)}',
              theme: theme,
              isDark: isDark,
              valueColor: theme.colorScheme.primary,
            ),
          ],
          const SizedBox(height: 8),
          _priceRow(
            label: l10n.deliveryFee,
            value: deliveryFee == 0.0
                ? l10n.free
                : '\$${deliveryFee.toStringAsFixed(2)}',
            theme: theme,
            isDark: isDark,
            valueColor: deliveryFee == 0.0 ? theme.colorScheme.primary : null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _priceRow(
            label: l10n.total,
            value: '\$${total.toStringAsFixed(2)}',
            theme: theme,
            isDark: isDark,
            isBold: true,
            fontSize: 18,
            valueColor: theme.colorScheme.primary,
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }

  static Widget _priceRow({
    required String label,
    required String value,
    required ThemeData theme,
    required bool isDark,
    bool isBold = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: valueColor ?? theme.colorScheme.onSurface,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
