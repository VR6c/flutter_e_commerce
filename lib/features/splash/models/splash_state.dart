enum SplashStatus {
  initial,
  initializing,
  completed,
  error,
}

class SplashState {
  final SplashStatus status;
  final String message;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.message = 'Starting up...',
    this.errorMessage,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? message,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplashState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ message.hashCode ^ errorMessage.hashCode;

  @override
  String toString() =>
      'SplashState(status: $status, message: $message, errorMessage: $errorMessage)';
}
