// -----------------------------------------------------------------------------
// 文件：secure_token_store.dart
// 作用：隔离登录 Token 的安全读写与清理实现
// 编写时间：2026-07-10
// 维护说明：Token 禁止写入 SharedPreferences、日志或页面状态
// -----------------------------------------------------------------------------

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';
import 'auth_models.dart';

/// Token 存储抽象，便于测试替换为内存实现，也避免网络层依赖具体插件。
abstract interface class TokenStore {
  Future<AuthTokens?> readTokens();

  Future<void> saveTokens(AuthTokens tokens);

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    AppLogger? logger,
    String environment = 'qas',
  }) : _environment = environment.trim().toLowerCase(),
       _storage =
           storage ??
           FlutterSecureStorage(
             // 冷启动恢复会话需要在设备首次解锁后读取 refresh token。
             // this_device 让令牌不会随 Keychain 备份迁移到另一台设备。
             iOptions: const IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
             // Android 7 已满足插件 API 23 要求。默认实现使用 RSA-OAEP
             // 包装密钥，并使用 AES-GCM 加密 Token，不会明文落盘。
             aOptions: AndroidOptions(
               storageNamespace:
                   'merp_${environment.trim().toLowerCase()}_auth',
             ),
           ),
       _logger = logger;

  final String _environment;
  final FlutterSecureStorage _storage;
  final AppLogger? _logger;

  String get _accessTokenKey => 'merp.$_environment.auth.access_token';
  String get _refreshTokenKey => 'merp.$_environment.auth.refresh_token';
  String get _legacyTokenKey => 'merp.$_environment.auth.token';

  @override
  Future<AuthTokens?> readTokens() async {
    var accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    // 兼容旧版本单 token 键；下次成功登录或刷新后会写入新结构。
    accessToken ??= await _storage.read(key: _legacyTokenKey);
    _logger?.info(
      'auth.storage',
      '安全存储读取完成',
      fields: {
        'appEnvironment': _environment,
        'accessCredentialPresent': accessToken?.isNotEmpty == true,
        'refreshCredentialPresent': refreshToken?.isNotEmpty == true,
      },
    );
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
    _logger?.info(
      'auth.storage',
      '认证令牌已写入安全存储',
      fields: {
        'appEnvironment': _environment,
        'refreshCredentialPresent': tokens.refreshToken?.isNotEmpty == true,
      },
    );
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _legacyTokenKey),
    ]);
    _logger?.info(
      'auth.storage',
      '安全存储中的认证令牌已清除',
      fields: {'appEnvironment': _environment},
    );
  }
}
