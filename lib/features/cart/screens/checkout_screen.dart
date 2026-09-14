import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/api/providers.dart';
import '../../../core/api/app_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/delivery_location_provider.dart';
import '../../home/widgets/location_selection_sheet.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';

const String _abaPayWayLogoSvg = '''
<svg width="196" height="31" viewBox="0 0 196 31" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M15.5709 5.11267L25.0237 30.837H19.3634L17.5806 25.5494H7.39852L5.68665 30.837H0L9.33729 5.11267H15.5709ZM8.81867 21.212H16.1159L12.4754 10.2631L8.81867 21.212Z" fill="#055E7C"/>
<path d="M32.594 5.11267H44.9559C50.3894 5.11267 53.1952 7.43444 53.1952 11.6168C53.1952 14.191 52.1802 15.9502 50.0632 16.9163C52.8001 17.9917 54.117 19.9915 54.117 23.009C54.117 27.903 50.756 30.835 44.5609 30.835H32.594V5.11267ZM43.9369 15.0537C46.5199 15.0537 47.7679 14.2328 47.7679 12.2569C47.7679 10.281 46.4956 9.58128 43.8964 9.58128H37.7762V15.0537H43.9389H43.9369ZM44.1496 26.1895C47.1074 26.1895 48.5053 25.2115 48.5053 22.8579C48.5053 20.3473 47.1054 19.4508 44.1172 19.4508H37.7742V26.1895H44.1496Z" fill="#055E7C"/>
<path d="M75.0165 5.11267L84.4733 30.837H78.8171L77.0242 25.5494H66.8481L65.1322 30.837H59.4537L68.7788 5.11267H75.0145H75.0165ZM68.2703 21.214H75.5676L71.925 10.2651L68.2703 21.214Z" fill="#055E7C"/>
<path d="M91.9077 0H86.9077V10H91.9077V0Z" fill="#EB2227"/>
<path d="M193.08 5.29766C192.29 5.29766 191.573 5.60776 191.046 6.10869L179.343 15.3838L177.127 13.6524L167.585 6.19814L167.415 6.05502C167.269 5.93774 167.25 5.92184 167.015 5.75685C166.503 5.38314 165.928 5.14062 165.265 5.14062C163.719 5.14062 162.467 6.40487 162.467 7.96531C162.467 8.83398 162.856 9.61122 163.468 10.13L163.472 10.134C163.499 10.1559 163.525 10.1777 163.553 10.1996L174.42 18.9679L176.328 20.5084L176.337 28.1794V28.1933C176.351 29.7339 177.629 30.9782 179.201 30.9782C180.773 30.9782 182.019 29.7657 182.064 28.251L182.07 28.241V20.5144L193.65 11.4301L193.781 11.3227L194.12 11.0444C194.191 10.9848 194.286 10.9152 194.351 10.8536L194.807 10.4779C195.499 9.88951 196 9.11625 196 8.16807C196 6.58577 194.693 5.30363 193.08 5.30363V5.29766Z" fill="#00BCD4"/>
<path d="M165.632 26.5812L151.884 6.33331C151.357 5.61174 150.484 5.14062 149.512 5.14062C147.911 5.14062 146.613 6.41481 146.613 7.98519C146.613 8.6193 146.823 9.20372 147.18 9.67682L153.687 18.8705L141.313 18.8506C140.584 18.8705 139.435 19.3217 138.604 20.3315L134.247 26.4063C133.793 26.8933 133.517 27.5433 133.517 28.2549C133.517 29.7716 134.769 31.0001 136.315 31.0001C137.241 31.0001 138.061 30.5588 138.57 29.879L138.606 29.8591L142.535 24.7345H157.828L160.988 29.5888C161.46 30.4296 162.374 31.0001 163.421 31.0001C164.955 31.0001 166.199 29.7796 166.199 28.2748C166.199 27.7063 166.021 27.1795 165.719 26.7422C165.692 26.6846 165.664 26.6289 165.634 26.5812H165.632Z" fill="#00BCD4"/>
<path d="M128.119 5.1366C128.098 5.1366 128.078 5.1366 128.058 5.1366H106.734C105.129 5.1366 103.83 6.41277 103.83 7.98513C103.83 8.55762 104.005 9.09036 104.3 9.53563C104.704 10.0962 105.271 10.4977 105.994 10.7363C106.231 10.7979 106.478 10.8337 106.734 10.8337H128.244H128.289C128.366 10.8337 128.441 10.8376 128.516 10.8456C129.699 10.9649 130.623 11.9468 130.623 13.1395C130.623 14.4018 129.588 15.4275 128.305 15.4434H128.111H120.149H106.592C104.868 15.4434 103.83 16.7593 103.83 18.2582V28.1078C103.83 29.6642 105.117 30.9265 106.703 30.9265C108.289 30.9265 109.515 29.7199 109.572 28.2131V21.1723H128.121L128.202 21.1683C128.202 21.1683 128.206 21.1683 128.208 21.1683C132.614 21.051 136.151 17.5088 136.151 13.1554C136.151 8.80213 132.568 5.20816 128.117 5.1366H128.119Z" fill="#00BCD4"/>
</svg>
''';

