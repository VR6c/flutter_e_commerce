import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_routes.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final avatarState = ref.watch(userAvatarProvider);

    String statusLabel = 'Default Initials';
    if (avatarState.isPhoto) {
      statusLabel = 'Uploaded Photo';
    } else if (avatarState.isFluttermoji) {
      statusLabel = 'Custom Avatar';
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
                        'Profile Picture & Avatar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
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
                          'Active: $statusLabel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
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
              title: 'Customize Avatar',
              subtitle: 'Design hair, face, clothes, and accessories',
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
              title: 'Take Photo',
              subtitle: 'Use camera to snap a new picture',
              theme: theme,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(userAvatarProvider.notifier)
                    .pickPhoto(ImageSource.camera);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile photo updated!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
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
              title: 'Choose from Gallery',
              subtitle: 'Select an image from your photos',
              theme: theme,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(userAvatarProvider.notifier)
                    .pickPhoto(ImageSource.gallery);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile photo updated!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
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
                title: 'Reset to Default Avatar',
                subtitle: 'Remove photo or avatar and use initials',
                theme: theme,
                isDark: isDark,
                isDestructive: true,
                onTap: () async {
                  await ref.read(userAvatarProvider.notifier).resetToDefault();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset to default initials'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
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
