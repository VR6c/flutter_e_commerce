import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/app_exception.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String returnTo;

  const RegisterScreen({super.key, this.returnTo = '/home'});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
          );
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
        _errorMessage = 'Registration failed. Please verify your info.';
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
                const SizedBox(height: 10),
                Text(
                  context.l10n.isKhmer ? 'បង្កើតគណនីថ្មី' : 'Create Account',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.isKhmer
                      ? 'ចុះឈ្មោះជាមួយយើងដើម្បីទទួលបានទំនិញគុណភាពល្អៗដឹកដល់ផ្ទះរបស់អ្នក។'
                      : 'Join us to get fresh organic groceries delivered right to your door.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.5,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 28),

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
                  const SizedBox(height: 18),
                ],

                // Full Name Field
                Text(
                  context.l10n.isKhmer ? 'ឈ្មោះពេញ' : 'Full Name',
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
                  controller: _nameController,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.isKhmer
                        ? 'ឈ្មោះរបស់អ្នក'
                        : 'John Doe',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (context.l10n.isKhmer
                            ? 'សូមបញ្ចូលឈ្មោះពេញ'
                            : 'Full name is required')
                      : null,
                ),
                const SizedBox(height: 16),

                // Email Field
                Text(
                  context.l10n.isKhmer ? 'អាសយដ្ឋានអ៊ីមែល' : 'Email Address',
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
                  decoration: const InputDecoration(
                    hintText: 'user@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return context.l10n.isKhmer
                          ? 'សូមបញ្ចូលអ៊ីមែល'
                          : 'Email is required';
                    }
                    if (!v.contains('@')) {
                      return context.l10n.isKhmer
                          ? 'សូមបញ្ចូលអ៊ីមែលដែលត្រឹមត្រូវ'
                          : 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                        ? 'យ៉ាងហោចណាស់ ៦ តួអក្សរ'
                        : 'At least 6 characters',
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
                          ? 'សូមបញ្ចូលពាក្យសម្ងាត់'
                          : 'Password is required';
                    }
                    if (v.length < 6) {
                      return context.l10n.isKhmer
                          ? 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ'
                          : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                Text(
                  context.l10n.isKhmer
                      ? 'បញ្ជាក់ពាក្យសម្ងាត់'
                      : 'Confirm Password',
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
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.isKhmer
                        ? 'បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត'
                        : 'Re-enter your password',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.l10n.isKhmer
                          ? 'សូមបញ្ជាក់ពាក្យសម្ងាត់របស់អ្នក'
                          : 'Please confirm your password';
                    }
                    if (v != _passwordController.text) {
                      return context.l10n.isKhmer
                          ? 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ'
                          : 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
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
                                context.l10n.isKhmer
                                    ? 'បង្កើតគណនី'
                                    : 'Create Account',
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
                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => context.push(
                      '/login',
                      extra: {'returnTo': widget.returnTo},
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: context.l10n.isKhmer
                            ? 'មានគណនីរួចហើយមែនទេ? '
                            : 'Already have an account? ',
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
                            text: context.l10n.isKhmer ? 'ចូលគណនី' : 'Sign in',
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
