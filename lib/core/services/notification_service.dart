import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime at;
  bool read;

  AppNotification({required this.title, required this.body, DateTime? at, this.read = false})
      : at = at ?? DateTime.now();
}

/// إشعارات محلية + صوت تنبيه للطلبات الجديدة + مركز إشعارات داخل التطبيق.
/// جاهز لإضافة Firebase Cloud Messaging لاحقاً دون تغيير الشاشات.
class NotificationService extends ChangeNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _player = AudioPlayer();

  final List<AppNotification> _items = [];
  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    try {
      await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool v) async {
    _soundEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', v);
    notifyListeners();
  }

  /// إشعار طلب جديد: بانر نظام + صوت + إدخال في مركز الإشعارات.
  Future<void> notifyNewOrder({
    required String orderNumber,
    required double total,
    bool isDelivery = false,
  }) async {
    final title = isDelivery ? '🚗 طلب توصيل جديد' : '🏪 طلب استلام جديد';
    final body = 'طلب رقم #$orderNumber — الإجمالي: ${total.toStringAsFixed(2)} د.أ';
    await _show(title, body);
    push(title, body);
    if (_soundEnabled) playAlert();
  }

  void push(String title, String body) {
    _items.insert(0, AppNotification(title: title, body: body));
    if (_items.length > 100) _items.removeLast();
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
  }

  Future<void> _show(String title, String body) async {
    const android = AndroidNotificationDetails(
      'orders_channel',
      'الطلبات الجديدة',
      channelDescription: 'إشعارات وصول الطلبات الجديدة',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(android: android, iOS: ios),
      );
    } catch (_) {}
  }

  Future<void> playAlert() async {
    try {
      await _player.play(AssetSource('sounds/new_order.mp3'));
    } catch (_) {
      // في حال عدم توفّر ملف الصوت لا نُفشل العملية
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
