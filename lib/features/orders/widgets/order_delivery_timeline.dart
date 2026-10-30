import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Unified order progress timeline stepper matching across
/// Order Success, Order Details, and Order History tracking.
class OrderDeliveryTimeline extends StatelessWidget {
  final String status;
  final bool showCard;
  final EdgeInsetsGeometry? padding;

  const OrderDeliveryTimeline({
    super.key,
    required this.status,
    this.showCard = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;

    final lower = status.toLowerCase().trim();
    final isCancelled = lower == 'cancelled' || lower == 'canceled';

    if (isCancelled) {
      final content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                size: 20,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stepCancelled,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.orderCancelledNotice,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      return showCard ? content : Padding(padding: padding ?? EdgeInsets.zero, child: content);
    }

    // Step completion calculation
    // 0: Placed/Confirmed
    // 1: Processing/Packing
    // 2: Delivering/Out for Delivery
    // 3: Delivered/Completed
    int currentStep = 0;
    if (lower == 'processing') {
      currentStep = 1;
    } else if (lower == 'shipped' || lower == 'delivering') {
      currentStep = 2;
    } else if (lower == 'completed' || lower == 'delivered') {
      currentStep = 3;
    }

    final steps = [
      _TimelineStepInfo(
        icon: Icons.check_circle_rounded,
        label: l10n.isKhmer ? 'បានបញ្ជាក់' : 'Confirmed',
        isCompleted: currentStep >= 0,
        isActive: currentStep == 0,
      ),
      _TimelineStepInfo(
        icon: Icons.inventory_2_rounded,
        label: l10n.isKhmer ? 'កំពុងរៀបចំ' : 'Packing',
        isCompleted: currentStep >= 1,
        isActive: currentStep == 1,
      ),
      _TimelineStepInfo(
        icon: Icons.local_shipping_rounded,
        label: l10n.isKhmer ? 'កំពុងដឹក' : 'Delivering',
        isCompleted: currentStep >= 2,
        isActive: currentStep == 2,
      ),
      _TimelineStepInfo(
        icon: Icons.verified_rounded,
        label: l10n.isKhmer ? 'បានទទួល' : 'Delivered',
        isCompleted: currentStep >= 3,
        isActive: currentStep == 3,
      ),
    ];

    final widgetContent = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: showCard
          ? BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 0.9,
              ),
            )
          : null,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _buildStepItem(
                step: steps[i],
                theme: theme,
                isDark: isDark,
                primary: primary,
              ),
            ),
            if (i < steps.length - 1)
              _buildConnector(
                isCompleted: currentStep > i,
                isNext: currentStep == i,
                primary: primary,
                isDark: isDark,
              ),
          ],
        ],
      ),
    );

    return widgetContent;
  }

  Widget _buildStepItem({
    required _TimelineStepInfo step,
    required ThemeData theme,
    required bool isDark,
    required Color primary,
  }) {
    final color = step.isCompleted
        ? primary
        : (step.isActive
            ? const Color(0xFFF59E0B)
            : (isDark ? Colors.grey[600]! : const Color(0xFF94A3B8)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: step.isActive ? 0.16 : 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: step.isActive ? 0.5 : 0.22),
              width: 1.2,
            ),
          ),
          child: Icon(step.icon, size: 16, color: color),
        ),
        const SizedBox(height: 5),
        Text(
          step.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10.5,
            fontWeight: step.isActive || step.isCompleted
                ? FontWeight.w700
                : FontWeight.w500,
            color: step.isActive || step.isCompleted
                ? theme.colorScheme.onSurface
                : (isDark ? Colors.grey[500] : const Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({
    required bool isCompleted,
    required bool isNext,
    required Color primary,
    required bool isDark,
  }) {
    return Container(
      width: 16,
      height: 2.2,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCompleted
            ? primary
            : (isNext
                ? primary.withValues(alpha: 0.45)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _TimelineStepInfo {
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _TimelineStepInfo({
    required this.icon,
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });
}
