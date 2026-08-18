import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/delivery_settings.dart';

/// خدمة التوصيل — تقرأ إعدادات المطعم من الخادم وتحفظ التعديلات فيه.
/// المسارات المستخدمة (موجودة فعلاً في خادم ديار الأنباط):
///   GET /api/settings/delivery-config   (عام)
///   PUT /api/settings   { delivery: {...} }   (admin/manager)
class DeliveryService extends ChangeNotifier {
  DeliveryService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  DeliverySettings _settings = DeliverySettings.empty();
  DeliverySettings get settings => _settings;

  bool _loading = false;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/settings/delivery-config', auth: false);
      _settings = DeliverySettings.fromJson(Map<String, dynamic>.from(res));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل إعدادات التوصيل';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// حفظ الإعدادات في الخادم — يؤثر فوراً على موقع الزبائن.
  Future<void> save(DeliverySettings s) async {
    _saving = true;
    notifyListeners();
    try {
      await _api.put('/api/settings', body: {'delivery': s.toJson()});
      _settings = s;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
