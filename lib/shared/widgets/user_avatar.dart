import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttermoji/fluttermoji.dart';

import '../../features/profile/providers/user_avatar_provider.dart';

class UserAvatar extends ConsumerWidget {
  final double radius;
  final String? name;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.radius = 32,
    this.name,
    this.showEditBadge = false,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(userAvatarProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initials = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : 'U';

    Widget avatarContent;

    if (avatarState.isPhoto && avatarState.photoPath != null) {
      final file = File(avatarState.photoPath!);
      final cacheDim = (radius * 4).round().clamp(100, 320);
      avatarContent = ClipOval(
        child: Image.file(
          file,
          width: radius * 2,
          height: radius * 2,
          cacheWidth: cacheDim,
          cacheHeight: cacheDim,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackInitials(
            theme,
            initials,
          ),
        ),
      );
    } else if (avatarState.isFluttermoji) {
      avatarContent = ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          child: FluttermojiCircleAvatar(
            radius: radius,
            backgroundColor: Colors.transparent,
          ),
        ),
      );
    } else {
      avatarContent = _buildFallbackInitials(theme, initials);
    }

    Widget avatarWidget = avatarContent;

    if (showBorder) {
      avatarWidget = Container(
        width: radius * 2 + 8,
        height: radius * 2 + 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              const Color(0xFF10B981),
            ],
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF131D38) : Colors.white,
          ),
          padding: const EdgeInsets.all(2.5),
          child: avatarContent,
        ),
      );
    }

    if (showEditBadge) {
      final badgeSize = (radius * 0.55).clamp(22.0, 32.0);
      final iconSize = (badgeSize * 0.55).clamp(12.0, 16.0);

      avatarWidget = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF10B981),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallbackInitials(ThemeData theme, String initials) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
