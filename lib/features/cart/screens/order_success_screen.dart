import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

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

                // Delivery Cart illustration container (matching mockup)
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
                  'Order Placed Successfully',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  isPayWay
                      ? 'Your payment via ABA PayWay was confirmed. Your groceries are being packed with care and will be delivered shortly.'
                      : 'Thanks for your order! Your groceries have been reserved and will be delivered to your address soon.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
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
                          Text('Order Reference', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 13)),
                          Text('#$orderId', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Type', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 13)),
                          Text(isPayWay ? 'ABA PayWay' : 'Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimated Delivery', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 13)),
                          const Text('Today (30-45 mins)', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF10B981), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Primary Action Button: "Track Order" or "View Orders"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isAuthenticated) {
                        context.go('/orders');
                      } else {
                        // For guests, go home with feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order saved! Sign in anytime to see full order tracking history.'),
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
                      isAuthenticated ? 'Track Order' : 'Continue Shopping',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Button: Back to Home
                if (isAuthenticated)
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
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
}
