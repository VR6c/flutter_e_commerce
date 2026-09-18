import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/image_url_formatter.dart';
import '../models/order.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<List<Order>> fetchOrders() async {
    final response = await _apiClient.get(ApiEndpoints.orders);
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

  Future<Order?> fetchOrderDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.orderDetail(id));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final orderData = data['data'] ?? data['order'] ?? data;
        if (orderData is Map) {
          final orderMap = Map<String, dynamic>.from(orderData);
          final baseUrl = _apiClient.dio.options.baseUrl;
          if (orderMap['items'] is List) {
            final itemsList = orderMap['items'] as List;
            orderMap['items'] = itemsList.map((itemObj) {
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
          }
          return Order.fromJson(orderMap);
        }
      }
    } catch (_) {}
    return null;
  }

  String getReceiptUrl(dynamic id) {
    final baseUrl = _apiClient.dio.options.baseUrl;
    return '$baseUrl${ApiEndpoints.orderReceipt(id)}';
  }

  Future<Uint8List> fetchReceiptBytes(dynamic id) async {
    final response = await _apiClient.dio.get<List<int>>(
      ApiEndpoints.orderReceipt(id),
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'application/pdf, text/html, */*',
        },
      ),
    );
    final data = response.data;
    if (data is Uint8List) {
      return data;
    } else if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    throw Exception('Failed to load receipt PDF data.');
  }

  Future<String> fetchReceiptHtml(dynamic id) async {
    final response = await _apiClient.get<String>(
      ApiEndpoints.orderReceipt(id),
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Accept': 'text/html, application/xhtml+xml, */*',
        },
      ),
    );
    return response.data ?? '';
  }

  Future<String?> getDownloadReceiptUrl(dynamic orderId, {String? existingUrl}) async {
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return existingUrl;
    }
    final id = int.tryParse(orderId.toString());
    if (id != null) {
      final order = await fetchOrderDetail(id);
      if (order?.receiptUrl != null && order!.receiptUrl!.isNotEmpty) {
        return order.receiptUrl;
      }
    }
    return getReceiptUrl(orderId);
  }

  Future<Map<String, dynamic>> submitCheckout(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.checkout,
      data: payload,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'status': false, 'message': 'Invalid server response'};
  }

  Future<bool> checkPaymentStatus({
    required String tranId,
    required String orderId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.checkoutPaymentStatus,
        queryParameters: {
          'tran_id': tranId,
          'order_id': orderId,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        return responseData['approved'] == true;
      }
    } catch (_) {
      // Return false on error to allow caller retry
    }
    return false;
  }
}
