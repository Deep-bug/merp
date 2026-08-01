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
import 'auth_repository.dart';

enum AuthStatus { booting, restoreFailed, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required PermissionRepository permissionRepository,
    required AppLogger logger,
  }) : _authRepository = authRepository,
       _permissionRepository = permissionRepository,
       _logger = logger;

  final AuthRepository _authRepository;
  final PermissionRepository _permissionRepository;
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
        status = AuthStatus.authenticated;
        _sessionGeneration += 1;
        _logger.info('auth', '登录会话刷新恢复成功，开始后台加载会话数据');
      }
    } catch (error, stackTrace) {
      session = null;
      status = AuthStatus.restoreFailed;
      lastError = error.toString();
      _logger.error('auth', '恢复登录会话失败', error: error, stackTrace: stackTrace);
    }
    notifyListeners();
    if (isAuthenticated) {
      unawaited(reloadSessionData());
    }
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
      _sessionGeneration += 1;
      session = null;
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
      status = AuthStatus.authenticated;
      _sessionGeneration += 1;
      _logger.info('auth', '用户登录成功', fields: {'account': account.trim()});
      notifyListeners();
      unawaited(reloadSessionData());
      return true;
    } catch (error, stackTrace) {
      lastError = error.toString();
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
    session = null;
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
    session = null;
    captchaChallenge = null;
    captchaError = null;
    status = AuthStatus.unauthenticated;
    lastError = '登录已过期，请重新登录';
    _logger.warning('auth', '刷新令牌失效，已退出当前会话');
    notifyListeners();
  }
}
