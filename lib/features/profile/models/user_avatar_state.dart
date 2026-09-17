enum AvatarType { defaultAvatar, photo, fluttermoji }

class UserAvatarState {
  final AvatarType type;
  final String? photoPath;
  final String? photoUrl;
  final bool isUploading;
  final String? errorMessage;

  const UserAvatarState({
    this.type = AvatarType.defaultAvatar,
    this.photoPath,
    this.photoUrl,
    this.isUploading = false,
    this.errorMessage,
  });

  bool get isPhoto =>
      type == AvatarType.photo &&
      ((photoPath != null && photoPath!.isNotEmpty) ||
          (photoUrl != null && photoUrl!.isNotEmpty));
  bool get isFluttermoji => type == AvatarType.fluttermoji;
  bool get isDefault => type == AvatarType.defaultAvatar;

  UserAvatarState copyWith({
    AvatarType? type,
    String? photoPath,
    String? photoUrl,
    bool? isUploading,
    String? errorMessage,
    bool clearPhotoPath = false,
    bool clearPhotoUrl = false,
  }) {
    return UserAvatarState(
      type: type ?? this.type,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage,
    );
  }
}
