import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_review.dart';
import 'product_provider.dart';

/// Approved reviews and average rating for a product, keyed by product slug.
final productReviewsProvider =
    FutureProvider.autoDispose.family<ProductReviewsResult, String>((
      ref,
      slug,
    ) {
      return ref.watch(productRepositoryProvider).fetchProductReviews(slug);
    });

/// Submits a review and refreshes the reviews list on success.
/// Throws on API failure (validation, unauthorized, network).
Future<bool> submitProductReview(
  WidgetRef ref,
  String slug, {
  required int rating,
  String? review,
}) async {
  final ok = await ref
      .read(productRepositoryProvider)
      .submitProductReview(slug, rating: rating, review: review);
  if (ok) ref.invalidate(productReviewsProvider(slug));
  return ok;
}
