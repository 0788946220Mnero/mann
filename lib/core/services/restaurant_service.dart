import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// حالة المطعم (مفتوح / مشغول / متوقف) — تستخدم مسار الخادم الحالي:
///   GET   /api/settings
///   PATCH /api/settings/status
class RestaurantService extends ChangeNotifier {
  RestaurantService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  String _mode = 'open';
  String get mode => _mode;
  bool get isOpen => _mode == 'open';

  DateTime? busyUntil;
  bool _loading = false;
  bool get loading => _loading;

  String get label {
    switch (_mode) {
      case 'busy': return 'المطعم مشغول';
      case 'stopped': return 'المطعم مغلق';
      default: return 'المطعم مفتوح';
    }
  }

  Future<void> load() async {
    try {
      final res = await _api.get('/api/settings', auth: false);
      final status = res['restaurantStatus'];
      if (status is Map) {
        _mode = (status['mode'] ?? 'open') as String;
        busyUntil = DateTime.tryParse((status['busyUntil'] ?? '').toString())?.toLocal();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setMode(String mode, {int? busyMinutes}) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.patch('/api/settings/status', body: {
        'mode': mode,
        if (busyMinutes != null) 'busyMinutes': busyMinutes,
      });
      final status = res['restaurantStatus'];
      if (status is Map) {
        _mode = (status['mode'] ?? mode) as String;
        busyUntil = DateTime.tryParse((status['busyUntil'] ?? '').toString())?.toLocal();
      } else {
        _mode = mode;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
