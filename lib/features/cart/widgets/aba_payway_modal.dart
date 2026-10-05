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

const String khqrLogoWhiteSvg = '''
<svg version="1.1" width="3000" height="710" viewBox="0 0 3000 710" xmlns="http://www.w3.org/2000/svg">
<path fill="#FFFFFF" d="m 0,0.03316065 h 130.12116 l 0.014,318.13267935 C 233.74068,213.55008 443.94173,2.5596428 444.48677,1.0664481 444.9679,-0.25167388 599.68926,-0.32516983 599.68926,0.99272374 486.57317,115.28505 371.72975,227.87418 257.21308,340.76853 c 20.97523,21.33678 282.3634,288.92492 357.65314,368.20425 0.65411,0.68876 -1.66382,0.99992 -77.17034,0.99992 H 459.73294 L 336.53629,585.72505 C 192.18995,440.14727 131.5997,379.75815 130.74116,379.75815 c -0.97346,110.06303 -0.62,220.14479 -0.62,330.21455 H 0 Z M 1208.4296,400.10055 H 842.95884 V 709.9727 H 716.79789 L 716.22858,0.03316065 H 842.95884 V 297.25838 H 1208.4296 V 0.10393571 L 1335.1563,0 v 709.9727 h -126.7267 z m 1514.243,188.60833 c -66.7198,-66.68699 -121.2089,-121.26394 -121.0692,-121.29991 0.1397,-0.036 35.4501,0.18884 78.4672,0.49963 l 78.2133,0.56505 86.4183,85.46964 c 137.7689,136.25637 155.0701,156.03188 154.7403,156.02941 -0.4084,-0.003 -103.6312,-0.51832 -155.4465,0 z M 1560.4467,709.97304 c -16.1379,-0.55379 -32.9532,-10.24556 -46.6705,-19.51539 -6.9569,-4.70134 -19.2747,-16.38202 -26.5809,-25.20617 -5.9447,-7.17977 -15.0496,-25.92873 -18.2971,-37.67776 l -3.055,-11.05251 -0.3309,-256.54041 c -0.359,-278.392633 -0.5867,-266.806561 5.6132,-285.669744 6.3968,-19.462404 20.5256,-39.027764 37.2996,-51.652247 11.1554,-8.39579 20.5183,-13.2107146 35.4908,-18.2513305 l 11.3149,-3.8092509 261.205,-0.29674884 261.205,-0.29674882 11.3309,2.86097216 c 14.8478,3.7488926 26.437,8.6527199 36.7824,15.5638289 20.3137,13.570359 35.5357,32.794807 42.7843,54.033877 6.4483,18.89392 6.1728,5.744005 6.1777,294.858942 v 266.14221 l -55.4189,-55.344 -55.4191,-55.344 -0.3093,-175.76404 c -0.291,-167.92384 -0.3987,-176.04133 -2.4096,-181.97982 -8.8441,-26.11777 -26.8665,-43.73799 -52.2413,-51.0754 l -9.0122,-2.60596 h -181.6039 -181.6039 l -7.3546,2.62867 c -12.3916,4.42895 -21.5422,10.21361 -30.5502,19.31286 -9.677,9.77482 -15.9266,19.7384 -19.5545,31.17478 l -2.5095,7.91094 v 181.38648 c 0,143.66042 0.3021,182.67929 1.4523,187.60223 0.7989,3.41864 3.6817,10.79277 6.4062,16.38694 8.578,17.61255 21.6642,29.51025 40.3928,36.72405 7.7117,2.97044 11.4807,3.67874 23.4647,4.40965 7.8524,0.47892 86.6496,0.72975 175.1047,0.55739 88.4552,-0.17235 162.086,0.0394 163.6242,0.47031 1.5395,0.43146 27.3682,25.03821 57.466,54.74757 l 54.6697,55.30949 h -264.6848 c -145.5766,0 -272.4039,0.0612 -274.1782,3.4e-4 z m 825.7135,-1.19632 c -26.9307,-3.11842 -54.2309,-19.77939 -71.1259,-41.95624 -11.6294,-15.26477 -17.997,-29.27579 -21.0351,-46.28374 -1.9276,-10.79088 -2.2975,-251.84349 -0.4287,-279.39581 3.9643,-58.45084 14.914,-100.14281 38.5348,-146.72478 23.4952,-46.33445 54.5203,-84.65461 93.8058,-115.863057 56.046,-44.522955 118.0676,-69.6753622 189.5243,-76.8600649 50.7725,-5.1049871 107.4757,2.901448 158.9994,22.4505889 18.2153,6.911221 49.0282,22.704492 65.0829,33.358531 28.5306,18.933106 61.4883,48.706502 81.5007,73.626512 34.6076,43.09443 60.4913,97.70145 71.1609,150.12886 4.2544,20.90466 9.2611,68.41547 7.4337,70.54076 -0.4059,0.47222 -25.4026,0.7265 -55.5478,0.56508 l -54.8096,-0.29351 -0.8411,-12.43146 c -1.7656,-26.10028 -7.7173,-54.37893 -14.9847,-71.19845 -0.8057,-1.86472 -3.1133,-7.20461 -5.1278,-11.86641 -18.9374,-43.82127 -52.4615,-82.6438 -93.4721,-108.24536 -72.0624,-44.98604 -158.5339,-49.629366 -235.2042,-12.62994 -60.7818,29.33194 -108.1942,85.64793 -126.5514,150.31634 -9.6873,34.12675 -8.9807,16.73362 -9.4418,231.33736 l -0.4139,192.62077 c -6.3032,-0.0934 -17.0584,-1.19598 -17.0584,-1.19598 z M 1715.9021,485.02273 c -9.8918,-3.24648 -19.6413,-11.95632 -24.217,-21.63467 l -2.9387,-6.21574 V 354.8952 252.61809 l 2.8287,-5.5517 c 4.2081,-8.259 11.6883,-15.94802 19.0063,-19.53718 l 6.4522,-3.16448 h 101.2682 101.2682 l 6.7317,2.70833 c 8.4892,3.41539 16.2362,10.59855 20.5044,19.01219 l 3.3141,6.53284 0.5658,116.21582 c 0.3111,63.9187 0.3536,116.42756 0.094,116.68633 -0.7905,0.78894 -232.4534,0.29825 -234.8781,-0.49751 z"/>
</svg>
''';

