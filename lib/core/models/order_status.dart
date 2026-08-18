/// حالات الطلب — مطابقة تماماً لقيم الـ Backend الحالي
/// (pending, new, preparing, ready, out_for_delivery, delivered, cancelled)
enum OrderStatus {
  pending,          // معلّق — بانتظار قبول المطعم
  newOrder,         // مقبول/جديد
  preparing,        // قيد التحضير
  ready,            // جاهز
  outForDelivery,   // خرج للتوصيل
  delivered,        // تم التسليم
  cancelled;        // ملغي

  static OrderStatus fromApi(String? v) {
    switch (v) {
      case 'pending': return OrderStatus.pending;
      case 'new': return OrderStatus.newOrder;
      case 'preparing': return OrderStatus.preparing;
      case 'ready': return OrderStatus.ready;
      case 'out_for_delivery': return OrderStatus.outForDelivery;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.newOrder: return 'new';
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.ready: return 'ready';
      case OrderStatus.outForDelivery: return 'out_for_delivery';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'جديد';
      case OrderStatus.newOrder: return 'مقبول';
      case OrderStatus.preparing: return 'قيد التحضير';
      case OrderStatus.ready: return 'جاهز';
      case OrderStatus.outForDelivery: return 'خرج للتوصيل';
      case OrderStatus.delivered: return 'تم التسليم';
      case OrderStatus.cancelled: return 'ملغي';
    }
  }
}
