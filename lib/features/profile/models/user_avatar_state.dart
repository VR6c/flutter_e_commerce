enum AvatarType {
  defaultAvatar,
  photo,
  fluttermoji,
}

class UserAvatarState {
  final AvatarType type;
  final String? photoPath;

  const UserAvatarState({
    this.type = AvatarType.defaultAvatar,
    this.photoPath,
  });

  bool get isPhoto =>
      type == AvatarType.photo && photoPath != null && photoPath!.isNotEmpty;
  bool get isFluttermoji => type == AvatarType.fluttermoji;
  bool get isDefault => type == AvatarType.defaultAvatar;

  UserAvatarState copyWith({
    AvatarType? type,
    String? photoPath,
  }) {
    return UserAvatarState(
      type: type ?? this.type,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
