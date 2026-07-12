// -----------------------------------------------------------------------------
// 文件：secure_token_store.dart
// 作用：隔离登录 Token 的安全读写与清理实现
// 编写时间：2026-07-10
// 维护说明：Token 禁止写入 SharedPreferences、日志或页面状态
// -----------------------------------------------------------------------------

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'merp.auth.token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
