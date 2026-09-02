// -----------------------------------------------------------------------------
// 文件：auth_controller.dart
// 作用：维护登录状态、会话恢复、权限加载和退出流程
// 编写时间：2026-07-10
// 维护说明：路由只监听 AuthStatus，页面不得自行判断或保存 Token
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/home/data/permission_repository.dart';
import '../logging/app_logger.dart';
import '../network/api_exception.dart';
import '../platform/web_data_cleaner.dart';
import 'auth_repository.dart';

enum AuthStatus {
  booting,
  restoreFailed,
  unauthenticated,
  authenticatedPendingSecurity,
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required PermissionRepository permissionRepository,
    required AppLogger logger,
    WebDataCleaner? webDataCleaner,
  }) : _authRepository = authRepository,
       _permissionRepository = permissionRepository,
       _webDataCleaner = webDataCleaner,
       _logger = logger;

  final AuthRepository _authRepository;
  final PermissionRepository _permissionRepository;
  final WebDataCleaner? _webDataCleaner;
  final AppLogger _logger;

  AuthStatus status = AuthStatus.booting;
  AuthSession? session;
  String? lastError;
  CaptchaChallenge? captchaChallenge;
  bool isCaptchaLoading = false;
  String? captchaError;
  bool isProfileLoading = false;
  String? profileLoadError;
  int _sessionGeneration = 0;
  bool gestureEnrollmentRequired = false;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  Future<void> restoreSession() async {
    lastError = null;
    try {
      session = await _authRepository.restore();
      if (session == null) {
        status = AuthStatus.unauthenticated;
        _logger.info('auth', '本地无可恢复会话');
      } else {
        gestureEnrollmentRequired = false;
        status = AuthStatus.authenticated;
        _sessionGeneration += 1;
        _logger.info('auth', '登录会话刷新恢复成功，开始后台加载会话数据');
      }
    } catch (error, stackTrace) {
      session = null;
      gestureEnrollmentRequired = false;
      status = AuthStatus.restoreFailed;
      lastError = error.toString();
      _logger.error('auth', '恢复登录会话失败', error: error, stackTrace: stackTrace);
    }
    notifyListeners();
    if (isAuthenticated) {
      unawaited(reloadSessionData());
    }
  }

  /// 只允许由依赖装配层在 QAS Debug 的显式开发开关下调用。
  /// Mock 会话不持久化 Token，也不会访问用户资料或认证接口。
  Future<void> enterDevelopmentMockSession() async {
    _sessionGeneration += 1;
    gestureEnrollmentRequired = false;
    lastError = null;
    captchaChallenge = null;
    captchaError = null;
    session = const AuthSession(
      tokens: AuthTokens(accessToken: 'development-mock-token'),
      profile: UserProfile(
        id: 'development-mock-user',
        accountName: 'mock.user',
        displayName: '开发测试用户',
        department: 'MERP Development',
      ),
    );
    status = AuthStatus.authenticated;
    _logger.warning('auth', '开发 Mock 模式：已跳过真实登录与会话恢复');
    notifyListeners();
    await _permissionRepository.loadDevelopmentMockMenu();
  }

  Future<void> retryRestoreSession() async {
    status = AuthStatus.booting;
    lastError = null;
    notifyListeners();
    await restoreSession();
  }

  /// 放弃无法恢复的旧会话，让用户可以主动返回登录页切换账号。
  Future<void> discardStoredSession() async {
    status = AuthStatus.booting;
    lastError = null;
    notifyListeners();
    try {
      await Future.wait([
        _authRepository.clearLocalSession(),
        _permissionRepository.clear(),
      ]);
      await _clearWebDataAfterSignOut();
      _sessionGeneration += 1;
      session = null;
      gestureEnrollmentRequired = false;
      captchaChallenge = null;
      captchaError = null;
      status = AuthStatus.unauthenticated;
      _logger.info('auth', '用户已放弃旧会话，返回登录页');
    } catch (error, stackTrace) {
      status = AuthStatus.restoreFailed;
      lastError = error.toString();
      _logger.error('auth', '清理旧会话失败', error: error, stackTrace: stackTrace);
    }
    notifyListeners();
  }

  Future<void> refreshCaptcha() async {
    if (isCaptchaLoading) {
      return;
    }

    isCaptchaLoading = true;
    captchaError = null;
    captchaChallenge = null;
    notifyListeners();

    try {
      captchaChallenge = await _authRepository.fetchCaptcha();
    } catch (error, stackTrace) {
      captchaError = error.toString();
      _logger.warning('auth', '验证码加载失败', error: error, stackTrace: stackTrace);
    } finally {
      isCaptchaLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String account,
    required String password,
    required String captchaCode,
    String? environment,
  }) async {
    final challenge = captchaChallenge;
    if (challenge == null) {
      lastError = '请先获取验证码';
      notifyListeners();
      return false;
    }
    if (captchaCode.trim().isEmpty) {
      lastError = '请输入验证码';
      notifyListeners();
      return false;
    }

    lastError = null;
    gestureEnrollmentRequired = false;
    notifyListeners();

    try {
      session = await _authRepository.login(
        account: account,
        password: password,
        captchaId: challenge.captchaId,
        captchaCode: captchaCode,
        environment: environment,
      );
      captchaChallenge = null;
      captchaError = null;
      status = AuthStatus.authenticatedPendingSecurity;
      _sessionGeneration += 1;
      _logger.info('auth', '用户登录成功', fields: {'account': account.trim()});
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      session = null;
      gestureEnrollmentRequired = false;
      // 登录页只展示后端可读错误，不暴露 traceId/incidentId 等诊断编号。
      // 完整异常仍进入诊断日志，开发和运维排查能力不受影响。
      lastError = error is ApiException ? error.message : error.toString();
      status = AuthStatus.unauthenticated;
      _logger.warning(
        'auth',
        '用户登录失败',
        error: error,
        stackTrace: stackTrace,
        fields: {'account': account.trim()},
      );
      notifyListeners();
      unawaited(refreshCaptcha());
      return false;
    }
  }

  /// 账号密码登录完成后，由登录页在本地手势安全域准备完成时放行路由。
  void completeInteractiveLogin({required bool requiresGestureEnrollment}) {
    if (status != AuthStatus.authenticatedPendingSecurity || session == null) {
      return;
    }
    gestureEnrollmentRequired = requiresGestureEnrollment;
    status = AuthStatus.authenticated;
    notifyListeners();
    unawaited(reloadSessionData());
  }

  void completeGestureEnrollment() {
    if (!gestureEnrollmentRequired) {
      return;
    }
    gestureEnrollmentRequired = false;
    notifyListeners();
  }

  /// 登录恢复后异步刷新用户资料和权限菜单；两者均只保存在当前进程内存中。
  Future<void> reloadSessionData() async {
    final currentSession = session;
    if (status != AuthStatus.authenticated || currentSession == null) {
      return;
    }
    await Future.wait([
      _loadProfileForCurrentSession(),
      _permissionRepository.loadForSession(currentSession),
    ]);
  }

  Future<void> _loadProfileForCurrentSession() async {
    final currentSession = session;
    if (currentSession == null) {
      return;
    }
    final generation = _sessionGeneration;
    isProfileLoading = true;
    profileLoadError = null;
    notifyListeners();
    try {
      final profile = await _authRepository.loadCurrentUserProfile(
        fallback: currentSession.profile,
      );
      if (generation != _sessionGeneration || session == null) {
        return;
      }
      session = session!.copyWith(profile: profile);
      _logger.info('auth', '用户资料后台加载完成');
    } catch (error, stackTrace) {
      if (generation != _sessionGeneration || session == null) {
        return;
      }
      profileLoadError = error.toString();
      _logger.warning(
        'auth',
        '用户资料后台加载失败，保留当前会话资料',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (generation == _sessionGeneration) {
        isProfileLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    _sessionGeneration += 1;
    await _authRepository.logout();
    await _permissionRepository.clear();
    await _clearWebDataAfterSignOut();
    session = null;
    gestureEnrollmentRequired = false;
    captchaChallenge = null;
    captchaError = null;
    status = AuthStatus.unauthenticated;
    _logger.info('auth', '用户已退出登录');
    notifyListeners();
  }

  /// ApiClient 在 refresh_token 失效后调用，确保内存会话与路由立即同步。
  Future<void> handleSessionExpired() async {
    _sessionGeneration += 1;
    await _permissionRepository.clear();
    await _clearWebDataAfterSignOut();
    session = null;
    gestureEnrollmentRequired = false;
    captchaChallenge = null;
    captchaError = null;
    status = AuthStatus.unauthenticated;
    lastError = '登录已过期，请重新登录';
    _logger.warning('auth', '刷新令牌失效，已退出当前会话');
    notifyListeners();
  }

  /// App 会话退出时同步移除 WebView 的 Cookie、缓存与 H5 本地数据，避免
  /// 下一位用户误用上一位用户的网页会话。原生清理失败不能阻断 App Token
  /// 和权限的退出流程，因此仅记录告警，用户仍可正常回到登录页。
  Future<void> _clearWebDataAfterSignOut() async {
    final cleaner = _webDataCleaner;
    if (cleaner == null) {
      return;
    }
    try {
      await cleaner.clearAllWebData();
    } catch (error, stackTrace) {
      _logger.warning(
        'auth',
        '登录会话已退出，但 WebView 数据清理失败',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
