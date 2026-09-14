class DeliveryLocation {
  final String id;
  final String label;
  final String street;
  final String city;
  final String country;
  final String iconType; // 'home', 'work', 'apartment', 'current', 'pin'
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const DeliveryLocation({
    required this.id,
    required this.label,
    required this.street,
    this.city = 'Phnom Penh',
    this.country = 'Cambodia',
    this.iconType = 'home',
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  String get fullAddress => '$street, $city, $country';

  DeliveryLocation copyWith({
    String? id,
    String? label,
    String? street,
    String? city,
    String? country,
    String? iconType,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return DeliveryLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      city: city ?? this.city,
      country: country ?? this.country,
      iconType: iconType ?? this.iconType,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'city': city,
      'country': country,
      'iconType': iconType,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id'] as String? ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
      label: json['label'] as String? ?? 'Location',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? 'Phnom Penh',
      country: json['country'] as String? ?? 'Cambodia',
      iconType: json['iconType'] as String? ?? 'pin',
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Default preset addresses for Phnom Penh
  static const defaultHome = DeliveryLocation(
    id: 'loc_home',
    label: 'Home',
    street: 'Street 2004, Sen Sok',
    city: 'Phnom Penh',
    iconType: 'home',
    isDefault: true,
    latitude: 11.5540,
    longitude: 104.8760,
  );

  static const defaultWork = DeliveryLocation(
    id: 'loc_work',
    label: 'Office',
    street: 'Vattanac Capital, Preah Monivong Blvd',
    city: 'Phnom Penh',
    iconType: 'work',
    isDefault: false,
    latitude: 11.5732,
    longitude: 104.9205,
  );

  static const defaultApt = DeliveryLocation(
    id: 'loc_apt',
    label: 'Apartment',
    street: 'BKK1, Street 302',
    city: 'Phnom Penh',
    iconType: 'apartment',
    isDefault: false,
    latitude: 11.5510,
    longitude: 104.9280,
  );

  static const List<DeliveryLocation> defaultLocations = [
    defaultHome,
    defaultWork,
    defaultApt,
  ];
}
