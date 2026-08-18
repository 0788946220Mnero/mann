import 'order_status.dart';

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final List<String> addons;
  final String notes;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.addons = const [],
    this.notes = '',
  });

  double get lineTotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: (j['nameAr'] ?? j['name'] ?? '') as String,
        quantity: (j['quantity'] ?? j['qty'] ?? 1) as int,
        price: _toDouble(j['price']),
        addons: (j['addons'] as List?)
                ?.map((a) => a is Map ? (a['name'] ?? '').toString() : a.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        notes: (j['notes'] ?? '') as String,
      );
}

class Order {
  final String id;
  final String orderNumber;
  final String customerName;
  final String phone;
  final String address;
  final String orderType;      // delivery | pickup
  final String paymentMethod;  // cash | card | online
  final String notes;
  final OrderStatus status;
  final List<OrderItem> items;
  final double itemsTotal;
  final double deliveryFee;
  final double total;
  final bool phoneVerified;
  // ═══ بيانات التوصيل (تأتي محسوبة من الخادم — لا يُعاد حسابها هنا) ═══
  final double? customerLatitude;
  final double? customerLongitude;
  final double? deliveryDistance;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.orderType,
    required this.paymentMethod,
    required this.notes,
    required this.status,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.total,
    required this.phoneVerified,
    this.customerLatitude,
    this.customerLongitude,
    this.deliveryDistance,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
  });

  bool get isDelivery => orderType != 'pickup';

  /// هل يملك الطلب إحداثيات صالحة لعرضها على الخريطة؟
  bool get hasLocation => customerLatitude != null && customerLongitude != null;

  String get orderTypeLabel => isDelivery ? 'توصيل' : 'استلام من الفرع';

  String get paymentLabel {
    switch (paymentMethod) {
      case 'card': return 'بطاقة';
      case 'online': return 'إلكتروني';
      default: return 'نقدي';
    }
  }

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        orderNumber: (j['orderNumber'] ?? '').toString(),
        customerName: (j['customerName'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        address: (j['address'] ?? '') as String,
        orderType: (j['orderType'] ?? 'delivery') as String,
        paymentMethod: (j['paymentMethod'] ?? 'cash') as String,
        notes: (j['notes'] ?? '') as String,
        status: OrderStatus.fromApi(j['status'] as String?),
        items: (j['items'] as List?)?.map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i))).toList() ?? [],
        itemsTotal: _toDouble(j['itemsTotal'] ?? j['total']),
        deliveryFee: _toDouble(j['deliveryFee']),
        total: _toDouble(j['total']),
        phoneVerified: j['phoneVerified'] == true,
        customerLatitude: _toDoubleOrNull(j['customerLatitude']),
        customerLongitude: _toDoubleOrNull(j['customerLongitude']),
        deliveryDistance: _toDoubleOrNull(j['deliveryDistance']),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
        updatedAt: DateTime.tryParse((j['updatedAt'] ?? '').toString())?.toLocal(),
        confirmedAt: DateTime.tryParse((j['confirmedAt'] ?? '').toString())?.toLocal(),
      );
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
