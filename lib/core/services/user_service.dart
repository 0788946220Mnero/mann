import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/app_user.dart';

/// إدارة مستخدمي الإدارة — تستخدم المسارات الجديدة على نفس خادم ديار الأنباط:
///   GET/POST /api/users · PUT/DELETE /api/users/:id
class UserService extends ChangeNotifier {
  UserService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  List<AppUser> _users = [];
  List<AppUser> get users => List.unmodifiable(_users);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load({String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/users', query: {
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final list = (res['data'] as List?) ?? [];
      _users = list.map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'تعذّر تحميل المستخدمين';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create({
    required String name,
    required String username,
    required String password,
    required UserRole role,
    String phone = '',
  }) async {
    await _api.post('/api/users', body: {
      'name': name,
      'username': username,
      'password': password,
      'role': role.apiValue,
      'phone': phone,
    });
    await load();
  }

  Future<void> update(
    String id, {
    String? name,
    String? username,
    String? password,
    UserRole? role,
    String? phone,
    bool? isActive,
  }) async {
    await _api.put('/api/users/$id', body: {
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (password != null && password.isNotEmpty) 'password': password,
      if (role != null) 'role': role.apiValue,
      if (phone != null) 'phone': phone,
      if (isActive != null) 'isActive': isActive,
    });
    await load();
  }

  Future<void> remove(String id) async {
    await _api.delete('/api/users/$id');
    await load();
  }
}
