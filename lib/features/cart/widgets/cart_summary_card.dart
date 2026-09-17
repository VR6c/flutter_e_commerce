import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';

/// Isolated Bill Summary card in the Cart Screen.
/// Only listens to totalAmount, totalWeight, and couponState.
class CartSummaryCard extends ConsumerWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = ref.watch(cartTotalAmountProvider);
    final totalWeight = ref.watch(cartTotalWeightProvider);
    final couponState = ref.watch(couponProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final double discount = couponState.isApplied ? couponState.discountAmount : 0.0;
    final double finalTotal = (totalAmount - discount).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          _summaryRow(
            l10n.subtotal,
            '\$${totalAmount.toStringAsFixed(2)}',
            theme,
            isDark,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            l10n.weightLabel,
            l10n.isKhmer
                ? '${totalWeight.toStringAsFixed(1)} គ.ក'
                : '${totalWeight.toStringAsFixed(1)} kg',
            theme,
            isDark,
          ),
          const SizedBox(height: 8),
          _summaryRow(l10n.vatLabel, '\$0.00', theme, isDark),
          if (couponState.isApplied) ...[
            const SizedBox(height: 8),
            _summaryRow(
              l10n.discount,
              '-\$${couponState.discountAmount.toStringAsFixed(2)}',
              theme,
              isDark,
              valueColor: theme.colorScheme.primary,
            ),
          ],
          const SizedBox(height: 8),
          _summaryRow(
            l10n.deliveryFee,
            l10n.isKhmer ? 'ឥតគិតថ្លៃ' : 'FREE',
            theme,
            isDark,
            valueColor: theme.colorScheme.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _summaryRow(
            l10n.total,
            '\$${finalTotal.toStringAsFixed(2)}',
            theme,
            isDark,
            isBold: true,
            fontSize: 18,
            valueColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
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
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
