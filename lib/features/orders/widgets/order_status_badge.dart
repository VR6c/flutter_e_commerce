import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable status badge pill for order status representations across
/// Order History, Order Details, and Profile order pipelines.
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = _resolveStatus(status, l10n);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: info.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(info.icon, size: fontSize + 2, color: info.color),
            const SizedBox(width: 4),
          ],
          Text(
            info.label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: info.color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  static _StatusConfig _resolveStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return _StatusConfig(
          color: const Color(0xFF059669),
          icon: Icons.check_circle_rounded,
          label: l10n.completed,
        );
      case 'processing':
        return _StatusConfig(
          color: const Color(0xFF4F46E5),
          icon: Icons.sync_rounded,
          label: l10n.processingStatus,
        );
      case 'cancelled':
      case 'canceled':
        return _StatusConfig(
          color: const Color(0xFFDC2626),
          icon: Icons.cancel_rounded,
          label: l10n.statusCancelled,
        );
      case 'paid':
        return _StatusConfig(
          color: const Color(0xFF0284C7),
          icon: Icons.verified_rounded,
          label: 'PAID',
        );
      case 'pending':
      default:
        return _StatusConfig(
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top_rounded,
          label: l10n.statusPending,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