class CheckoutScreen extends ConsumerStatefulWidget {
  final bool isGuest;

  const CheckoutScreen({super.key, this.isGuest = false});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
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

  Timer? _pollingTimer;
  String? _activeTranId;
  dynamic _activeOrderId;
  String? _activeQrImage;
  String? _activeDeeplink;
  bool _isCheckingStatus = false;
  bool _isModalOpen = false;
  void Function(void Function())? _modalSetState;
  int _pollingRemainingSeconds = 120;
  bool _isPollingTimedOut = false;

  String _formatRemainingTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _resetPaymentState();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _activeTranId != null &&
        _activeOrderId != null) {
      _checkPaymentStatus(silent: false);
    }
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
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/checkout', data: payload);
      final data = response.data;

      if (data is Map<String, dynamic> && data['status'] == true) {
        final orderId =
            data['data']?['order_id'] ??
            DateTime.now().millisecondsSinceEpoch % 100000;
        final abapayDeeplink = data['data']?['abapay_deeplink'] as String?;
        final qrImage = data['data']?['qrImage'] as String?;
        final tranId = data['data']?['tran_id']?.toString();

        if (_selectedGateway == 'abapayway' && tranId != null) {
          if (!mounted) return;
          _activeTranId = tranId;
          _activeOrderId = orderId;
          _activeQrImage = qrImage;
          _activeDeeplink = abapayDeeplink;

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
      _showErrorSnackbar(e.message);
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
      launched = await _launchDeeplink(abapayDeeplink);
    }

    if (!mounted) return;

    if (launched) {
      // Deeplink directly opened ABA Mobile app.
      // Do NOT open QR modal! Open payment status loading modal instead!
      _startStatusPolling();
      _showPaymentStatusModal();
    } else {
      // Deeplink failed or ABA Mobile is not installed on device.
      // Fallback to showing the KHQR modal.
      if (qrImageBase64 != null && qrImageBase64.isNotEmpty) {
        _startStatusPolling();
        _showPayWayQrModal();
      } else {
        _showErrorSnackbar(
          'Could not launch ABA Mobile and QR code is unavailable.',
        );
      }
    }
  }

  void _startStatusPolling({int durationSeconds = 120}) {
    _pollingTimer?.cancel();
    _pollingRemainingSeconds = durationSeconds;
    _isPollingTimedOut = false;
    _modalSetState?.call(() {});

    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_pollingRemainingSeconds > 0) {
        _pollingRemainingSeconds--;
        _modalSetState?.call(() {});

        // Check payment status every 3 seconds
        if (_pollingRemainingSeconds % 3 == 0) {
          _checkPaymentStatus(silent: true);
        }
      } else {
        timer.cancel();
        _isPollingTimedOut = true;
        _isCheckingStatus = false;
        _modalSetState?.call(() {});
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isCheckingStatus || _activeTranId == null || _activeOrderId == null) {
      return;
    }

    _isCheckingStatus = true;
    _modalSetState?.call(() {});
    if (!silent && mounted) {
      setState(() {});
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get<Map<String, dynamic>>(
        '/checkout/payment-status',
        queryParameters: {
          'tran_id': _activeTranId,
          'order_id': _activeOrderId.toString(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['approved'] == true) {
        final successOrderId = _activeOrderId;
        _resetPaymentState();

        if (mounted) {
          if (_isModalOpen) {
            Navigator.of(context, rootNavigator: true).pop();
            _isModalOpen = false;
          }
          _onOrderSuccess(successOrderId);
        }
        return;
      }
    } catch (_) {
      // Silently ignore transient network errors during polling
    } finally {
      _isCheckingStatus = false;
      _modalSetState?.call(() {});
      if (!silent && mounted) {
        setState(() {});
      }
    }
  }

  void _resetPaymentState() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _activeTranId = null;
    _activeOrderId = null;
    _activeQrImage = null;
    _activeDeeplink = null;
    _isCheckingStatus = false;
    _pollingRemainingSeconds = 120;
    _isPollingTimedOut = false;
    _modalSetState = null;
  }

  void _showPaymentStatusModal() {
    if (_isModalOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isModalOpen = false;
    }

    _isModalOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            _modalSetState = setModalState;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.string(_abaPayWayLogoSvg, height: 22),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _resetPaymentState();
                              Navigator.pop(sheetContext);
                              _showErrorSnackbar('Payment was cancelled.');
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 24),
                      if (!_isPollingTimedOut) ...[
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF005C8A).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 46,
                                height: 46,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFF005C8A)),
                                ),
                              ),
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 24,
                                color: Color(0xFF005C8A),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Waiting for ABA Payment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please complete the payment in the ABA Mobile app.\nYour order will be confirmed automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF005C8A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFF005C8A)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Checking status... (${_formatRemainingTime(_pollingRemainingSeconds)})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF005C8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isCheckingStatus
                                ? null
                                : () async {
                                    await _checkPaymentStatus(silent: false);
                                  },
                            icon: _isCheckingStatus
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              _isCheckingStatus
                                  ? 'Checking...'
                                  : 'Check Status Now',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005C8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 38,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Payment Confirmation Timeout',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We haven\'t received confirmation from ABA Pay yet.\nIf you already paid, check your orders or try checking status again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _startStatusPolling(durationSeconds: 60);
                              _checkPaymentStatus(silent: false);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Checking Again (60s)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005C8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _resetPaymentState();
                              Navigator.pop(sheetContext);
                              context.push('/orders');
                            },
                            icon: const Icon(Icons.receipt_long_rounded,
                                size: 18),
                            label: const Text('View in My Orders'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005C8A),
                              side: const BorderSide(color: Color(0xFF005C8A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_activeQrImage != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _showPayWayQrModal();
                            },
                            icon: const Icon(Icons.qr_code_rounded, size: 18),
                            label: const Text('Pay with KHQR Code instead'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005C8A),
                              side: const BorderSide(color: Color(0xFF005C8A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _resetPaymentState();
                          Navigator.pop(sheetContext);
                          _showErrorSnackbar('Payment was cancelled.');
                        },
                        child: Text(
                          'Cancel Payment',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _isModalOpen = false;
      _modalSetState = null;
    });
  }

  void _showPayWayQrModal() {
    if (_activeQrImage == null) return;

    if (_isModalOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isModalOpen = false;
    }

    _isModalOpen = true;

    String cleanedBase64 = _activeQrImage!;
    if (cleanedBase64.startsWith('data:image/png;base64,')) {
      cleanedBase64 = cleanedBase64.replaceFirst('data:image/png;base64,', '');
    }
    final imageBytes = base64Decode(cleanedBase64);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            _modalSetState = setModalState;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.string(_abaPayWayLogoSvg, height: 22),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _resetPaymentState();
                              Navigator.pop(sheetContext);
                              _showErrorSnackbar('Payment was cancelled.');
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          width: 190,
                          height: 190,
                          child: Image.memory(imageBytes, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Scan KHQR code or pay via ABA Mobile',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isPollingTimedOut) ...[
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF005C8A)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Checking payment status... (${_formatRemainingTime(_pollingRemainingSeconds)})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF005C8A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            const Icon(Icons.hourglass_bottom_rounded,
                                size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            const Text(
                              'QR validity timed out',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isPollingTimedOut &&
                          _activeDeeplink != null &&
                          _activeDeeplink!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              final launched =
                                  await _launchDeeplink(_activeDeeplink!);
                              if (launched) {
                                _showPaymentStatusModal();
                              } else {
                                _showErrorSnackbar(
                                  'Could not launch ABA Mobile. Ensure the app is installed.',
                                );
                                _showPayWayQrModal();
                              }
                            },
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 18),
                            label: const Text('Open ABA Mobile App'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005C8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      if (_isPollingTimedOut)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _startStatusPolling(durationSeconds: 60);
                              _checkPaymentStatus(silent: false);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Restart Status Check (60s)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005C8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _resetPaymentState();
                          Navigator.pop(sheetContext);
                          _showErrorSnackbar('Payment was cancelled.');
                        },
                        child: Text(
                          'Cancel Payment',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _isModalOpen = false;
      _modalSetState = null;
    });
  }

  Future<bool> _launchDeeplink(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  void _onOrderSuccess(dynamic orderId) {
    _resetPaymentState();
    ref.read(cartProvider.notifier).clear();
    ref.read(couponProvider.notifier).removeCoupon();

    if (!mounted) return;
    if (_isModalOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isModalOpen = false;
    }
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
          widget.isGuest ? 'Guest Checkout' : 'Checkout',
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
                        'Delivery Address',
                        style: TextStyle(
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
                            'Change',
                            style: TextStyle(
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
                                    : 'Select delivery address',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_cityController.text}, ${_countryController.text}',
                                style: TextStyle(
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
                    decoration: const InputDecoration(
                      hintText: 'Detailed street address',
                      prefixIcon: Icon(Icons.home_outlined, size: 18),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
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
                    'Contact Information',
                    style: TextStyle(
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
                          decoration: const InputDecoration(
                            hintText: 'First Name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            hintText: 'Last Name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Phone is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Valid email required'
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
                    'Payment Method',
                    style: TextStyle(
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
                          title: 'Credit Card',
                          icon: Icons.credit_card_rounded,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _paymentPill(
                          id: 'cod',
                          title: 'Cash on Del.',
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
                      decoration: const InputDecoration(
                        hintText: 'Card Number',
                        prefixIcon: Icon(Icons.credit_card_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(hintText: 'MM/YY'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(hintText: 'CVV'),
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
                          'Save card for future payments',
                          style: TextStyle(
                            fontSize: 12,
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
                children: [
                  _priceRow(
                    'Subtotal',
                    '\$${totalAmount.toStringAsFixed(2)}',
                    theme,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  if (couponState.isApplied) ...[
                    _priceRow(
                      'Coupon Discount',
                      '-\$${couponState.discountAmount.toStringAsFixed(2)}',
                      theme,
                      isDark,
                      valueColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _priceRow(
                    'Delivery',
                    'FREE',
                    theme,
                    isDark,
                    valueColor: theme.colorScheme.primary,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _priceRow(
                    'Total Amount',
                    '\$${finalTotal.toStringAsFixed(2)}',
                    theme,
                    isDark,
                    isBold: true,
                    fontSize: 18,
                    valueColor: theme.colorScheme.primary,
                  ),
                ],
              ),
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
                      'Pay Now · \$${finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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

  Widget _priceRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool isBold = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (isBold
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
