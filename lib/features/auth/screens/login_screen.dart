import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/app_exception.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String returnTo;

  const LoginScreen({super.key, this.returnTo = '/home'});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      context.go(widget.returnTo);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordSheet() {
    final theme = Theme.of(context);
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.isKhmer ? 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ!' : 'Reset your password!',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.isKhmer
                    ? 'សូមបញ្ចូលលេខទូរស័ព្ទ ឬអ៊ីមែលរបស់អ្នក យើងនឹងផ្ញើលេខកូដផ្ទៀងផ្ទាត់។'
                    : 'Please enter your phone number or email, we will send a verification code.',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.isKhmer
                      ? 'បញ្ចូលលេខទូរស័ព្ទ ឬអ៊ីមែល'
                      : 'Enter phone number or email',
                  hintStyle: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0,
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.isKhmer
                              ? 'លេខកូដផ្ទៀងផ្ទាត់ត្រូវបានផ្ញើទៅ ${phoneController.text}'
                              : 'Verification code sent to ${phoneController.text}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            letterSpacing: 0,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.l10n.isKhmer ? 'ផ្ញើលេខកូដផ្ទៀងផ្ទាត់' : 'Send Verification Code',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Heading matching mockup
                Text(
                  context.l10n.isKhmer
                      ? 'សូមស្វាគមន៍មកកាន់\nហាងទំនិញរបស់យើង'
                      : 'Welcome Back to\nour grocery shop',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.isKhmer
                      ? 'ចូលគណនីដើម្បីស្វែងរកទំនិញស្រស់ៗ និងតាមដានការដឹកជញ្ជូនរបស់អ្នក។'
                      : 'Sign in to explore organic fresh foods and track your deliveries.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.5,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 36),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Email / Mobile Field
                Text(
                  context.l10n.isKhmer ? 'អ៊ីមែល ឬលេខទូរស័ព្ទ' : 'Email or Mobile',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'user@example.com',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return context.l10n.isKhmer
                          ? 'សូមបំពេញព័ត៌មាននេះ'
                          : 'Field is required';
                    }
                    if (!v.contains('@')) {
                      return context.l10n.isKhmer
                          ? 'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលដែលត្រឹមត្រូវ'
                          : 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password Field
                Text(
                  context.l10n.isKhmer ? 'ពាក្យសម្ងាត់' : 'Password',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.isKhmer
                        ? 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក'
                        : 'Enter your password',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey[500],
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.l10n.isKhmer
                          ? 'សូមបំពេញព័ត៌មាននេះ'
                          : 'Field is required';
                    }
                    if (v.length < 6) {
                      return context.l10n.isKhmer
                          ? 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ'
                          : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPasswordSheet,
                    child: Text(
                      context.l10n.isKhmer ? 'ភ្លេចពាក្យសម្ងាត់?' : 'Forgot password?',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Action Button (matching mockup)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.l10n.isKhmer ? 'ចូលគណនី' : 'Login',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Register Prompt
                Center(
                  child: GestureDetector(
                    onTap: () => context.push(
                      '/register',
                      extra: {'returnTo': widget.returnTo},
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: context.l10n.isKhmer
                            ? 'មិនទាន់មានគណនីមែនទេ? '
                            : "Don't have an Account? ",
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                          fontSize: 14,
                          letterSpacing: 0,
                        ),
                        children: [
                          TextSpan(
                            text: context.l10n.isKhmer ? 'ចុះឈ្មោះ' : 'Sign up',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
