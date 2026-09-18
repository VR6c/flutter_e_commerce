import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/app_exception.dart';
import '../../../shared/widgets/price_breakdown_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/delivery_location_provider.dart';
import '../../home/widgets/location_selection_sheet.dart';
import '../../orders/providers/orders_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';
import '../widgets/aba_payway_modal.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final bool isGuest;

  const CheckoutScreen({super.key, this.isGuest = false});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Phnom Penh');
  final _countryController = TextEditingController(text: 'Cambodia');

  String _selectedGateway = 'abapayway'; // 'abapayway', 'card', 'cod'
  bool _isSubmitting = false;
  bool _saveCardForFuture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedLocation = ref
          .read(deliveryLocationProvider)
          .selectedLocation;
      if (selectedLocation != null) {
        setState(() {
          _addressController.text = selectedLocation.street;
          _cityController.text = selectedLocation.city;
          _countryController.text = selectedLocation.country;
        });
      } else {
        _addressController.text = 'Street 2004, Sen Sok';
      }

      if (!widget.isGuest) {
        final customer = ref.read(authStateProvider).valueOrNull;
        if (customer != null) {
          final nameParts = customer.name.split(' ');
          setState(() {
            _firstNameController.text = nameParts.isNotEmpty
                ? nameParts[0]
                : '';
            _lastNameController.text = nameParts.length > 1
                ? nameParts.sublist(1).join(' ')
                : '';
            _emailController.text = customer.email;
            _phoneController.text = '+855 12 345 678';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final cartItems = ref.read(cartProvider);
    final cartPayload = cartItems
        .map(
          (item) => {
            'product_id': item.product.id,
            'quantity': item.quantity,
            if (item.variantId != null) 'variant_id': item.variantId,
          },
        )
        .toList();

    final couponState = ref.read(couponProvider);
    final payload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'gateway': _selectedGateway,
      'cart': cartPayload,
      if (couponState.isApplied) 'coupon_code': couponState.code,
    };

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final data = await orderRepo.submitCheckout(payload);

      if (data['status'] == true) {
        final orderId =
            data['data']?['order_id'] ??
            DateTime.now().millisecondsSinceEpoch % 100000;
        final abapayDeeplink = data['data']?['abapay_deeplink'] as String?;
        final qrImage = data['data']?['qrImage'] as String?;
        final tranId = data['data']?['tran_id']?.toString();

        if (_selectedGateway == 'abapayway' && tranId != null) {
          if (!mounted) return;
          await _startPaymentFlow(
            abapayDeeplink: abapayDeeplink,
            qrImageBase64: qrImage,
            tranId: tranId,
            orderId: orderId,
          );
        } else {
          _onOrderSuccess(orderId);
        }
      } else {
        _showErrorSnackbar('Failed to create order. Please try again.');
      }
    } on AppException catch (e) {
      if (e is TimeoutException) {
        _showErrorSnackbar(
          'Order processing took longer than expected. Please check your Orders or try again.',
        );
      } else {
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred during checkout.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _startPaymentFlow({
    String? abapayDeeplink,
    String? qrImageBase64,
    required String tranId,
    required dynamic orderId,
  }) async {
    bool launched = false;
    if (abapayDeeplink != null && abapayDeeplink.isNotEmpty) {
      try {
        launched = await launchUrl(
          Uri.parse(abapayDeeplink),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }
    }

    if (!mounted) return;

    final initialShowQr = !launched;
    if (initialShowQr && (qrImageBase64 == null || qrImageBase64.isEmpty)) {
      _showErrorSnackbar(
        'Could not launch ABA Mobile and QR code is unavailable.',
      );
      return;
    }

    await AbaPayWayModal.show(
      context: context,
      tranId: tranId,
      orderId: orderId,
      deeplink: abapayDeeplink,
      qrImageBase64: qrImageBase64,
      initialShowQr: initialShowQr,
      onCheckStatus: () => ref
          .read(orderRepositoryProvider)
          .checkPaymentStatus(tranId: tranId, orderId: orderId.toString()),
      onSuccess: (successId) => _onOrderSuccess(successId),
      onCancel: () => _showErrorSnackbar('Payment was cancelled.'),
    );
  }

  void _onOrderSuccess(dynamic orderId) {
    ref.read(cartProvider.notifier).clear();
    ref.read(couponProvider.notifier).removeCoupon();

    if (!mounted) return;
    context.go(
      '/order-success',
      extra: {'orderId': orderId, 'isPayWay': _selectedGateway == 'abapayway'},
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalAmount = ref.watch(cartTotalAmountProvider);
    final couponState = ref.watch(couponProvider);

    final double discount = couponState.isApplied
        ? couponState.discountAmount
        : 0.0;
    final double finalTotal = (totalAmount - discount).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 6.0, bottom: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          widget.isGuest
              ? (context.l10n.guestCheckout)
              : context.l10n.checkoutTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // 1. Delivery Address Card (Matching mockup)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.shippingAddress,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final loc = await LocationSelectionSheet.show(
                            context,
                          );
                          if (loc != null) {
                            setState(() {
                              _addressController.text = loc.street;
                              _cityController.text = loc.city;
                              _countryController.text = loc.country;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            context.l10n.change,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final loc = await LocationSelectionSheet.show(context);
                      if (loc != null) {
                        setState(() {
                          _addressController.text = loc.street;
                          _cityController.text = loc.city;
                          _countryController.text = loc.country;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _addressController.text.isNotEmpty
                                    ? _addressController.text
                                    : (context.l10n.selectDeliveryAddress),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_cityController.text}, ${_countryController.text}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.grey[500]
                              : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(fontFamily: AppTheme.fontFamily),
                    decoration: InputDecoration(
                      hintText: context.l10n.detailedStreetAddress,
                      prefixIcon: const Icon(Icons.home_outlined, size: 18),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (context.l10n.addressIsRequired)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Contact Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.contactInformation,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          style: const TextStyle(fontFamily: AppTheme.fontFamily),
                          decoration: InputDecoration(
                            hintText: context.l10n.firstName,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (context.l10n.required)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          style: const TextStyle(fontFamily: AppTheme.fontFamily),
                          decoration: InputDecoration(
                            hintText: context.l10n.lastName,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (context.l10n.required)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontFamily: AppTheme.fontFamily),
                    decoration: InputDecoration(
                      hintText: context.l10n.phoneNumber,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (context.l10n.phoneIsRequired)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontFamily: AppTheme.fontFamily),
                    decoration: InputDecoration(
                      hintText: context.l10n.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? (context.l10n.validEmailRequired)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Payment Method Selection (Matching mockup)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.paymentMethod,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _paymentPill(
                          id: 'abapayway',
                          title: 'ABA Pay',
                          icon: Icons.qr_code_rounded,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _paymentPill(
                          id: 'card',
                          title: context.l10n.creditCard1,
                          icon: Icons.credit_card_rounded,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _paymentPill(
                          id: 'cod',
                          title: context.l10n.cashOnDel,
                          icon: Icons.payments_outlined,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedGateway == 'card') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      style: const TextStyle(fontFamily: AppTheme.fontFamily),
                      decoration: InputDecoration(
                        hintText: context.l10n.cardNumber,
                        prefixIcon: const Icon(Icons.credit_card_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontFamily: AppTheme.fontFamily),
                            decoration: InputDecoration(
                              hintText: context.l10n.mmyy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontFamily: AppTheme.fontFamily),
                            decoration: const InputDecoration(hintText: 'CVV'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: _saveCardForFuture,
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (v) =>
                              setState(() => _saveCardForFuture = v),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.saveCardForFuturePayments,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            letterSpacing: 0,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Price Summary
            PriceBreakdownCard(
              subtotal: totalAmount,
              discount: couponState.isApplied ? couponState.discountAmount : null,
              couponCode: couponState.isApplied ? couponState.code : null,
              deliveryFee: 0.0,
              total: finalTotal,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      context.l10n.payNowAmount(finalTotal.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentPill({
    required String id,
    required String title,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedGateway == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedGateway = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
