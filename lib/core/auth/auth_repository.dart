// -----------------------------------------------------------------------------
// 文件：auth_repository.dart
// 作用：封装登录接口、Token 持久化和本地会话恢复
// 编写时间：2026-07-10
// 维护说明：认证协议变化在仓库层处理，不向页面泄露网络实现
// -----------------------------------------------------------------------------

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'secure_token_store.dart';

class AuthSession {
  const AuthSession({required this.token, required this.userName});

  final String token;
  final String userName;
}

/// 登录仓库。
///
/// 只负责登录接口、token 持久化和本地登录态恢复。
/// 页面层不要直接保存 token，避免后续替换安全存储或刷新 token 时到处改代码。
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStore tokenStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;

  Future<AuthSession?> restore() async {
    // App 启动时先尝试恢复本地 token；是否仍然有效由后续接口请求确认。
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return AuthSession(token: token, userName: '当前用户');
  }

  Future<AuthSession> login({
    required String account,
    required String password,
  }) async {
    if (account.trim().isEmpty || password.isEmpty) {
      throw const AuthException('请输入账号和密码');
    }

    try {
      // 登录接口也走统一 ApiClient，因此错误码、traceId、网络异常都会统一转换。
      final data = await _apiClient.post<Map<String, dynamic>>(
        _apiClient.config.loginPath,
        data: {'account': account.trim(), 'password': password},
      );
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AuthException('登录响应缺少 token');
      }
      await _tokenStore.saveToken(token);
      return AuthSession(
        token: token,
        userName: data['userName'] as String? ?? account.trim(),
      );
    } on AuthException {
      rethrow;
    } on ApiException catch (error) {
      if (!_apiClient.config.usesDemoBackend) {
        throw AuthException(error.userMessage);
      }
      return _loginWithDemoToken(account.trim());
    } catch (error) {
      if (!_apiClient.config.usesDemoBackend) {
        throw AuthException(error.toString());
      }
      return _loginWithDemoToken(account.trim());
    }
  }

  Future<AuthSession> _loginWithDemoToken(String account) async {
    const demoToken = 'demo-token-for-flutter-shell';
    await _tokenStore.saveToken(demoToken);
    return AuthSession(token: demoToken, userName: account);
  }

  Future<void> logout() => _tokenStore.clear();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
