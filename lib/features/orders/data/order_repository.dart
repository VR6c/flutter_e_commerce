import '../../../core/api/api_client.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../models/order.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<List<Order>> fetchOrders() async {
    final response = await _apiClient.get('/orders');
    final data = response.data;
    if (data == null) return [];

    // Handle both { data: [...] } and direct list responses
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        raw = data['data'] as List<dynamic>;
      } else if (data['orders'] is List) {
        raw = data['orders'] as List<dynamic>;
      } else {
        raw = [];
      }
    } else {
      raw = [];
    }

    final baseUrl = _apiClient.dio.options.baseUrl;

    final List<Map<String, dynamic>> mappedOrders = [];
    for (final item in raw) {
      if (item is Map) {
        final orderMap = Map<String, dynamic>.from(item);
        if (orderMap['items'] is List) {
          final itemsList = orderMap['items'] as List;
          final updatedItems = itemsList.map((itemObj) {
            if (itemObj is Map) {
              final itemMap = Map<String, dynamic>.from(itemObj);
              itemMap['product_thumbnail'] = formatImageUrl(
                itemMap['product_thumbnail']?.toString(),
                baseUrl,
                title: itemMap['product_name']?.toString(),
              );
              return itemMap;
            }
            return itemObj;
          }).toList();
          orderMap['items'] = updatedItems;
        }
        mappedOrders.add(orderMap);
      }
    }

    return mappedOrders
        .map((e) => Order.fromJson(e))
        .toList();
  }
}
