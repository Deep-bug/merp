// -----------------------------------------------------------------------------
// 文件：auth_repository.dart
// 作用：封装登录、用户资料、会话恢复、刷新 Token 和登出接口
// 编写时间：2026-07-15
// 维护说明：认证协议变化在仓库层处理，不向页面泄露网络与 JSON 实现
// -----------------------------------------------------------------------------

import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'auth_models.dart';
import 'secure_token_store.dart';

export 'auth_models.dart';

/// 认证仓库严格按照后端认证接口组装请求，并把接口 DTO 转成应用会话。
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStore tokenStore,
    required AppLogger logger,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _logger = logger;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final AppLogger _logger;

  /// 启动恢复不直接信任旧 access_token，而是只用 refresh_token 换新令牌。
  ///
  /// 恢复阶段不拉用户资料和权限菜单，避免启动路径被非认证接口阻塞。只要
  /// refresh_token 未失效且刷新成功，就允许进入首页。
  Future<AuthSession?> restore() async {
    final storedTokens = await _tokenStore.readTokens();
    if (storedTokens?.refreshToken == null ||
        storedTokens!.refreshToken!.isEmpty) {
      await _tokenStore.clear();
      return null;
    }

    final refreshedTokens = await _apiClient.refreshTokensForRestore();
    if (refreshedTokens == null) {
      return null;
    }
    const profile = UserProfile(
      id: '',
      accountName: '',
      displayName: '当前用户',
      department: '',
    );
    return AuthSession(tokens: refreshedTokens, profile: profile);
  }

  Future<CaptchaChallenge> fetchCaptcha() async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        _apiClient.config.captchaPath,
        skipAuth: true,
      );
      return CaptchaChallenge.fromJson(data);
    } on ApiException catch (error) {
      throw AuthException(error.userMessage);
    } on FormatException catch (error) {
      throw AuthException(error.message);
    } catch (error) {
      throw AuthException(error.toString());
    }
  }

  Future<AuthSession> login({
    required String account,
    required String password,
    required String captchaId,
    required String captchaCode,
    String? environment,
  }) async {
    final username = account.trim();
    final normalizedCaptchaId = captchaId.trim();
    final normalizedCaptchaCode = captchaCode.trim();
    final loginEnvironment = environment?.trim().isNotEmpty == true
        ? environment!.trim()
        : _apiClient.config.normalizedAuthEnvironment;
    if (username.isEmpty || password.isEmpty) {
      throw const AuthException('请输入账号和密码');
    }
    if (normalizedCaptchaId.isEmpty) {
      throw const AuthException('验证码已失效，请刷新验证码');
    }
    if (normalizedCaptchaCode.isEmpty) {
      throw const AuthException('请输入验证码');
    }

    try {
      _logger.debug(
        'auth',
        'Login 请求参数',
        fields: {
          'username': username,
          'credentialPresent': password.isNotEmpty,
          'credentialLength': password.length,
          'captchaId': normalizedCaptchaId,
          'captchaInputPresent': normalizedCaptchaCode.isNotEmpty,
          'captchaInputLength': normalizedCaptchaCode.length,
          'appId': 'merp',
          'source': 1,
          'environment': loginEnvironment,
        },
      );
      final data = await _apiClient.post<Map<String, dynamic>>(
        _apiClient.config.loginPath,
        data: {
          'username': username,
          'password': password,
          'captchaId': normalizedCaptchaId,
          'captchaCode': normalizedCaptchaCode,
          'appId': 'merp',
          'source': 1,
          'environment': loginEnvironment,
        },
        skipAuth: true,
      );
      final tokens = AuthTokens.fromJson(data);
      final loginProfile = UserProfile.fromLoginResponse(
        data,
        fallbackAccountName: username,
      );

      // 用户信息接口依赖刚取得的 Bearer Token，因此必须先安全保存令牌。
      await _tokenStore.saveTokens(tokens);
      final profile = await _loadUserProfileForLogin(fallback: loginProfile);
      return AuthSession(tokens: tokens, profile: profile);
    } on AuthException {
      rethrow;
    } on ApiException catch (error) {
      throw AuthException(error.userMessage);
    } on FormatException catch (error) {
      throw AuthException(error.message);
    } catch (error) {
      throw AuthException(error.toString());
    }
  }

  /// 用户信息失败不阻塞登录，使用登录响应里的账号与显示名作为降级资料。
  Future<UserProfile> loadCurrentUserProfile({
    required UserProfile fallback,
  }) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      _apiClient.config.userInfoPath,
    );
    return UserProfile.fromJson(
      data,
      fallbackAccountName: fallback.accountName,
      fallbackDisplayName: fallback.displayName,
    );
  }

  Future<UserProfile> _loadUserProfileForLogin({
    required UserProfile fallback,
  }) async {
    try {
      return await loadCurrentUserProfile(fallback: fallback);
    } catch (error, stackTrace) {
      _logger.warning(
        'auth',
        '用户资料接口失败，已使用登录资料降级',
        error: error,
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }

  /// 无论服务端登出成功与否，本地令牌都必须清空。
  Future<void> logout() async {
    final refreshToken = (await _tokenStore.readTokens())?.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post<Object?>(
          _apiClient.config.logoutPath,
          data: {'refreshToken': refreshToken},
          skipAuth: true,
        );
      }
    } catch (error, stackTrace) {
      _logger.warning(
        'auth',
        '服务端登出接口失败，本地会话仍将清理',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await _tokenStore.clear();
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
