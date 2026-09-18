import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Widget? actionWidget;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'No Data Found',
    this.message = 'There is currently no data to display here.',
    this.actionLabel,
    this.onActionPressed,
    this.actionWidget,
    this.iconSize = 72,
    this.padding = const EdgeInsets.all(32.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 36,
              height: iconSize + 36,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 13.5,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionWidget != null) ...[
              const SizedBox(height: 24),
              actionWidget!,
            ] else if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
