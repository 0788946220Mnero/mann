import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/app_user.dart';
import '../storage/token_storage.dart';

/// إدارة جلسة المستخدم الإداري.
/// يستخدم مسارات الـ Backend الحالية: POST /api/auth/login و GET /api/auth/me
class AuthService extends ChangeNotifier {
  AuthService({ApiClient? api, TokenStorage? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? TokenStorage() {
    _api.onUnauthorized = () => logout(silent: true);
  }

  final ApiClient _api;
  final TokenStorage _storage;

  ApiClient get api => _api;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  bool _loading = false;
  bool get loading => _loading;

  /// استعادة الجلسة عند فتح التطبيق.
  Future<void> restoreSession() async {
    final token = await _storage.accessToken;
    if (token == null || token.isEmpty) return;

    final cached = await _storage.user;
    if (cached != null) {
      try {
        _user = AppUser.decode(cached);
        notifyListeners();
      } catch (_) {}
    }

    // تحقّق من صلاحية الجلسة فعلياً على الخادم
    try {
      final res = await _api.get('/api/auth/me');
      final data = (res is Map && res['user'] != null) ? res['user'] : res;
      _user = AppUser.fromJson(Map<String, dynamic>.from(data));
      await _storage.saveUser(_user!.encode());
      notifyListeners();
    } catch (_) {
      await logout(silent: true);
    }
  }

  Future<void> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post(
        '/api/auth/login',
        body: {'username': username.trim(), 'password': password},
        auth: false,
      );

      final accessToken = res['accessToken'] as String?;
      if (accessToken == null) {
        throw ApiException('تعذّر تسجيل الدخول. حاول مجدداً.');
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: res['refreshToken'] as String?,
      );

      final userData = Map<String, dynamic>.from(res['user'] ?? {});
      final u = AppUser.fromJson(userData);

      // حماية: تطبيق الإدارة لا يقبل إلا حسابات الإدارة
      _user = u;
      await _storage.saveUser(u.encode());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      try {
        await _api.post('/api/auth/logout');
      } catch (_) {}
    }
    await _storage.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> changePassword({
    required String current,
    required String newPassword,
    required String confirm,
  }) async {
    await _api.post('/api/auth/change-password', body: {
      'currentPassword': current,
      'newPassword': newPassword,
      'confirmPassword': confirm,
    });
  }
}
