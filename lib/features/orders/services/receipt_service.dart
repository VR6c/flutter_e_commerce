import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/orders_provider.dart';
import '../screens/receipt_viewer_screen.dart';

/// Service for directly downloading, saving, and sharing order receipts.
class ReceiptService {
  static const MethodChannel _channel =
      MethodChannel('com.tvr.ecommerce/file_share');

  /// Directly downloads the receipt PDF via the authenticated API,
  /// saves it to the device's Documents directory, and opens the native
  /// iOS / Android system Save to Files / Share sheet.
  static Future<File?> downloadReceipt({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic orderId,
    List<int>? existingBytes,
    bool fromViewerScreen = false,
  }) async {
    final l10n = context.l10n;
    try {
      // 1. Fetch binary PDF data with Bearer token authentication
      List<int> bytes;
      if (existingBytes != null && existingBytes.isNotEmpty) {
        bytes = existingBytes;
      } else {
        final repo = ref.read(orderRepositoryProvider);
        bytes = await repo.fetchReceiptBytes(orderId);
      }

      if (bytes.isEmpty) {
        throw Exception('Empty receipt PDF data received.');
      }

      // 2. Save directly to App Documents directory
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Order_Receipt_$orderId.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // 3. Trigger native system Save to Files / Share sheet if available
      try {
        await _channel.invokeMethod<bool>('shareFile', {
          'filePath': file.path,
        });
      } catch (_) {
        // Platform channel not compiled in current running hot-reload session
      }

      // 4. Show success feedback to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.isKhmer
                        ? 'បានទាញយកវិក្កយបត្រ $fileName'
                        : 'Receipt downloaded: $fileName',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: !fromViewerScreen
                ? SnackBarAction(
                    label: l10n.viewReceipt,
                    textColor: Colors.white,
                    onPressed: () {
                      ReceiptViewerScreen.show(context, orderId: orderId);
                    },
                  )
                : null,
          ),
        );
      }

      return file;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.couldNotOpenReceipt,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return null;
    }
  }

  /// Displays a clean modal sheet showing the exact downloaded file name,
  /// file size, and the iOS Files app path (On My iPhone > Flutter E Commerce).
  static void showFileDetailsBottomSheet(
    BuildContext context, {
    required dynamic orderId,
    required File file,
    bool fromViewerScreen = false,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fileName = 'Order_Receipt_$orderId.pdf';
    final fileSizeKb = file.existsSync()
        ? (file.lengthSync() / 1024).toStringAsFixed(1)
        : '24.0';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.isKhmer ? 'បានទាញយកវិក្កយបត្រ' : 'Receipt Downloaded',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fileName,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_rounded,
                          size: 24,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.isKhmer
                                    ? 'ទីតាំងផ្ទុកឯកសារ (Files App):'
                                    : 'Saved in Apple Files App:',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'On My iPhone > Flutter E Commerce',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$fileSizeKb KB',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!fromViewerScreen)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ReceiptViewerScreen.show(context, orderId: orderId);
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(l10n.viewReceipt),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (!fromViewerScreen)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.isKhmer ? 'យល់ព្រម' : 'Done',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
