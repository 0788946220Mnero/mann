import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين آمن لرموز الدخول وبيانات المستخدم (Keychain على iOS / EncryptedSharedPrefs على Android).
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _kUser = 'user';

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _kAccess, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefresh, value: refreshToken);
    }
  }

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);

  Future<void> saveUser(String userJson) => _storage.write(key: _kUser, value: userJson);
  Future<String?> get user => _storage.read(key: _kUser);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }
}
