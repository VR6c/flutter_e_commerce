import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyTermsSheet extends StatelessWidget {
  const PrivacyTermsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PrivacyTermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKm = context.l10n.isKhmer;

    return SafeArea(
      child: Padding(
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
                    color: const Color(0xFF475569).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF475569),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isKm ? 'ឯកជនភាព & លក្ខខណ្ឌ' : 'Privacy & Terms',
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
            Text(
              isKm
                  ? 'ឯកជនភាព និងសុវត្ថិភាពទិន្នន័យរបស់អ្នក គឺជាអាទិភាពចម្បងរបស់យើង។ រាល់ប្រតិបត្តិការទូទាត់ទាំងអស់ត្រូវបានការពារ និងអ៊ិនគ្រីបតាមប្រព័ន្ធសុវត្ថិភាពធនាគារកម្រិតខ្ពស់។ យើងមិនរក្សាទុកលេខសម្ងាត់កាតធនាគារផ្ទាល់ខ្លួនរបស់អ្នកឡើយ។'
                  : 'Your privacy and data security are our top priorities. All payment transactions are encrypted end-to-end via secure banking gateways. We do not store your raw credit card credentials.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.5,
                letterSpacing: 0,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isKm
                  ? 'តាមរយៈការប្រើប្រាស់កម្មវិធី TVR អ្នកយល់ព្រមតាមលក្ខខណ្ឌប្រើប្រាស់ជាមូលដ្ឋាន គោលការណ៍នៃការប្រើប្រាស់សមរម្យ និងសិទ្ធិការពារអ្នកប្រើប្រាស់របស់យើង។'
                  : 'By using the TVR app, you agree to our standard terms of service, fair usage policies, and consumer return guidelines.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.5,
                letterSpacing: 0,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isKm ? 'ខ្ញុំយល់ព្រម' : 'I Understand',
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
          ],
        ),
      ),
    );
  }
}
