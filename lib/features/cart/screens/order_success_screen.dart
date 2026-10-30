import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/models/order.dart';
import '../../orders/providers/orders_provider.dart';
import '../../orders/screens/order_detail_bottom_sheet.dart';
import '../../orders/screens/receipt_viewer_screen.dart';
import '../../orders/services/receipt_service.dart';
import '../../orders/widgets/order_delivery_timeline.dart';
import '../../orders/widgets/rate_order_products_sheet.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final dynamic orderId;
  final bool isPayWay;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.isPayWay,
  });

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  Order? _preloadedOrder;
  bool _isDownloadingReceipt = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    _preloadOrder();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _preloadOrder() {
    final parsedId = int.tryParse('${widget.orderId}');
    if (parsedId != null) {
      ref
          .read(orderRepositoryProvider)
          .fetchOrderDetail(parsedId)
          .then((order) {
        if (mounted && order != null) {
          setState(() => _preloadedOrder = order);
        }
      }).catchError((_) {});
    }
  }

  Future<void> _handleDownloadReceipt() async {
    if (_isDownloadingReceipt) return;
    setState(() => _isDownloadingReceipt = true);
    try {
      final file = await ReceiptService.downloadReceipt(
        context: context,
        ref: ref,
        orderId: widget.orderId,
      );
      if (!mounted) return;
      if (file != null) {
        ReceiptService.showFileDetailsBottomSheet(
          context,
          orderId: widget.orderId,
          file: file,
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingReceipt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isAuthenticated = ref.watch(authStateProvider).valueOrNull != null;
    final orderIdInt = int.tryParse('${widget.orderId}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),

                      // 1. Celebratory Hero Illustration
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildCelebrationHero(theme, isDark),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Order Confirmed Chip Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.isKhmer
                                  ? 'ការបញ្ជាទិញបានបញ្ជាក់'
                                  : 'ORDER CONFIRMED',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                letterSpacing: 0.6,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        l10n.orderSuccess,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        l10n.isKhmer
                            ? (widget.isPayWay
                                  ? 'ការទូទាត់តាម ABA PayWay ត្រូវបានបញ្ជាក់ជោគជ័យ។ ទំនិញរបស់អ្នកកំពុងត្រូវបានវេចខ្ចប់យ៉ាងយកចិត្តទុកដាក់ និងដឹកជញ្ជូនក្នុងពេលឆាប់ៗនេះ។'
                                  : 'សូមអរគុណសម្រាប់ការបញ្ជាទិញ! ទំនិញរបស់អ្នកត្រូវបានកក់ទុក និងកំពុងដឹកជញ្ជូនទៅកាន់អាសយដ្ឋានរបស់អ្នកក្នុងពេលឆាប់ៗ។')
                            : (widget.isPayWay
                                  ? 'Your payment via ABA PayWay was confirmed. Your groceries are being packed with care and will be delivered shortly.'
                                  : 'Thanks for your order! Your groceries have been reserved and will be delivered to your address soon.'),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // 2. Delivery Progress Tracker Stepper
                      const OrderDeliveryTimeline(status: 'confirmed'),
                      const SizedBox(height: 16),

                      // 3. Order Reference & Details Card
                      _buildOrderInfoCard(context, theme, isDark, l10n),
                      const SizedBox(height: 14),

                      // 4. Receipt Action Card
                      _buildReceiptCard(context, theme, isDark, l10n),
                      const SizedBox(height: 14),

                      // 5. Rate Products Banner Card
                      if (isAuthenticated && orderIdInt != null)
                        _buildRateProductsCard(
                          context,
                          theme,
                          isDark,
                          l10n,
                          orderIdInt,
                        ),

                      const Spacer(),
                      const SizedBox(height: 16),

                      // Primary Action: Track Order
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (isAuthenticated) {
                              context.go('/orders');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.orderSavedSignInAnytime,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              context.go('/home');
                            }
                          },
                          icon: Icon(
                            isAuthenticated
                                ? Icons.route_rounded
                                : Icons.shopping_bag_outlined,
                            size: 19,
                            color: Colors.white,
                          ),
                          label: Text(
                            isAuthenticated
                                ? l10n.trackOrder
                                : l10n.continueShopping,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Action: Back to Home
                      if (isAuthenticated)
                        TextButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                          label: Text(
                            l10n.backToHome,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHero(ThemeData theme, bool isDark) {
    final primary = theme.colorScheme.primary;

    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient outer soft ring
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
            // Inner circle with soft shadow
            Container(
              width: 114,
              height: 114,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEBF8EE),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.2 : 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 54,
                  color: primary,
                ),
              ),
            ),
            // Verified checkmark badge
            Positioned(
              top: 14,
              right: 18,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildOrderInfoCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Reference Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tag_rounded,
                  size: 17,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.orderReference,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '#${widget.orderId}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '${widget.orderId}'));
                  AppSnackBar.showSuccess(
                    context,
                    l10n.isKhmer
                        ? 'បានចម្លងលេខកូដបញ្ជាទិញ'
                        : 'Order reference copied to clipboard',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.8),
          ),

          // Payment Type Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isPayWay
                      ? Icons.account_balance_wallet_rounded
                      : Icons.payments_rounded,
                  size: 17,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.paymentType,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: widget.isPayWay
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.isPayWay ? l10n.abaPayWay : l10n.cashOnDelivery,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: widget.isPayWay
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.onSurface,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.8),
          ),

          // Estimated Delivery Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 17,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.estimatedDelivery,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                l10n.today3045Mins,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (_preloadedOrder != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 0.8),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => OrderDetailBottomSheet.show(context, _preloadedOrder!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.viewFullDetails,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderReceipt,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.officialInvoiceForThisOrder,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // View Receipt
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ReceiptViewerScreen.show(
                        context,
                        orderId: widget.orderId,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      l10n.viewReceipt,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Download Receipt
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.tonalIcon(
                    onPressed: _isDownloadingReceipt
                        ? null
                        : _handleDownloadReceipt,
                    icon: _isDownloadingReceipt
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(
                      l10n.downloadReceipt,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      elevation: 0,
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
    );
  }

  Widget _buildRateProductsCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    int orderIdInt,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => RateOrderProductsSheet.show(
        context,
        orderIdInt,
        initialOrder: _preloadedOrder,
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF2C2214),
                    const Color(0xFF1E1A14),
                  ]
                : [
                    const Color(0xFFFFFBEB),
                    const Color(0xFFFEF3C7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rateYourProducts,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.rateYourProductsDesc,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5,
                      color: isDark
                          ? Colors.grey[300]
                          : const Color(0xFF78350F).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
