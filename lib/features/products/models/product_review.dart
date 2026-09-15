class ProductReview {
  final int id;
  final int rating;
  final String review;
  final String customerName;
  final String? customerAvatar;
  final DateTime? createdAt;

  const ProductReview({
    required this.id,
    required this.rating,
    required this.review,
    required this.customerName,
    this.customerAvatar,
    this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.tryParse(json['created_at'].toString());
      } catch (_) {}
    }

    return ProductReview(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      rating: int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      review: json['review']?.toString() ?? '',
      customerName: customer?['name']?.toString() ?? 'Customer',
      customerAvatar: customer?['profile_image']?.toString(),
      createdAt: parsedDate,
    );
  }
}

class ProductReviewsResult {
  final double avgRating;
  final int total;
  final List<ProductReview> reviews;

  const ProductReviewsResult({
    this.avgRating = 0.0,
    this.total = 0,
    this.reviews = const [],
  });

  factory ProductReviewsResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    return ProductReviewsResult(
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '0') ?? 0.0,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      reviews: rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductReview.fromJson(e))
          .toList(),
    );
  }
}
