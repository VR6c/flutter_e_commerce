import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_e_commerce/core/localization/app_localizations.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (error, stackTrace) {
        final theme = Theme.of(context);
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () =>
          loading ??
          const Center(
            child: CircularProgressIndicator(),
          ),
    );
  }
}
