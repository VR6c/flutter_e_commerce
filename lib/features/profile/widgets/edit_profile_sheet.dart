import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/models/customer.dart';
import '../../auth/providers/auth_provider.dart';
import 'avatar_options_sheet.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const EditProfileSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, {required Customer customer}) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditProfileSheet(customer: customer),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  final _formKey = GlobalKey<FormState>();
  bool _changePassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _emailController = TextEditingController(text: widget.customer.email);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final l10n = context.l10n;

    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            currentPassword:
                _changePassword ? _currentPasswordController.text : null,
            newPassword: _changePassword ? _newPasswordController.text : null,
            newPasswordConfirmation:
                _changePassword ? _confirmPasswordController.text : null,
          );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.isKhmer
                    ? 'បានកែសម្រួលព័ត៌មានគណនីជោគជ័យ!'
                    : 'Profile updated successfully!',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF23AA49),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isKhmer ? 'កែសម្រួលព័ត៌មានគណនី' : 'Edit Profile',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        radius: 36,
                        name: widget.customer.name,
                        showEditBadge: true,
                        onTap: () => AvatarOptionsSheet.show(
                          context,
                          customerName: widget.customer.name,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => AvatarOptionsSheet.show(
                          context,
                          customerName: widget.customer.name,
                        ),
                        child: Text(
                          l10n.isKhmer
                              ? 'ចុចដើម្បីប្ដូររូបថត ឬរូបតំណាង'
                              : 'Tap to change photo or avatar',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.isKhmer ? 'ឈ្មោះពេញ' : 'Full Name',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                    ),
                    hintText: l10n.isKhmer
                        ? 'បញ្ចូលឈ្មោះពេញរបស់អ្នក'
                        : 'Enter your full name',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.isKhmer
                          ? 'សូមបញ្ចូលឈ្មោះពេញ'
                          : 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.isKhmer ? 'អាសយដ្ឋានអ៊ីមែល' : 'Email Address',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      size: 20,
                    ),
                    hintText: l10n.isKhmer
                        ? 'បញ្ចូលអាសយដ្ឋានអ៊ីមែលរបស់អ្នក'
                        : 'Enter your email address',
                    hintStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.isKhmer
                          ? 'សូមបញ្ចូលអ៊ីមែល'
                          : 'Email is required';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return l10n.isKhmer
                          ? 'សូមបញ្ចូលអ៊ីមែលឱ្យបានត្រឹមត្រូវ'
                          : 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Change Password toggle
                InkWell(
                  onTap: () {
                    setState(() {
                      _changePassword = !_changePassword;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _changePassword
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.isKhmer ? 'ប្តូរពាក្យសម្ងាត់' : 'Change Password',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_changePassword) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                      ),
                      hintText: l10n.isKhmer
                          ? 'ពាក្យសម្ងាត់បច្ចុប្បន្ន'
                          : 'Current Password',
                      hintStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrent = !_obscureCurrent;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (_changePassword && (val == null || val.isEmpty)) {
                        return l10n.isKhmer
                            ? 'សូមបញ្ចូលពាក្យសម្ងាត់បច្ចុប្បន្ន'
                            : 'Current password is required to change password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                        size: 20,
                      ),
                      hintText: l10n.isKhmer
                          ? 'ពាក្យសម្ងាត់ថ្មី (យ៉ាងតិច ៦ តួអក្សរ)'
                          : 'New Password (min 6 characters)',
                      hintStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNew = !_obscureNew;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (_changePassword) {
                        if (val == null || val.length < 6) {
                          return l10n.isKhmer
                              ? 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ'
                              : 'New password must be at least 6 characters';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                        size: 20,
                      ),
                      hintText: l10n.isKhmer
                          ? 'ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់ថ្មី'
                          : 'Confirm New Password',
                      hintStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (_changePassword && val != _newPasswordController.text) {
                        return l10n.isKhmer
                            ? 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ'
                            : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.isKhmer ? 'បោះបង់' : 'Cancel',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  l10n.isKhmer
                                      ? 'រក្សាទុកការផ្លាស់ប្តូរ'
                                      : 'Save Changes',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
