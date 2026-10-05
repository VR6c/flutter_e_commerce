import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/providers.dart';
import '../data/order_repository.dart';
import '../models/order.dart';

part 'orders_provider.g.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderRepository(apiClient);
});

@riverpod
class Orders extends _$Orders {
  @override
  FutureOr<List<Order>> build() async {
    return ref.watch(orderRepositoryProvider).fetchOrders();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Memoized derived provider calculating pipeline status counts.
/// Avoids rebuilding order status tracker widgets and re-looping orders in build().
final orderStatusCountsProvider = Provider<Map<String, int>>((ref) {
  final orders = ref.watch(ordersProvider).valueOrNull ?? const [];
  final statusCounts = <String, int>{
    'pending': 0,
    'processing': 0,
    'shipped': 0,
    'delivered': 0,
  };
  for (final order in orders) {
    final s = order.status.toLowerCase();
    if (s == 'completed') {
      statusCounts['delivered'] = (statusCounts['delivered'] ?? 0) + 1;
    } else if (statusCounts.containsKey(s)) {
      statusCounts[s] = statusCounts[s]! + 1;
    }
  }
  return statusCounts;
});
