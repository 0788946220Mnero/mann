import 'dart:convert';
import 'package:http/http.dart' as http;

import 'app_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  ApiException(this.message, {this.statusCode, this.code});
  @override
  String toString() => message;
}

/// عميل HTTP موحّد لكل نداءات الـ API.
/// يضيف رمز الدخول تلقائياً، ويجدّده عند انتهائه، ويوحّد معالجة الأخطاء.
class ApiClient {
  ApiClient({TokenStorage? storage}) : _storage = storage ?? TokenStorage();

  final TokenStorage _storage;
  final _http = http.Client();

  /// يُستدعى عند فشل التجديد (جلسة منتهية) ليتولّى التطبيق تسجيل الخروج.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = query?.map((k, v) => MapEntry(k, v?.toString()))
      ?..removeWhere((_, v) => v == null || v.isEmpty);
    return Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
      queryParameters: (cleaned == null || cleaned.isEmpty) ? null : cleaned,
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send(() async => _http.get(_uri(path, query), headers: await _headers(auth: auth)), path, query, auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) => _send(
        () async => _http.post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})),
        path, null, auth,
      );

  Future<dynamic> put(String path, {Object? body, bool auth = true}) => _send(
        () async => _http.put(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})),
        path, null, auth,
      );

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) => _send(
        () async => _http.patch(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})),
        path, null, auth,
      );

  Future<dynamic> delete(String path, {bool auth = true}) =>
      _send(() async => _http.delete(_uri(path), headers: await _headers(auth: auth)), path, null, auth);

  Future<dynamic> _send(
    Future<http.Response> Function() request,
    String path,
    Map<String, dynamic>? query,
    bool auth, {
    bool retried = false,
  }) async {
    http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ApiException('تعذّر الاتصال بالخادم. تحقّق من الإنترنت وحاول مجدداً.');
    }

    // انتهت صلاحية الرمز → نحاول التجديد مرة واحدة
    if (res.statusCode == 401 && auth && !retried) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _send(request, path, query, auth, retried: true);
      }
      onUnauthorized?.call();
      throw ApiException('انتهت الجلسة. الرجاء تسجيل الدخول من جديد.', statusCode: 401);
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = res.body;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final msg = (data is Map && data['message'] is String)
        ? data['message'] as String
        : 'حدث خطأ غير متوقع (${res.statusCode})';
    final code = (data is Map && data['code'] is String) ? data['code'] as String : null;
    throw ApiException(msg, statusCode: res.statusCode, code: code);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _http.post(
        _uri('/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body);
      final token = data['accessToken'] as String?;
      if (token == null) return false;
      await _storage.saveTokens(accessToken: token, refreshToken: data['refreshToken'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }
}
