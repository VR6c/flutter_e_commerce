part of 'order.dart';

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  total: (json['total'] as num).toDouble(),
  couponCode: json['coupon_code'] as String?,
  discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  receiptUrl: json['receipt_url'] as String?,
  address: json['address'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  gateway: json['gateway'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'total': instance.total,
      'coupon_code': instance.couponCode,
      'discount_amount': instance.discountAmount,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'email': instance.email,
      'receipt_url': instance.receiptUrl,
      'address': instance.address,
      'city': instance.city,
      'country': instance.country,
      'gateway': instance.gateway,
      'items': instance.items,
      'created_at': instance.createdAt,
    };
