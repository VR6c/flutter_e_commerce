import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/user_avatar_provider.dart';

class AvatarCustomizerScreen extends ConsumerStatefulWidget {
  const AvatarCustomizerScreen({super.key});

  @override
  ConsumerState<AvatarCustomizerScreen> createState() =>
      _AvatarCustomizerScreenState();
}

class _AvatarCustomizerScreenState
    extends ConsumerState<AvatarCustomizerScreen> {
  final GlobalKey _avatarBoundaryKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.customizeAvatar,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _onSaveAndApply,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                l10n.save,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Live Preview Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Layered Avatar ring
                  Container(
                    width: 136,
                    height: 136,
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
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF131D38) : Colors.white,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: RepaintBoundary(
                        key: _avatarBoundaryKey,
                        child: ClipOval(
                          child: Container(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            child: FluttermojiCircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF23AA49),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.livePreviewAutosaved,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fluttermoji Customizer Widget
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: FluttermojiCustomizer(
                    autosave: true,
                    attributeTitles: l10n.isKhmer
                        ? const [
                            'ម៉ូដសក់',
                            'ពណ៌សក់',
                            'ពុកចង្កា / ពុកមាត់',
                            'ពណ៌ពុកចង្កា',
                            'សម្លៀកបំពាក់',
                            'ពណ៌សម្លៀកបំពាក់',
                            'ភ្នែក',
                            'ចិញ្ចើម',
                            'មាត់',
                            'ពណ៌សម្បុរ',
                            'គ្រឿងតុបតែង',
                          ]
                        : null,
                    theme: FluttermojiThemeData(
                      boxDecoration: BoxDecoration(color: theme.cardColor),
                      primaryBgColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      secondaryBgColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      labelTextStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Apply Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _onSaveAndApply,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    l10n.applyUseThisAvatar,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSaveAndApply() async {
    HapticFeedback.mediumImpact();

    File? imageFile;
    try {
      final boundary = _avatarBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final tempDir = await getTemporaryDirectory();
          final file = File(
            '${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(byteData.buffer.asUint8List());
          imageFile = file;
        }
      }
    } catch (e) {
      debugPrint('Error rasterizing fluttermoji avatar: $e');
    }

    await ref
        .read(userAvatarProvider.notifier)
        .setFluttermojiAvatar(imageFile: imageFile);

    if (mounted) {
      final isKm = context.l10n.isKhmer;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                isKm
                    ? 'បានរក្សាទុក និងអនុវត្តរូបតំណាងថ្មីជោគជ័យ!'
                    : 'Custom avatar saved and synced!',
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
  }
}
