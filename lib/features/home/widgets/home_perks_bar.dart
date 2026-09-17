import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Trust / Store Highlights Perks Strip for the Home Screen.
class HomePerksBar extends StatelessWidget {
  const HomePerksBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D38) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDCFCE7),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPerkItem(
              icon: Icons.bolt_rounded,
              label: l10n.fastDelivery,
              iconColor: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
            Container(
              height: 14,
              width: 1,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
            ),
            _buildPerkItem(
              icon: Icons.eco_rounded,
              label: l10n.organic100,
              iconColor: theme.colorScheme.primary,
              isDark: isDark,
            ),
            Container(
              height: 14,
              width: 1,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
            ),
            _buildPerkItem(
              icon: Icons.verified_user_rounded,
              label: l10n.bestPrices,
              iconColor: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
