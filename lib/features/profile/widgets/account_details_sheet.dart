import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/models/customer.dart';
import 'avatar_options_sheet.dart';
import 'edit_profile_sheet.dart';

class AccountDetailsSheet extends StatelessWidget {
  final Customer customer;

  const AccountDetailsSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, {required Customer customer}) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AccountDetailsSheet(customer: customer),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.isKhmer
                  ? 'បានចម្លង $label ជោគជ័យ'
                  : 'Copied $label to clipboard',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF23AA49),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInfoDetailRow(
    BuildContext context,
    String label,
    String value,
    ThemeData theme, {
    bool canCopy = false,
    bool statusBadge = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              letterSpacing: 0,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (statusBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF23AA49).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: Color(0xFF23AA49),
                ),
              ),
            )
          else
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value, label),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 18),
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
                    Icons.badge_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.isKhmer ? 'ព័ត៌មានលម្អិតគណនី' : 'Account Details',
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
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    radius: 28,
                    name: customer.name,
                    showEditBadge: true,
                    onTap: () {
                      Navigator.pop(context);
                      AvatarOptionsSheet.show(
                        context,
                        customerName: customer.name,
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      AvatarOptionsSheet.show(
                        context,
                        customerName: customer.name,
                      );
                    },
                    child: Text(
                      l10n.isKhmer
                          ? 'ប្ដូររូបតំណាង / រូបថត'
                          : 'Change Avatar / Photo',
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
            _buildInfoDetailRow(
              context,
              l10n.isKhmer ? 'ឈ្មោះពេញ' : 'Full Name',
              customer.name,
              theme,
            ),
            _buildInfoDetailRow(
              context,
              l10n.isKhmer ? 'អាសយដ្ឋានអ៊ីមែល' : 'Email Address',
              customer.email,
              theme,
              canCopy: true,
            ),
            _buildInfoDetailRow(
              context,
              l10n.isKhmer ? 'លេខសម្គាល់អតិថិជន' : 'Customer ID',
              '#${customer.id}',
              theme,
              canCopy: true,
            ),
            _buildInfoDetailRow(
              context,
              l10n.isKhmer ? 'ស្ថានភាព' : 'Status',
              l10n.isKhmer
                  ? (customer.status.toLowerCase() == 'active'
                      ? 'សកម្ម'
                      : customer.status)
                  : customer.status.toUpperCase(),
              theme,
              statusBadge: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                        l10n.isKhmer ? 'បិទ' : 'Close',
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        EditProfileSheet.show(context, customer: customer);
                      },
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        l10n.isKhmer ? 'កែសម្រួលព័ត៌មាន' : 'Edit Info',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
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
      ),
    );
  }
}
