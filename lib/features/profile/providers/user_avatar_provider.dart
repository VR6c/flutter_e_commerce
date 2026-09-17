import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_endpoints.dart';
import '../../auth/models/customer.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_avatar_state.dart';

final userAvatarProvider =
    StateNotifierProvider<UserAvatarNotifier, UserAvatarState>((ref) {
  final customer = ref.watch(authStateProvider).valueOrNull;
  return UserAvatarNotifier(customer, ref);
});

class UserAvatarNotifier extends StateNotifier<UserAvatarState> {
  final Customer? _customer;
  final Ref? _ref;
  final int? _overrideUserId;
  final ImagePicker _picker = ImagePicker();

  UserAvatarNotifier([dynamic customerOrUserId, this._ref])
      : _customer = customerOrUserId is Customer ? customerOrUserId : null,
        _overrideUserId = customerOrUserId is int ? customerOrUserId : null,
        super(const UserAvatarState()) {
    _loadAvatar();
  }

  int? get _userId => _overrideUserId ?? _customer?.id;
  String get _storagePrefix => 'user_avatar_${_userId ?? 'guest'}';
  String get _typeKey => '${_storagePrefix}_type';
  String get _photoPathKey => '${_storagePrefix}_photo_path';
  String get _fluttermojiKey => '${_storagePrefix}_fluttermoji_options';

  static String? _resolveRemoteUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = ApiEndpoints.baseUrl.replaceAll('/api', '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$cleanPath';
  }

  Future<void> _loadAvatar() async {
    try {
      // If guest / logged out, always show default initials
      if (_userId == null) {
        state = const UserAvatarState(type: AvatarType.defaultAvatar);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final typeStr = prefs.getString(_typeKey);
      final photoPath = prefs.getString(_photoPathKey);

      // 1. Only use profileImage for remote photo (ignore default ui-avatars fallback from backend)
      final remoteProfileImage = _customer?.profileImage;
      final remoteUrl = (remoteProfileImage != null && remoteProfileImage.isNotEmpty)
          ? _resolveRemoteUrl(remoteProfileImage)
          : null;

      // 2. Check local disk photo for this user
      String? validLocalPath;
      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          validLocalPath = photoPath;
        }
      }

      if (validLocalPath != null || (remoteUrl != null && remoteUrl.isNotEmpty)) {
        state = UserAvatarState(
          type: AvatarType.photo,
          photoPath: validLocalPath,
          photoUrl: remoteUrl,
        );
        return;
      }

      // 3. Check if THIS SPECIFIC USER customized a Fluttermoji
      final userFluttermojiOptions = prefs.getString(_fluttermojiKey);
      if (userFluttermojiOptions != null && userFluttermojiOptions.isNotEmpty) {
        await prefs.setString(
          'fluttermojiSelectedOptions',
          userFluttermojiOptions,
        );
        state = const UserAvatarState(type: AvatarType.fluttermoji);
        return;
      }

      // 4. Default: native initials (P for phanit, T for Tvr)
      // If there was any legacy/stale 'fluttermoji' type key without user options, purge it
      if (typeStr == 'fluttermoji' && userFluttermojiOptions == null) {
        await prefs.remove(_typeKey);
      }
      state = const UserAvatarState(type: AvatarType.defaultAvatar);
    } catch (_) {
      state = const UserAvatarState(type: AvatarType.defaultAvatar);
    }
  }

  Future<bool> pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
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

      // Optimistic UI state
      state = UserAvatarState(
        type: AvatarType.photo,
        photoPath: persistentFile.path,
        photoUrl: state.photoUrl,
        isUploading: true,
      );

      if (_ref != null && _customer != null) {
        try {
          final updatedCustomer = await _ref
              .read(authStateProvider.notifier)
              .uploadAvatar(persistentFile, avatarType: 'photo');

          final newRemoteUrl = _resolveRemoteUrl(
            updatedCustomer.avatarUrl ?? updatedCustomer.profileImage,
          );

          state = UserAvatarState(
            type: AvatarType.photo,
            photoPath: persistentFile.path,
            photoUrl: newRemoteUrl,
            isUploading: false,
          );
          return true;
        } catch (e) {
          state = state.copyWith(
            isUploading: false,
            errorMessage: e.toString(),
          );
          return true;
        }
      } else {
        state = state.copyWith(isUploading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> setFluttermojiAvatar({File? imageFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_typeKey, 'fluttermoji');

      // Save active fluttermoji specifically for this user account
      final activeOptions = prefs.getString('fluttermojiSelectedOptions');
      if (activeOptions != null) {
        await prefs.setString(_fluttermojiKey, activeOptions);
      }

      String? localPhotoPath;
      if (imageFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'avatar_${_userId ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}.png';
        final persistentFile = File('${appDir.path}/$fileName');
        await imageFile.copy(persistentFile.path);
        await prefs.setString(_photoPathKey, persistentFile.path);
        localPhotoPath = persistentFile.path;
      }

      state = UserAvatarState(
        type: localPhotoPath != null ? AvatarType.photo : AvatarType.fluttermoji,
        photoPath: localPhotoPath,
        photoUrl: state.photoUrl,
        isUploading: imageFile != null && _ref != null && _customer != null,
      );

      // Upload to Laravel backend API: POST /api/customer/avatar
      if (imageFile != null && _ref != null && _customer != null) {
        try {
          final updatedCustomer = await _ref
              .read(authStateProvider.notifier)
              .uploadAvatar(File(localPhotoPath!), avatarType: 'fluttermoji');

          final newRemoteUrl = _resolveRemoteUrl(
            updatedCustomer.avatarUrl ?? updatedCustomer.profileImage,
          );

          state = UserAvatarState(
            type: AvatarType.photo,
            photoPath: localPhotoPath,
            photoUrl: newRemoteUrl,
            isUploading: false,
          );
          return true;
        } catch (e) {
          state = state.copyWith(
            isUploading: false,
            errorMessage: e.toString(),
          );
          return true;
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetToDefault() async {
    state = state.copyWith(isUploading: true);
    try {
      if (_ref != null && _customer != null) {
        try {
          await _ref.read(authStateProvider.notifier).deleteAvatar();
        } catch (_) {}
      }

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
      await prefs.remove(_fluttermojiKey);

      state = const UserAvatarState(type: AvatarType.defaultAvatar);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
