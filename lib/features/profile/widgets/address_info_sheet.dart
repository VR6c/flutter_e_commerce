import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class AddressInfoSheet extends StatelessWidget {
  const AddressInfoSheet({super.key});

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddressInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.shippingAddress,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 18,
                        color: Color(0xFF23AA49),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.homeDefaultDelivery,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.phnomPenhCityCambodianstreet271,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      letterSpacing: 0,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.done,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
