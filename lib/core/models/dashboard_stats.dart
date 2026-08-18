class TopProduct {
  final String name;
  final int quantity;
  TopProduct({required this.name, required this.quantity});

  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
        name: (j['_id'] ?? '').toString(),
        quantity: (j['totalOrdered'] ?? 0) as int,
      );
}

/// إحصائيات لوحة الإدارة — من المسار الحالي GET /api/orders/stats/dashboard
class DashboardStats {
  final int todayOrders;
  final int pendingOrders;
  final double todaySales;
  final double monthlySales;
  final List<TopProduct> topProducts;
  // ═══ إحصائيات التوصيل (من الخادم — لا تُحسب هنا) ═══
  final int deliveryCount;
  final double deliveryFeesTotal;
  final double? avgDeliveryDistanceKm;
  final int pickupCount;

  DashboardStats({
    required this.todayOrders,
    required this.pendingOrders,
    required this.todaySales,
    required this.monthlySales,
    required this.topProducts,
    this.deliveryCount = 0,
    this.deliveryFeesTotal = 0,
    this.avgDeliveryDistanceKm,
    this.pickupCount = 0,
  });

  /// متوسط قيمة الطلب اليوم
  double get avgOrderValue => todayOrders == 0 ? 0 : todaySales / todayOrders;

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        todayOrders: (j['todayOrders'] ?? 0) as int,
        pendingOrders: (j['pendingOrders'] ?? 0) as int,
        todaySales: _d(j['todaySales']),
        monthlySales: _d(j['monthlySales']),
        topProducts: (j['topProducts'] as List?)
                ?.map((e) => TopProduct.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        deliveryCount: (j['deliveryToday']?['count'] ?? 0) as int,
        deliveryFeesTotal: _d(j['deliveryToday']?['feesTotal']),
        avgDeliveryDistanceKm: j['deliveryToday']?['avgDistanceKm'] == null
            ? null
            : _d(j['deliveryToday']?['avgDistanceKm']),
        pickupCount: (j['pickupToday']?['count'] ?? 0) as int,
      );

  static DashboardStats empty() => DashboardStats(
      todayOrders: 0, pendingOrders: 0, todaySales: 0, monthlySales: 0, topProducts: const []);
}

double _d(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
