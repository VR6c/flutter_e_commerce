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
