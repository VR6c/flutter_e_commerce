class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<int> productIds;
  final bool isError;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.productIds = const [],
    this.isError = false,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? createdAt,
    List<int>? productIds,
    bool? isError,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      productIds: productIds ?? this.productIds,
      isError: isError ?? this.isError,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt.toIso8601String(),
      'productIds': productIds,
      'isError': isError,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      productIds: (json['productIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      isError: json['isError'] as bool? ?? false,
      isLoading: false,
    );
  }
}
