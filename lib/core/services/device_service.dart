import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// تسجيل الجهاز لاستقبال إشعارات FCM.
///
/// ملاحظة مهمة: الحصول على رمز FCM نفسه يتطلّب إضافة حزمة firebase_messaging
/// وملفَّي google-services.json و GoogleService-Info.plist (راجع FCM_SETUP.md).
/// هذه الخدمة جاهزة لاستقبال الرمز وتسجيله في الخادم بمجرد توفّره.
class DeviceService extends ChangeNotifier {
  DeviceService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  static const _kDeviceId = 'device_id';
  String? _deviceId;
  String? get deviceId => _deviceId;

  /// معرّف ثابت للجهاز (يُولَّد مرة ويُحفظ) — يمنع تكرار التسجيل.
  Future<String> _ensureDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(this)}';
      await prefs.setString(_kDeviceId, id);
    }
    _deviceId = id;
    return id;
  }

  /// تسجيل رمز FCM في الخادم بعد تسجيل الدخول.
  Future<void> register(String fcmToken, {String platform = 'unknown'}) async {
    if (fcmToken.isEmpty) return;
    try {
      final id = await _ensureDeviceId();
      await _api.post('/api/devices/register', body: {
        'deviceId': id,
        'fcmToken': fcmToken,
        'platform': platform,
      });
    } on ApiException catch (e) {
      debugPrint('device register failed: ${e.message}');
    }
  }

  /// إلغاء التسجيل عند تسجيل الخروج — يوقف الإشعارات لهذا الجهاز.
  Future<void> unregister() async {
    try {
      final id = await _ensureDeviceId();
      await _api.delete('/api/devices/$id');
    } catch (_) {}
  }
}