const String bakongCenterEmblemSvg = '''
<svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="30" cy="30" r="28" fill="#E1251B" stroke="white" stroke-width="3"/>
  <g transform="translate(30, 30) scale(0.66) translate(-29.7, -38.7)">
    <path fill="white" d="M5.12,40.79c.56.55,1.12,1.07,1.66,1.63,1.92,2,3.82,4,5.74,5.95a1,1,0,0,1,.23.73v3.18q0,3.57,0,7.13c0,.32.09.42.4.42q5.06,0,10.11,0a.73.73,0,0,1,.46.25c1,1,2,2.06,3,3.09L31,67.72l1-1q3.18-3.32,6.37-6.64a1,1,0,0,1,.65-.24H49c.3,0,.36-.11.36-.4,0-3.45,0-6.89,0-10.34a1,1,0,0,1,.31-.8c1.56-1.6,3.1-3.21,4.66-4.81a.68.68,0,0,1,.44-.23c1.55,0,3.11,0,4.67,0l.2,0c-.06.08-.09.16-.14.21l-6.18,6.43a.93.93,0,0,0-.28.71c0,4.14,0,8.29,0,12.43,0,.59,0,.59-.58.59h-12a.77.77,0,0,0-.52.22c-2,2-3.92,4.08-5.88,6.12-.93,1-1.87,1.94-2.8,2.92-.18.19-.29.15-.46,0l-3-3.1-5.75-6a.59.59,0,0,0-.4-.16H9.6c-.53,0-.54,0-.54-.56q0-6.24,0-12.5a.87.87,0,0,0-.25-.65C7,48.06,5.18,46.16,3.36,44.27L.13,40.88,0,40.72c.13-.15.24-.3.37-.44l5.68-5.91c.93-1,1.86-1.92,2.76-2.9a1,1,0,0,0,.24-.6q0-6.3,0-12.58c0-.49,0-.49.5-.49q6,0,12,0a.87.87,0,0,0,.67-.29l8.26-8.6c.18-.19.34-.39.54-.63L32.69,10c2.42,2.52,4.84,5,7.27,7.56a.85.85,0,0,0,.55.23l12.07,0c.49,0,.49,0,.49.53q0,6.24,0,12.5a.9.9,0,0,0,.26.68c2,2.08,4,4.17,6,6.26.13.13.24.28.36.42l0,.1H58.54c-1.18,0-2.36,0-3.54,0a.92.92,0,0,1-.61-.26c-1.59-1.63-3.17-3.28-4.74-4.93a1,1,0,0,1-.25-.59q0-5.22,0-10.42c0-.36-.09-.46-.42-.45H39a.84.84,0,0,1-.54-.24Q34.88,17.7,31.35,14c-.2-.21-.33-.25-.56,0-1.42,1.51-2.87,3-4.31,4.5-.92,1-1.84,1.93-2.78,2.88a.9.9,0,0,1-.58.23c-3.29,0-6.58,0-9.86,0h-.48c0,.2,0,.37,0,.54,0,3.36,0,6.72,0,10.09a1.27,1.27,0,0,1-.38,1c-2.35,2.42-4.68,4.87-7,7.3Z"/>
    <path fill="white" d="M43.88,43.3c-.29.91-.58,1.78-.85,2.66a3.39,3.39,0,0,0-.17.95q0,2.85,0,5.7c0,.35-.13.4-.41.4-1.83,0-3.65,0-5.48,0a4.42,4.42,0,0,0-1.56.47,12.25,12.25,0,0,1-7.45.39c-.69-.18-1.34-.48-2-.71a2.29,2.29,0,0,0-.68-.14c-1.84,0-3.69,0-5.54,0-.36,0-.45-.11-.45-.48,0-1.92,0-3.85,0-5.77a1.82,1.82,0,0,0-.14-.7,13.8,13.8,0,0,1-.66-8.65c.17-.66.43-1.29.63-1.94a3.27,3.27,0,0,0,.17-.87c0-1.9,0-3.8,0-5.7,0-.47,0-.47.47-.47h5.54a1.75,1.75,0,0,0,.71-.16A12.19,12.19,0,0,1,35.5,28a5.59,5.59,0,0,0,2.17.42c1.59,0,3.18,0,4.77,0,.32,0,.42.1.42.44,0,1.9,0,3.8,0,5.7a3.47,3.47,0,0,0,.18,1c.23.82.49,1.62.74,2.43.08.26,0,.35-.26.35-1.06,0-2.13,0-3.19,0A.45.45,0,0,1,40,38c-.26-.63-.51-1.26-.73-1.89a2.51,2.51,0,0,1-.11-.72c0-.92,0-1.85,0-2.77,0-.29-.08-.39-.36-.38-.91,0-1.82,0-2.73,0a2.7,2.7,0,0,1-1-.3,9,9,0,0,0-8.37.17,1.41,1.41,0,0,1-.64.13c-.93,0-1.85,0-2.77,0-.28,0-.37.08-.36.37,0,.94,0,1.88,0,2.82a2.3,2.3,0,0,1-.19.9,9.9,9.9,0,0,0,0,8.66A2.69,2.69,0,0,1,23,46c0,.92,0,1.83,0,2.75,0,.29.07.4.37.39.95,0,1.9,0,2.84,0a1.26,1.26,0,0,1,.57.14,9,9,0,0,0,8.47.1,2.51,2.51,0,0,1,1-.23c.89,0,1.78,0,2.66,0,.27,0,.35-.09.34-.36,0-1,0-2,0-2.92a2.54,2.54,0,0,1,.2-.8c.18-.52.38-1,.6-1.55.06-.13.21-.29.32-.3,1.11,0,2.22,0,3.33,0C43.67,43.23,43.72,43.26,43.88,43.3Z"/>
  </g>
</svg>
''';

