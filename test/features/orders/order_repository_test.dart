import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_e_commerce/core/api/api_client.dart';
import 'package:flutter_e_commerce/features/orders/data/order_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late Dio mockDio;
  late OrderRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    when(() => mockApiClient.dio).thenReturn(mockDio);
    repository = OrderRepository(mockApiClient);
  });

  final sampleOrderJson = {
    'id': 101,
    'status': 'completed',
    'total': 89.99,
    'first_name': 'John',
    'last_name': 'Doe',
    'gateway': 'stripe',
    'created_at': '2026-01-01T00:00:00Z',
    'items': [
      {
        'id': 1,
        'order_id': 101,
        'product_id': 5,
        'product_name': 'Sneakers',
        'product_thumbnail': 'sneakers.jpg',
        'price': 89.99,
        'quantity': 1,
      }
    ],
  };

  group('OrderRepository Tests', () {
    test('parses direct List responses safely without type error', () async {
      when(() => mockApiClient.get<dynamic>('/orders')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/orders'),
          data: [sampleOrderJson],
          statusCode: 200,
        ),
      );

      final orders = await repository.fetchOrders();
      expect(orders.length, 1);
      expect(orders.first.id, 101);
      expect(orders.first.status, 'completed');
      expect(orders.first.total, 89.99);
      expect(orders.first.items.length, 1);
      expect(orders.first.items.first.productName, 'Sneakers');
    });

    test('parses nested { "data": [...] } response', () async {
      when(() => mockApiClient.get<dynamic>('/orders')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/orders'),
          data: {
            'data': [sampleOrderJson],
          },
          statusCode: 200,
        ),
      );

      final orders = await repository.fetchOrders();
      expect(orders.length, 1);
      expect(orders.first.id, 101);
    });

    test('parses nested { "orders": [...] } response', () async {
      when(() => mockApiClient.get<dynamic>('/orders')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/orders'),
          data: {
            'orders': [sampleOrderJson],
          },
          statusCode: 200,
        ),
      );

      final orders = await repository.fetchOrders();
      expect(orders.length, 1);
      expect(orders.first.id, 101);
    });

    test('returns empty list for null or unexpected format', () async {
      when(() => mockApiClient.get<dynamic>('/orders')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/orders'),
          data: null,
          statusCode: 200,
        ),
      );

      final orders = await repository.fetchOrders();
      expect(orders, isEmpty);
    });
  });
}
