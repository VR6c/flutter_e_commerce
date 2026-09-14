import 'package:freezed_annotation/freezed_annotation.dart';
import 'order_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class Order with _$Order {
  const factory Order({
    required int id,
    required String status,
    required double total,
    @JsonKey(name: 'coupon_code') String? couponCode,
    @JsonKey(name: 'discount_amount') @Default(0.0) double discountAmount,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'phone') String? phone,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'address') String? address,
    @JsonKey(name: 'city') String? city,
    @JsonKey(name: 'country') String? country,
    required String gateway,
    @JsonKey(name: 'items') @Default([]) List<OrderItem> items,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
