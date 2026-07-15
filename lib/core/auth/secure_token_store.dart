// -----------------------------------------------------------------------------
// 文件：secure_token_store.dart
// 作用：隔离登录 Token 的安全读写与清理实现
// 编写时间：2026-07-10
// 维护说明：Token 禁止写入 SharedPreferences、日志或页面状态
// -----------------------------------------------------------------------------

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_models.dart';

/// Token 存储抽象，便于测试替换为内存实现，也避免网络层依赖具体插件。
abstract interface class TokenStore {
  Future<AuthTokens?> readTokens();

  Future<void> saveTokens(AuthTokens tokens);

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Android 7 已满足插件 API 23 要求。默认实现使用 RSA-OAEP
            // 包装密钥，并使用 AES-GCM 加密 Token，不会明文落盘。
            aOptions: AndroidOptions(storageNamespace: 'merp_auth'),
          );

  static const _accessTokenKey = 'merp.auth.access_token';
  static const _refreshTokenKey = 'merp.auth.refresh_token';
  static const _legacyTokenKey = 'merp.auth.token';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> readTokens() async {
    var accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    // 兼容旧版本单 token 键；下次成功登录或刷新后会写入新结构。
    accessToken ??= await _storage.read(key: _legacyTokenKey);
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }
    return AuthTokens(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    if (tokens.refreshToken == null || tokens.refreshToken!.isEmpty) {
      await _storage.delete(key: _refreshTokenKey);
    } else {
      await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    }
    await _storage.delete(key: _legacyTokenKey);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _legacyTokenKey),
    ]);
  }
}
