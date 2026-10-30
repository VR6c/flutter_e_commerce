import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/product_review.dart';
import '../providers/product_reviews_provider.dart';

const _starColor = Color(0xFFF59E0B);

/// Read-only or interactive row of 5 rating stars.
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = i + 1;
        final icon = rating >= value
            ? Icons.star_rounded
            : (rating >= value - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded);
        final star = Icon(icon, color: _starColor, size: size);
        if (onChanged == null) return star;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged!(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }
}

class ProductReviewsSection extends ConsumerWidget {
  final String productSlug;

  const ProductReviewsSection({super.key, required this.productSlug});

  Future<void> _onWriteReview(BuildContext context, WidgetRef ref) async {
    final customer = ref.read(authStateProvider).valueOrNull;
    if (customer == null) {
      AppSnackBar.showInfo(context, context.l10n.signInToReview);
      context.push('/login');
      return;
    }
    await WriteReviewSheet.show(context, productSlug);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final async = ref.watch(productReviewsProvider(productSlug));
    final muted = isDark ? Colors.grey[400] : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.reviews,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _onWriteReview(context, ref),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(l10n.writeReview),
              ),
            ],
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (result) {
              if (result.reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.noReviewsYet,
                    style: TextStyle(fontSize: 13.5, color: muted),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        result.avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRating(rating: result.avgRating, size: 18),
                          const SizedBox(height: 2),
                          Text(
                            l10n.reviewCount(result.total),
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final review in result.reviews)
                    _ReviewTile(review: review),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final date = review.createdAt;
    final avatar = review.customerAvatar;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                backgroundImage: (avatar != null && avatar.startsWith('http'))
                    ? NetworkImage(avatar)
                    : null,
                child: (avatar != null && avatar.startsWith('http'))
                    ? null
                    : Text(
                        review.customerName.isNotEmpty
                            ? review.customerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    StarRating(rating: review.rating.toDouble(), size: 14),
                  ],
                ),
              ),
              if (date != null)
                Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.review,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                height: 1.5,
                letterSpacing: 0,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WriteReviewSheet extends ConsumerStatefulWidget {
  final String productSlug;

  const WriteReviewSheet({super.key, required this.productSlug});

  static Future<void> show(BuildContext context, String productSlug) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WriteReviewSheet(productSlug: productSlug),
    );
  }

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  final _controller = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_rating == 0) {
      AppSnackBar.showError(context, l10n.selectRating);
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await submitProductReview(
        ref,
        widget.productSlug,
        rating: _rating,
        review: _controller.text,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(context, l10n.reviewSubmitted);
      } else {
        setState(() => _submitting = false);
        AppSnackBar.showError(context, l10n.reviewFailed);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final error = e is DioException ? e.error : e;
      AppSnackBar.showError(
        context,
        error is AppException ? error.message : l10n.reviewFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.writeReview,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.yourRating,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StarRating(
                rating: _rating.toDouble(),
                size: 38,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                enabled: !_submitting,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: l10n.reviewHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.submitReview),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
