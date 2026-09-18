import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/price_breakdown_card.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';

/// Isolated Bill Summary card in the Cart Screen.
/// Only listens to totalAmount, totalWeight, and couponState.
class CartSummaryCard extends ConsumerWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = ref.watch(cartTotalAmountProvider);
    final totalWeight = ref.watch(cartTotalWeightProvider);
    final couponState = ref.watch(couponProvider);

    final double discount = couponState.isApplied ? couponState.discountAmount : 0.0;
    final double finalTotal = (totalAmount - discount).clamp(0.0, double.infinity);

    return PriceBreakdownCard(
      subtotal: totalAmount,
      weight: totalWeight,
      vat: 0.0,
      discount: couponState.isApplied ? discount : null,
      couponCode: couponState.isApplied ? couponState.code : null,
      deliveryFee: 0.0,
      total: finalTotal,
    );
  }
}
