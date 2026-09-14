import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/user_avatar_state.dart';

final userAvatarProvider =
    StateNotifierProvider<UserAvatarNotifier, UserAvatarState>((ref) {
  final customer = ref.watch(authStateProvider).valueOrNull;
  return UserAvatarNotifier(customer?.id);
});

class UserAvatarNotifier extends StateNotifier<UserAvatarState> {
  final int? _userId;
  final ImagePicker _picker = ImagePicker();

  UserAvatarNotifier(this._userId) : super(const UserAvatarState()) {
    _loadAvatar();
  }

  String get _storagePrefix => 'user_avatar_${_userId ?? 'guest'}';
  String get _typeKey => '${_storagePrefix}_type';
  String get _photoPathKey => '${_storagePrefix}_photo_path';

  Future<void> _loadAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeStr = prefs.getString(_typeKey);
      final photoPath = prefs.getString(_photoPathKey);

      if (typeStr == 'photo' && photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          state = UserAvatarState(
            type: AvatarType.photo,
            photoPath: photoPath,
          );
          return;
        }
      } else if (typeStr == 'fluttermoji') {
        state = const UserAvatarState(
          type: AvatarType.fluttermoji,
        );
        return;
      }

      state = const UserAvatarState(
        type: AvatarType.defaultAvatar,
      );
    } catch (_) {
      state = const UserAvatarState(
        type: AvatarType.defaultAvatar,
      );
    }
  }

  Future<bool> pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );

      if (picked == null) return false;

      final appDir = await getApplicationDocumentsDirectory();
      final dotIndex = picked.path.lastIndexOf('.');
      final ext = dotIndex != -1 ? picked.path.substring(dotIndex) : '.jpg';
      final fileName =
          'avatar_${_userId ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final persistentFile = File('${appDir.path}/$fileName');

      await File(picked.path).copy(persistentFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_typeKey, 'photo');
      await prefs.setString(_photoPathKey, persistentFile.path);

      state = UserAvatarState(
        type: AvatarType.photo,
        photoPath: persistentFile.path,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> setFluttermojiAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_typeKey, 'fluttermoji');

      state = const UserAvatarState(
        type: AvatarType.fluttermoji,
      );
    } catch (_) {}
  }

  Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldPath = prefs.getString(_photoPathKey);
      if (oldPath != null && oldPath.isNotEmpty) {
        final file = File(oldPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      await prefs.remove(_typeKey);
      await prefs.remove(_photoPathKey);

      state = const UserAvatarState(
        type: AvatarType.defaultAvatar,
      );
    } catch (_) {}
  }
}
