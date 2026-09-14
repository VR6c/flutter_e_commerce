/// Generic container for paginated API responses matching Laravel API pagination structures.
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  /// True if more pages are available on the server
  bool get hasMore => currentPage < lastPage;

  /// Index of the subsequent page
  int get nextPage => currentPage + 1;

  /// Whether the dataset in this page is empty
  bool get isEmpty => items.isEmpty;

  /// Whether the dataset in this page contains items
  bool get isNotEmpty => items.isNotEmpty;

  /// Creates a PaginatedResponse by parsing Laravel's pagination payload.
  /// Supports both nested `meta` (Laravel Resource Collection) and flat pagination structures.
  factory PaginatedResponse.fromJson(
    dynamic json,
    T Function(dynamic item) itemParser,
  ) {
    if (json is List) {
      final items = json.map(itemParser).toList();
      return PaginatedResponse(
        items: items,
        currentPage: 1,
        lastPage: 1,
        perPage: items.length,
        total: items.length,
      );
    }

    if (json is! Map<String, dynamic>) {
      throw FormatException('Expected Map or List for PaginatedResponse, got ${json.runtimeType}');
    }

    // Extract list data
    final dynamic rawData = json['data'] ?? json['items'] ?? [];
    final List<dynamic> list = rawData is List ? rawData : <dynamic>[];
    final items = list.map(itemParser).toList();

    // Check for nested 'meta' block vs flat root properties
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : json;

    final currentPage = _parseInt(meta['current_page']) ?? 1;
    final lastPage = _parseInt(meta['last_page']) ?? 1;
    final perPage = _parseInt(meta['per_page']) ?? (items.isNotEmpty ? items.length : 15);
    final total = _parseInt(meta['total']) ?? items.length;

    return PaginatedResponse<T>(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  PaginatedResponse<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? lastPage,
    int? perPage,
    int? total,
  }) {
    return PaginatedResponse<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
    );
  }
}
