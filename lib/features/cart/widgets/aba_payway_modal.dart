import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_e_commerce/core/localization/app_localizations.dart';

const String abaPayWayLogoSvg = '''
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

class AbaPayWayModal extends StatefulWidget {
  final String tranId;
  final dynamic orderId;
  final String? deeplink;
  final String? qrImageBase64;
  final bool initialShowQr;
  final Future<bool> Function() onCheckStatus;
  final ValueChanged<dynamic> onSuccess;
  final VoidCallback onCancel;

  const AbaPayWayModal({
    super.key,
    required this.tranId,
    required this.orderId,
    this.deeplink,
    this.qrImageBase64,
    required this.initialShowQr,
    required this.onCheckStatus,
    required this.onSuccess,
    required this.onCancel,
  });

  static Future<void> show({
    required BuildContext context,
    required String tranId,
    required dynamic orderId,
    String? deeplink,
    String? qrImageBase64,
    required bool initialShowQr,
    required Future<bool> Function() onCheckStatus,
    required ValueChanged<dynamic> onSuccess,
    required VoidCallback onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AbaPayWayModal(
        tranId: tranId,
        orderId: orderId,
        deeplink: deeplink,
        qrImageBase64: qrImageBase64,
        initialShowQr: initialShowQr,
        onCheckStatus: onCheckStatus,
        onSuccess: onSuccess,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<AbaPayWayModal> createState() => AbaPayWayModalState();
}

class AbaPayWayModalState extends State<AbaPayWayModal>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;
  late final ValueNotifier<int> _remainingSecondsNotifier;
  Uint8List? _qrBytes;
  bool _isPollingTimedOut = false;
  bool _isCheckingStatus = false;
  bool _isManualChecking = false;
  late bool _showQr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showQr = widget.initialShowQr;
    _remainingSecondsNotifier = ValueNotifier<int>(120);
    _decodeQrBytes();
    _startStatusPolling(durationSeconds: 120);
  }

  void _decodeQrBytes() {
    if (widget.qrImageBase64 == null || widget.qrImageBase64!.isEmpty) {
      _qrBytes = null;
      return;
    }
    try {
      String cleanedBase64 = widget.qrImageBase64!;
      if (cleanedBase64.startsWith('data:image/png;base64,')) {
        cleanedBase64 = cleanedBase64.replaceFirst('data:image/png;base64,', '');
      }
      _qrBytes = base64Decode(cleanedBase64);
    } catch (_) {
      _qrBytes = null;
    }
  }

  @override
  void didUpdateWidget(covariant AbaPayWayModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrImageBase64 != widget.qrImageBase64) {
      _decodeQrBytes();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPayment(silent: false);
    }
  }

  void _startStatusPolling({int durationSeconds = 120}) {
    _pollingTimer?.cancel();
    _remainingSecondsNotifier.value = durationSeconds;
    _isPollingTimedOut = false;

    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSecondsNotifier.value > 0) {
        final nextVal = _remainingSecondsNotifier.value - 1;
        _remainingSecondsNotifier.value = nextVal;

        // Auto-check payment status every 3 seconds
        if (nextVal % 3 == 0) {
          checkPayment(silent: true);
        }
      } else {
        timer.cancel();
        setState(() {
          _isPollingTimedOut = true;
          _isCheckingStatus = false;
          _isManualChecking = false;
        });
      }
    });
  }

  Future<void> checkPayment({bool silent = false}) async {
    if (_isCheckingStatus) return;

    _isCheckingStatus = true;
    if (!silent) {
      setState(() {
        _isManualChecking = true;
      });
    }

    try {
      final approved = await widget.onCheckStatus();
      if (!mounted) return;

      if (approved) {
        _pollingTimer?.cancel();
        Navigator.of(context, rootNavigator: true).pop();
        widget.onSuccess(widget.orderId);
        return;
      }
    } catch (_) {
      // Ignore transient errors
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _isManualChecking = false;
        });
      }
    }
  }

  String _formatRemainingTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _launchDeeplink(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  void _cancelPayment() {
    _pollingTimer?.cancel();
    Navigator.of(context).pop();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  SvgPicture.string(abaPayWayLogoSvg, height: 22),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _cancelPayment,
                  ),
                ],
              ),
              const Divider(),
              if (_showQr && widget.qrImageBase64 != null)
                _buildQrContent(theme, isDark)
              else
                _buildWaitingContent(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        if (!_isPollingTimedOut) ...[
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005C8A)),
                    backgroundColor: Color(0x1F005C8A),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005C8A).withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 28,
                    color: Color(0xFF005C8A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.waitingAbaPayment,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.waitingAbaPaymentSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF005C8A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Color(0xFF005C8A),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<int>(
                  valueListenable: _remainingSecondsNotifier,
                  builder: (context, seconds, _) {
                    return Text(
                      context.l10n.autoCheckingStatus(_formatRemainingTime(seconds)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF005C8A),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isManualChecking ? null : () => checkPayment(silent: false),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_isManualChecking ? context.l10n.checkingStatus : context.l10n.checkStatusNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005C8A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF005C8A).withValues(alpha: 0.65),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
            context.l10n.paymentTimeout,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.paymentTimeoutSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                checkPayment(silent: false);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.tryCheckingAgain),
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
                _pollingTimer?.cancel();
                Navigator.pop(context);
                context.push('/orders');
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(context.l10n.viewInMyOrders),
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
        if (widget.qrImageBase64 != null && widget.qrImageBase64!.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showQr = true;
                });
              },
              icon: const Icon(Icons.qr_code_rounded, size: 18),
              label: Text(context.l10n.payWithKhqr),
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
          onPressed: _cancelPayment,
          child: Text(
            context.l10n.cancelPayment,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
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
            child: _qrBytes != null
                ? Image.memory(
                    _qrBytes!,
                    fit: BoxFit.contain,
                    cacheWidth: 380,
                  )
                : Icon(
                    Icons.qr_code_2_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.scanKhqrInstructions,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isPollingTimedOut) ...[
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF005C8A),
              ),
              const SizedBox(width: 5),
              ValueListenableBuilder<int>(
                valueListenable: _remainingSecondsNotifier,
                builder: (context, seconds, _) {
                  return Text(
                    context.l10n.checkingPaymentStatus(_formatRemainingTime(seconds)),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF005C8A),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ] else ...[
              const Icon(
                Icons.hourglass_bottom_rounded,
                size: 14,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.qrValidityTimedOut,
                style: const TextStyle(
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
            widget.deeplink != null &&
            widget.deeplink!.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final launched = await _launchDeeplink(widget.deeplink!);
                if (!mounted) return;
                if (launched) {
                  setState(() {
                    _showQr = false;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.abaNotInstalled,
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(context.l10n.openAbaMobile),
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
                checkPayment(silent: false);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.restartStatusCheck),
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
          onPressed: _cancelPayment,
          child: Text(
            context.l10n.cancelPayment,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
