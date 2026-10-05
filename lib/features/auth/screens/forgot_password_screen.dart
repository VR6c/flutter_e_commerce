import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

enum ForgotPasswordStep {
  email,
  otp,
  newPassword,
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String returnTo;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
    this.returnTo = AppRoutes.home,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;

  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _debugOtp;

  // Resend OTP countdown
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown([int seconds = 60]) {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  // ────────────────────────────────────────────────────────────
  // Step 1: Request OTP
  // ────────────────────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (!_formKeyEmail.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.forgotPassword(email);

      if (!mounted) return;

      final debugOtp = response['debug_otp'] as String?;
      if (debugOtp != null && debugOtp.isNotEmpty) {
        _debugOtp = debugOtp;
        _otpController.text = debugOtp;
      }

      _startCountdown(60);

      setState(() {
        _currentStep = ForgotPasswordStep.otp;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] as String? ??
                'A 6-digit code has been sent to $email',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = msg.isNotEmpty
            ? msg
            : 'Unable to send verification code. Please check your email and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // Step 2: Resend OTP
  // ────────────────────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.resendOtp(email);

      if (!mounted) return;

      final debugOtp = response['debug_otp'] as String?;
      if (debugOtp != null && debugOtp.isNotEmpty) {
        _debugOtp = debugOtp;
        _otpController.text = debugOtp;
      }

      _startCountdown(60);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] as String? ?? 'New verification code sent to $email',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = msg.isNotEmpty ? msg : 'Unable to resend code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // Step 2: Verify OTP
  // ────────────────────────────────────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyOtp(email: email, otp: otp);

      if (!mounted) return;

      setState(() {
        _currentStep = ForgotPasswordStep.newPassword;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = msg.isNotEmpty
            ? msg
            : 'Invalid or expired verification code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // Step 3: Reset Password
  // ────────────────────────────────────────────────────────────
  Future<void> _handleResetPassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    final newPass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass != confirmPass) {
      setState(() {
        _errorMessage = context.l10n.passwordsDoNotMatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: email,
            otp: otp,
            password: newPass,
            passwordConfirmation: confirmPass,
          );

      if (!mounted) return;

      final customer = ref.read(authStateProvider).valueOrNull;
      final displayName = customer?.name.isNotEmpty == true
          ? customer!.name
          : email.split('@').first;

      // Navigate to Auth Success celebrating password reset
      context.go(
        AppRoutes.authSuccess,
        extra: {
          'userName': displayName,
          'returnTo': widget.returnTo,
        },
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = msg.isNotEmpty
            ? msg
            : 'Password reset failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_currentStep == ForgotPasswordStep.newPassword) {
              setState(() {
                _currentStep = ForgotPasswordStep.otp;
                _errorMessage = null;
              });
            } else if (_currentStep == ForgotPasswordStep.otp) {
              setState(() {
                _currentStep = ForgotPasswordStep.email;
                _errorMessage = null;
              });
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(theme),
              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                _buildErrorBanner(theme),
                const SizedBox(height: 20),
              ],

              if (_currentStep == ForgotPasswordStep.email)
                _buildEmailStep(theme, isDark),

              if (_currentStep == ForgotPasswordStep.otp)
                _buildOtpStep(theme, isDark),

              if (_currentStep == ForgotPasswordStep.newPassword)
                _buildNewPasswordStep(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step Indicator
  // ────────────────────────────────────────────────────────────
  Widget _buildStepIndicator(ThemeData theme) {
    return Row(
      children: [
        _buildStepBadge(1, 'Email', _currentStep == ForgotPasswordStep.email,
            _currentStep != ForgotPasswordStep.email, theme),
        Expanded(child: _buildStepDivider(_currentStep != ForgotPasswordStep.email, theme)),
        _buildStepBadge(
            2,
            'Verify',
            _currentStep == ForgotPasswordStep.otp,
            _currentStep == ForgotPasswordStep.newPassword,
            theme),
        Expanded(
            child: _buildStepDivider(
                _currentStep == ForgotPasswordStep.newPassword, theme)),
        _buildStepBadge(3, 'Password',
            _currentStep == ForgotPasswordStep.newPassword, false, theme),
      ],
    );
  }

  Widget _buildStepBadge(
      int step, String label, bool isActive, bool isDone, ThemeData theme) {
    final color = isDone
        ? const Color(0xFF10B981)
        : (isActive ? theme.colorScheme.primary : Colors.grey[400]!);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF10B981)
                : (isActive ? theme.colorScheme.primary : Colors.grey[200]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            color: color,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isCompleted, ThemeData theme) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isCompleted ? const Color(0xFF10B981) : Colors.grey[300],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Error Banner
  // ────────────────────────────────────────────────────────────
  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: theme.colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 1: Email View
  // ────────────────────────────────────────────────────────────
  Widget _buildEmailStep(ThemeData theme, bool isDark) {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.forgotPassword,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address. We will send you a 6-digit verification code to reset your password.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Email Address',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. name@example.com',
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Verification Code',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                'Back to Login',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 2: OTP Verification View
  // ────────────────────────────────────────────────────────────
  Widget _buildOtpStep(ThemeData theme, bool isDark) {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            size: 36,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Verify OTP Code',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit verification code to '),
              TextSpan(
                text: email,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const TextSpan(text: '. Check your inbox or spam folder.'),
            ],
          ),
        ),
        if (_debugOtp != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Test OTP Code: $_debugOtp',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        Text(
          '6-Digit Code',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(
              letterSpacing: 12,
              color: Colors.grey[400],
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          onChanged: (val) {
            if (val.length == 6) {
              _handleVerifyOtp();
            }
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
            _secondsRemaining > 0
                ? Text(
                    'Resend in ${_secondsRemaining}s',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : GestureDetector(
                    onTap: _isLoading ? null : _handleResendOtp,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 3: Set New Password View
  // ────────────────────────────────────────────────────────────
  Widget _buildNewPasswordStep(ThemeData theme, bool isDark) {
    return Form(
      key: _formKeyPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 36,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create New Password',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your code has been verified. Create a new, strong password with at least 6 characters.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // New Password
          Text(
            'New Password',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm Password
          Text(
            'Confirm New Password',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Re-enter your new password',
              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Reset Password & Sign In',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
