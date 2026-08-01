// -----------------------------------------------------------------------------
// 文件：secure_token_store.dart
// 作用：隔离登录 Token 的安全读写与清理实现
// 编写时间：2026-07-10
// 维护说明：Token 禁止写入 SharedPreferences、日志或页面状态
// -----------------------------------------------------------------------------

import 'dart:convert';

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
  String get _tokenBundleKey => 'merp.$_environment.auth.tokens.v2';

  @override
  Future<AuthTokens?> readTokens() async {
    final encodedBundle = await _storage.read(key: _tokenBundleKey);
    if (encodedBundle != null && encodedBundle.isNotEmpty) {
      try {
        final decoded = jsonDecode(encodedBundle);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Token bundle 不是 JSON Object');
        }
        final tokens = AuthTokens.fromJson(decoded);
        _logRead(tokens);
        return tokens;
      } catch (error, stackTrace) {
        _logger?.warning(
          'auth.storage',
          '安全存储中的 Token bundle 已损坏，将尝试兼容旧格式',
          error: error,
          stackTrace: stackTrace,
          fields: {'appEnvironment': _environment},
        );
        try {
          await _storage.delete(key: _tokenBundleKey);
        } catch (deleteError, deleteStackTrace) {
          _logger?.warning(
            'auth.storage',
            '损坏的 Token bundle 暂时无法删除',
            error: deleteError,
            stackTrace: deleteStackTrace,
            fields: {'appEnvironment': _environment},
          );
        }
      }
    }

    var accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    // 兼容旧版本单 token 键；下次成功登录或刷新后会写入新结构。
    accessToken ??= await _storage.read(key: _legacyTokenKey);
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      _logRead(null);
      return null;
    }
    final tokens = AuthTokens(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken,
    );
    _logRead(tokens);

    // 旧版本分键数据读取成功后立即迁移。迁移失败不阻塞本次会话恢复，
    // 下次启动仍可继续读取旧键并重试迁移。
    try {
      await saveTokens(tokens);
    } catch (error, stackTrace) {
      _logger?.warning(
        'auth.storage',
        '旧版认证令牌迁移失败，本次继续使用兼容数据',
        error: error,
        stackTrace: stackTrace,
        fields: {'appEnvironment': _environment},
      );
    }
    return tokens;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    // 单次写入完整令牌对，避免进程在两个键之间被终止后留下新旧令牌混合状态。
    await _storage.write(
      key: _tokenBundleKey,
      value: jsonEncode({
        'access_token': tokens.accessToken,
        if (tokens.refreshToken?.isNotEmpty == true)
          'refresh_token': tokens.refreshToken,
      }),
    );
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _legacyTokenKey),
      ]);
    } catch (error, stackTrace) {
      // 新 bundle 已成功落盘，旧键清理失败不应把本次登录判定为失败。
      _logger?.warning(
        'auth.storage',
        '原子 Token 已保存，但旧版认证键清理失败',
        error: error,
        stackTrace: stackTrace,
        fields: {'appEnvironment': _environment},
      );
    }
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
      _storage.delete(key: _tokenBundleKey),
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

  void _logRead(AuthTokens? tokens) {
    _logger?.info(
      'auth.storage',
      '安全存储读取完成',
      fields: {
        'appEnvironment': _environment,
        'accessCredentialPresent': tokens?.accessToken.isNotEmpty == true,
        'refreshCredentialPresent': tokens?.refreshToken?.isNotEmpty == true,
      },
    );
  }
}
