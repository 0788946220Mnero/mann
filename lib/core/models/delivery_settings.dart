/// إعدادات التوصيل — تُقرأ وتُحفظ في الخادم (مصدر الحقيقة الوحيد).
/// لا تُخزَّن إحداثيات ثابتة داخل التطبيق إطلاقاً.
class DeliverySettings {
  final bool enabled;
  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double freeDistanceKm;
  final double pricePerKm;
  final double maxDistanceKm;

  DeliverySettings({
    required this.enabled,
    this.restaurantLatitude,
    this.restaurantLongitude,
    required this.freeDistanceKm,
    required this.pricePerKm,
    required this.maxDistanceKm,
  });

  bool get hasRestaurantLocation =>
      restaurantLatitude != null && restaurantLongitude != null;

  factory DeliverySettings.fromJson(Map<String, dynamic> j) => DeliverySettings(
        enabled: j['enabled'] == true,
        restaurantLatitude: _d(j['restaurantLatitude']),
        restaurantLongitude: _d(j['restaurantLongitude']),
        freeDistanceKm: _d(j['freeDistanceKm']) ?? 1,
        pricePerKm: _d(j['pricePerKm']) ?? 0.5,
        maxDistanceKm: _d(j['maxDistanceKm']) ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'restaurantLatitude': restaurantLatitude,
        'restaurantLongitude': restaurantLongitude,
        'freeDistanceKm': freeDistanceKm,
        'pricePerKm': pricePerKm,
        'maxDistanceKm': maxDistanceKm,
        'distanceMode': 'straight',
      };

  DeliverySettings copyWith({
    bool? enabled,
    double? restaurantLatitude,
    double? restaurantLongitude,
    double? freeDistanceKm,
    double? pricePerKm,
    double? maxDistanceKm,
  }) =>
      DeliverySettings(
        enabled: enabled ?? this.enabled,
        restaurantLatitude: restaurantLatitude ?? this.restaurantLatitude,
        restaurantLongitude: restaurantLongitude ?? this.restaurantLongitude,
        freeDistanceKm: freeDistanceKm ?? this.freeDistanceKm,
        pricePerKm: pricePerKm ?? this.pricePerKm,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      );

  static DeliverySettings empty() => DeliverySettings(
      enabled: false, freeDistanceKm: 1, pricePerKm: 0.5, maxDistanceKm: 10);
}

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
