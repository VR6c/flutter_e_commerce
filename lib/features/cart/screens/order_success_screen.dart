import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/screens/receipt_viewer_screen.dart';
import '../../orders/services/receipt_service.dart';

class OrderSuccessScreen extends ConsumerWidget {
  final dynamic orderId;
  final bool isPayWay;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.isPayWay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isAuthenticated = ref.watch(authStateProvider).valueOrNull != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(),

                // Delivery Cart illustration container
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF8EE),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        Positioned(
                          top: 24,
                          right: 28,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  l10n.orderSuccess,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  l10n.isKhmer
                      ? (isPayWay
                          ? 'ការទូទាត់តាម ABA PayWay ត្រូវបានបញ្ជាក់ជោគជ័យ។ ទំនិញរបស់អ្នកកំពុងត្រូវបានវេចខ្ចប់យ៉ាងយកចិត្តទុកដាក់ និងដឹកជញ្ជូនក្នុងពេលឆាប់ៗនេះ។'
                          : 'សូមអរគុណសម្រាប់ការបញ្ជាទិញ! ទំនិញរបស់អ្នកត្រូវបានកក់ទុក និងកំពុងដឹកជញ្ជូនទៅកាន់អាសយដ្ឋានរបស់អ្នកក្នុងពេលឆាប់ៗ។')
                      : (isPayWay
                          ? 'Your payment via ABA PayWay was confirmed. Your groceries are being packed with care and will be delivered shortly.'
                          : 'Thanks for your order! Your groceries have been reserved and will be delivered to your address soon.'),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Order Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.orderReference,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            '#$orderId',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              fontSize: 14,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.paymentType,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            isPayWay ? l10n.abaPayWay : l10n.cashOnDelivery,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.estimatedDelivery,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            l10n.today3045Mins,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Receipt Action Buttons
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.orderReceipt,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: 0,
                                  ),
                                ),
                                Text(
                                  l10n.officialInvoiceForThisOrder,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : const Color(0xFF64748B),
                                    fontSize: 11,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // View Receipt Button
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ReceiptViewerScreen.show(
                                    context,
                                    orderId: orderId,
                                  );
                                },
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  l10n.viewReceipt,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Download Receipt Button
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed: () => _handleDownloadReceipt(
                                  context,
                                  ref,
                                  l10n,
                                ),
                                icon: const Icon(
                                  Icons.file_download_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  l10n.downloadReceipt,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Primary Action Button: "Track Order" or "Continue Shopping"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isAuthenticated) {
                        context.go('/orders');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.orderSavedSignInAnytime,
                              style: const TextStyle(fontFamily: AppTheme.fontFamily, letterSpacing: 0),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.go('/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(
                      isAuthenticated
                          ? (l10n.trackOrder)
                          : l10n.continueShopping,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Button: Back to Home
                if (isAuthenticated)
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      l10n.backToHome,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadReceipt(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final file = await ReceiptService.downloadReceipt(
      context: context,
      ref: ref,
      orderId: orderId,
    );
    if (file != null && context.mounted) {
      ReceiptService.showFileDetailsBottomSheet(
        context,
        orderId: orderId,
        file: file,
      );
    }
  }
}
