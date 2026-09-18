import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../providers/user_avatar_provider.dart';

class AvatarOptionsSheet extends ConsumerWidget {
  final String? customerName;

  const AvatarOptionsSheet({super.key, this.customerName});

  static Future<void> show(BuildContext context, {String? customerName}) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvatarOptionsSheet(customerName: customerName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final avatarState = ref.watch(userAvatarProvider);

    String statusLabel = l10n.defaultInitials;
    if (avatarState.isPhoto) {
      statusLabel = l10n.uploadedPhoto;
    } else if (avatarState.isFluttermoji) {
      statusLabel = l10n.customAvatar;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Header with current avatar preview
            Row(
              children: [
                UserAvatar(
                  radius: 28,
                  name: customerName,
                  showEditBadge: false,
                  showBorder: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profilePictureAvatar,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.activeStatus(statusLabel),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Divider(
              height: 1,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 16),

            // Option 1: Custom Avatar with Fluttermoji
            _buildOptionTile(
              context: context,
              icon: Icons.face_retouching_natural_rounded,
              gradientColors: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
              ],
              title: l10n.customizeAvatar,
              subtitle: l10n.designHairFaceClothesAnd,
              isHighlight: true,
              theme: theme,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.avatarCustomizer);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Take Photo with Camera
            _buildOptionTile(
              context: context,
              icon: Icons.camera_alt_rounded,
              gradientColors: [
                const Color(0xFF10B981),
                const Color(0xFF059669),
              ],
              title: l10n.takePhoto,
              subtitle: l10n.useCameraToSnapA,
              theme: theme,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(userAvatarProvider.notifier)
                    .pickPhoto(ImageSource.camera);
                if (context.mounted && success) {
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
                            l10n.avatarUploadSuccess,
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
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Choose from Gallery
            _buildOptionTile(
              context: context,
              icon: Icons.photo_library_rounded,
              gradientColors: [
                const Color(0xFF3B82F6),
                const Color(0xFF1D4ED8),
              ],
              title: l10n.chooseFromGallery,
              subtitle: l10n.selectAnImageFromYour,
              theme: theme,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(userAvatarProvider.notifier)
                    .pickPhoto(ImageSource.gallery);
                if (context.mounted && success) {
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
                            l10n.avatarUploadSuccess,
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
              },
            ),

            // Option 4: Reset to Default (if customized)
            if (!avatarState.isDefault) ...[
              const SizedBox(height: 12),
              _buildOptionTile(
                context: context,
                icon: Icons.refresh_rounded,
                gradientColors: [
                  const Color(0xFFEF4444),
                  const Color(0xFFDC2626),
                ],
                title: l10n.resetToDefaultAvatar,
                subtitle: l10n.removePhotoOrAvatarAnd,
                theme: theme,
                isDark: isDark,
                isDestructive: true,
                onTap: () async {
                  await ref.read(userAvatarProvider.notifier).resetToDefault();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.avatarRemoved,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
    bool isHighlight = false,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlight
              ? (isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlight
                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                : (isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0)),
            width: isHighlight ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.onSurface,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
