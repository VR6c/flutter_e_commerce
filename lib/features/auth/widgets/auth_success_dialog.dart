import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

enum AuthDialogStatus { loading, success }

class AuthSuccessDialogController {
  final void Function(String userName) showSuccess;
  final void Function() dismiss;

  AuthSuccessDialogController({
    required this.showSuccess,
    required this.dismiss,
  });
}

class AuthSuccessDialog extends StatefulWidget {
  final String? initialMessage;

  const AuthSuccessDialog({super.key, this.initialMessage});

  static AuthSuccessDialogController show(
    BuildContext context, {
    String? initialMessage,
  }) {
    late void Function(String) successCallback;
    late void Function() dismissCallback;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: _AuthSuccessDialogWrapper(
            initialMessage: initialMessage,
            onInit: (successCb, dismissCb) {
              successCallback = successCb;
              dismissCallback = dismissCb;
            },
          ),
        );
      },
    );

    return AuthSuccessDialogController(
      showSuccess: (name) => successCallback(name),
      dismiss: () => dismissCallback(),
    );
  }

  @override
  State<AuthSuccessDialog> createState() => _AuthSuccessDialogState();
}

class _AuthSuccessDialogWrapper extends StatefulWidget {
  final String? initialMessage;
  final void Function(void Function(String) successCb, void Function() dismissCb)
      onInit;

  const _AuthSuccessDialogWrapper({
    this.initialMessage,
    required this.onInit,
  });

  @override
  State<_AuthSuccessDialogWrapper> createState() =>
      _AuthSuccessDialogWrapperState();
}

class _AuthSuccessDialogWrapperState extends State<_AuthSuccessDialogWrapper> {
  final GlobalKey<_AuthSuccessDialogState> _dialogKey =
      GlobalKey<_AuthSuccessDialogState>();

  @override
  void initState() {
    super.initState();
    widget.onInit(
      (userName) {
        _dialogKey.currentState?.setSuccess(userName);
      },
      () {
        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthSuccessDialog(
      key: _dialogKey,
      initialMessage: widget.initialMessage,
    );
  }
}

class _AuthSuccessDialogState extends State<AuthSuccessDialog>
    with SingleTickerProviderStateMixin {
  AuthDialogStatus _status = AuthDialogStatus.loading;
  String _userName = '';
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  void setSuccess(String userName) {
    if (!mounted) return;
    setState(() {
      _status = AuthDialogStatus.success;
      _userName = userName;
    });
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _status == AuthDialogStatus.loading
                  ? Column(
                      key: const ValueKey('loading'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.initialMessage ?? l10n.signingIn,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ScaleTransition(
                      key: const ValueKey('success'),
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  AppTheme.secondaryColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _userName.isNotEmpty
                                ? l10n.welcomeUser(_userName)
                                : l10n.welcomeBack,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.successfullySignedIn,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.5,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
