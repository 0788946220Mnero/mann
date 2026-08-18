import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/dashboard_stats.dart';

/// إحصائيات الإدارة — تستخدم المسار الحالي دون أي تعديل على الخادم.
class StatsService extends ChangeNotifier {
  StatsService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  DashboardStats _stats = DashboardStats.empty();
  DashboardStats get stats => _stats;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/orders/stats/dashboard');
      _stats = DashboardStats.fromJson(Map<String, dynamic>.from(res));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل الإحصائيات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
