import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/app_config.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../websocket/websocket_service.dart';
import 'notification_service.dart';

/// إدارة الطلبات: الجلب، تغيير الحالة، والتحديث الفوري.
/// يستخدم مسارات الـ Backend الحالية:
///   GET  /api/orders
///   PUT  /api/orders/:id/confirm
///   PUT  /api/orders/:id/status
class OrderService extends ChangeNotifier {
  OrderService({
    required ApiClient api,
    required NotificationService notifications,
    WebSocketService? ws,
  })  : _api = api,
        _notifications = notifications,
        _ws = ws ?? WebSocketService();

  final ApiClient _api;
  final NotificationService _notifications;
  final WebSocketService _ws;

  List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Timer? _pollTimer;
  final Set<String> _knownIds = {};
  bool _firstLoadDone = false;

  /// عدّادات لوحة الرئيسية
  int countOf(OrderStatus s) => _orders.where((o) => o.status == s).length;
  int get newCount => countOf(OrderStatus.pending) + countOf(OrderStatus.newOrder);
  int get preparingCount => countOf(OrderStatus.preparing);
  int get readyCount => countOf(OrderStatus.ready) + countOf(OrderStatus.outForDelivery);
  int get completedCount => countOf(OrderStatus.delivered);
  int get cancelledCount => countOf(OrderStatus.cancelled);

  double get todaySales {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .fold(0.0, (t, o) => t + o.total);
  }

  bool get isRealtimeConnected => _ws.isConnected;

  /// بدء المزامنة: WebSocket للتحديث الفوري، والاستطلاع كشبكة أمان.
  ///
  /// عند اتصال WebSocket تصل الأحداث فوراً (بلا انتظار)، ويبقى الاستطلاع
  /// يعمل بوتيرة أبطأ كـ Fallback فلا تتوقف الطلبات عند أي انقطاع.
  void start(String? accessToken) {
    fetchOrders();

    if (_ws.isEnabled) {
      _ws.connect(accessToken);
      _ws.events.listen((event) {
        final type = (event['type'] ?? '').toString();

        // أحداث الطلبات من الخادم
        if (type == 'order.created' ||
            type == 'order.updated' ||
            type == 'order.status_changed' ||
            type == 'order.cancelled') {
          _handleRealtimeOrderEvent(type, event);
        }
      });
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConfig.pollInterval, (_) {
      // عند اتصال WebSocket نخفّف الاستطلاع (شبكة أمان فقط)
      if (_ws.isConnected && _firstLoadDone) return;
      fetchOrders(silent: true);
    });
  }

  /// معالجة حدث فوري: إشعار للطلب الجديد ثم تحديث القائمة والعدّادات.
  void _handleRealtimeOrderEvent(String type, Map<String, dynamic> event) {
    if (type == 'order.created') {
      final raw = event['order'];
      if (raw is Map) {
        try {
          final o = Order.fromJson(Map<String, dynamic>.from(raw));
          if (!_knownIds.contains(o.id)) {
            _notifications.notifyNewOrder(
              orderNumber: o.orderNumber,
              total: o.total,
              isDelivery: o.isDelivery,
            );
          }
        } catch (_) {}
      }
    }
    // نعيد الجلب لضمان تطابق القائمة والعدّادات مع الخادم
    fetchOrders(silent: true);
  }

  void stop() {
    _pollTimer?.cancel();
    _ws.disconnect();
  }

  Future<void> fetchOrders({bool silent = false, String? status, String? search}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final res = await _api.get('/api/orders', query: {
        'limit': '100',
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final list = (res['data'] as List?) ?? [];
      final fetched = list.map((e) => Order.fromJson(Map<String, dynamic>.from(e))).toList();

      // كشف الطلبات الجديدة لإطلاق الإشعار والصوت
      if (_firstLoadDone) {
        for (final o in fetched) {
          final isNew = !_knownIds.contains(o.id) &&
              (o.status == OrderStatus.pending || o.status == OrderStatus.newOrder);
          if (isNew) {
            _notifications.notifyNewOrder(
              orderNumber: o.orderNumber,
              total: o.total,
              isDelivery: o.isDelivery,
            );
          }
        }
      }
      _knownIds
        ..clear()
        ..addAll(fetched.map((o) => o.id));
      _firstLoadDone = true;

      _orders = fetched;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل الطلبات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Order? byId(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// قبول الطلب (pending → new) عبر مسار confirm في الخادم.
  Future<void> acceptOrder(String id) async {
    await _api.put('/api/orders/$id/confirm');
    await fetchOrders(silent: true);
  }

  /// تغيير حالة الطلب.
  Future<void> updateStatus(String id, OrderStatus status) async {
    if (status == OrderStatus.newOrder) {
      final o = byId(id);
      if (o != null && o.status == OrderStatus.pending) {
        return acceptOrder(id);
      }
    }
    await _api.put('/api/orders/$id/status', body: {'status': status.apiValue});
    await fetchOrders(silent: true);
  }

  Future<void> cancelOrder(String id) => updateStatus(id, OrderStatus.cancelled);

  @override
  void dispose() {
    stop();
    _ws.dispose();
    super.dispose();
  }
}