class _KhqrHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerCutWidth = 24.0;
    const cornerCutExtraHeight = 14.0;
    final baseHeight = size.height - cornerCutExtraHeight;

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerCutWidth, baseHeight);
    path.lineTo(0, baseHeight);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset((startX + dashWidth).clamp(0.0, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class AbaPayWayModal extends StatefulWidget {
  final String tranId;
  final dynamic orderId;
  final String? deeplink;
  final String? qrImageBase64;
  final double? amount;
  final String currency;
  final String merchantName;
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
    this.amount,
    this.currency = 'USD',
    this.merchantName = 'THARY VIREAK Store',
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
    double? amount,
    String currency = 'USD',
    String merchantName = 'THARY VIREAK Store',
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
        amount: amount,
        currency: currency,
        merchantName: merchantName,
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
              SizedBox(
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: SvgPicture.string(abaPayWayLogoSvg, height: 22),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        onPressed: _cancelPayment,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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

  String _formatAmount(double? amount) {
    if (amount == null) return '0.00';
    if (widget.currency.toUpperCase() == 'KHR') {
      return amount.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(2);
  }

  Widget _buildQrContent(ThemeData theme, bool isDark) {
    final currencySymbol = widget.currency.toUpperCase() == 'KHR' ? '៛' : '\$';

    return Column(
      children: [
        const SizedBox(height: 16),
        // KHQR Card Frame (According to PayWay KHQR Display Guidelines & Image 2)
        Center(
          child: Container(
            width: 295,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Red KHQR Header Bar with Signature Corner Tab and KHQR Logo
                  SizedBox(
                    height: 58,
                    child: ClipPath(
                      clipper: _KhqrHeaderClipper(),
                      child: Container(
                        color: const Color(0xFFE1251B),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 44,
                              child: Center(
                                child: SvgPicture.string(
                                  khqrLogoWhiteSvg,
                                  height: 19,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Merchant Name & Amount (Left-aligned as shown in Image 2)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.merchantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currencySymbol ${_formatAmount(widget.amount)}',
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Clean Dashed Divider Line (No hole punches / notches)
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: const _DashedLinePainter(
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. QR Code Container (Unobstructed so all data modules are scannable)
                  Center(
                    child: _qrBytes != null
                        ? Image.memory(
                            _qrBytes!,
                            width: 215,
                            height: 215,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          )
                        : Icon(
                            Icons.qr_code_2_rounded,
                            size: 140,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        // 5. Subtext Below Card
        Text(
          context.l10n.isKhmer
              ? 'ស្កេនជាមួយ ABA Mobile ឬកម្មវិធីធនាគារ\nដែលគាំទ្រ KHQR ណាមួយ'
              : 'Scan with ABA Mobile or any KHQR\nsupported banking app',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 10),
        // Polling countdown badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _isPollingTimedOut
                ? Colors.amber.withOpacity(0.12)
                : const Color(0xFF005C8A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPollingTimedOut) ...[
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: Color(0xFF005C8A),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<int>(
                  valueListenable: _remainingSecondsNotifier,
                  builder: (context, seconds, _) {
                    return Text(
                      context.l10n.checkingPaymentStatus(_formatRemainingTime(seconds)),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF005C8A),
                        fontWeight: FontWeight.w600,
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
